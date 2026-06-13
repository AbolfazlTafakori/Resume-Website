using System.IO.Compression;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using ResumeAPI.Data;

namespace ResumeAPI.Controllers;

[ApiController]
[Route("api")]
public class BackupController(AppDbContext db, IWebHostEnvironment env) : ControllerBase
{
    // The backup is intentionally portable: it carries ONLY the SQLite database
    // (all content + the admin username/password hash) and the uploaded images.
    // It does NOT contain domains, JWT key, or any server config — those live in
    // nginx / systemd — so a backup restores cleanly onto a different domain or
    // a brand-new server.
    private static readonly string[] _tables =
        ["Profiles", "Skills", "Projects", "Educations", "Experiences", "Socials", "AdminUsers", "SiteTexts"];

    private string DbPath      => db.Database.GetDbConnection().DataSource;
    private string UploadsPath => Path.Combine(env.ContentRootPath, "uploads");

    [HttpGet("backup")]
    [Authorize]
    public async Task<IActionResult> Backup()
    {
        // Consistent online snapshot of the live DB (safe while the app runs).
        var snapshot = Path.Combine(Path.GetTempPath(), $"resume-snap-{Guid.NewGuid():N}.db");
        try
        {
            // Pooling=False so the connections fully release the snapshot file
            // handle on dispose — otherwise the pool keeps it open and zipping
            // the file fails with "being used by another process".
            await using (var src = new SqliteConnection($"Data Source={DbPath};Pooling=False"))
            await using (var dst = new SqliteConnection($"Data Source={snapshot};Pooling=False"))
            {
                await src.OpenAsync();
                await dst.OpenAsync();
                src.BackupDatabase(dst);
            }

            using var ms = new MemoryStream();
            using (var zip = new ZipArchive(ms, ZipArchiveMode.Create, leaveOpen: true))
            {
                zip.CreateEntryFromFile(snapshot, "resume.db");
                if (Directory.Exists(UploadsPath))
                    foreach (var f in Directory.GetFiles(UploadsPath))
                        zip.CreateEntryFromFile(f, $"uploads/{Path.GetFileName(f)}");
            }
            ms.Position = 0;
            var name = $"resume-backup-{DateTime.UtcNow:yyyyMMdd-HHmmss}.zip";
            return File(ms.ToArray(), "application/zip", name);
        }
        finally
        {
            try { if (System.IO.File.Exists(snapshot)) System.IO.File.Delete(snapshot); } catch { }
        }
    }

    [HttpPost("restore")]
    [Authorize]
    [RequestSizeLimit(200 * 1024 * 1024)] // 200 MB
    public async Task<IActionResult> Restore(IFormFile file)
    {
        if (file is null || file.Length == 0) return BadRequest("No file uploaded");

        // Buffer the upload into memory so the zip reader has a well-behaved,
        // seekable stream (the raw request stream throws on the backward seeks
        // ZipArchive does when the payload isn't actually a zip).
        using var buffer = new MemoryStream();
        await file.CopyToAsync(buffer);
        buffer.Position = 0;

        ZipArchive archive;
        try
        {
            archive = new ZipArchive(buffer, ZipArchiveMode.Read, leaveOpen: true);
        }
        catch (Exception ex) when (ex is InvalidDataException or ArgumentException or IOException)
        {
            return BadRequest("Invalid backup file (not a valid .zip)");
        }

        var snapshot = Path.Combine(Path.GetTempPath(), $"resume-restore-{Guid.NewGuid():N}.db");
        try
        {
            using (archive)
            {
                var dbEntry = archive.GetEntry("resume.db");
                if (dbEntry is null) return BadRequest("Invalid backup file (resume.db not found)");

                await using (var es = dbEntry.Open())
                await using (var fs = System.IO.File.Create(snapshot))
                    await es.CopyToAsync(fs);

                // Replace the live data table-by-table from the snapshot, atomically.
                try
                {
                    await RestoreDatabaseAsync(snapshot);
                }
                catch (SqliteException ex)
                {
                    return BadRequest($"Backup is not compatible with this version ({ex.Message})");
                }

                // Restore uploaded images (overwrite by name; ignore anything else).
                Directory.CreateDirectory(UploadsPath);
                foreach (var entry in archive.Entries)
                {
                    if (!entry.FullName.StartsWith("uploads/", StringComparison.Ordinal)) continue;
                    var safe = Path.GetFileName(entry.FullName);
                    if (string.IsNullOrEmpty(safe) || safe.Contains("..")) continue;
                    var dest = Path.Combine(UploadsPath, safe);
                    await using var es = entry.Open();
                    await using var fs = System.IO.File.Create(dest);
                    await es.CopyToAsync(fs);
                }
            }

            return Ok(new { restored = true });
        }
        catch (InvalidDataException)
        {
            return BadRequest("Invalid backup file (corrupt archive)");
        }
        finally
        {
            try { if (System.IO.File.Exists(snapshot)) System.IO.File.Delete(snapshot); } catch { }
        }
    }

    // Copy every row from the snapshot into the live DB using ATTACH, in one
    // transaction. Preserves Ids and the admin credentials. No app restart needed.
    private async Task RestoreDatabaseAsync(string snapshotPath)
    {
        await using var conn = new SqliteConnection($"Data Source={DbPath};Pooling=False");
        await conn.OpenAsync();

        await using (var pragma = conn.CreateCommand())
        {
            pragma.CommandText = "PRAGMA busy_timeout=8000;";
            await pragma.ExecuteNonQueryAsync();
        }

        await using (var attach = conn.CreateCommand())
        {
            attach.CommandText = "ATTACH DATABASE $p AS bak;";
            attach.Parameters.AddWithValue("$p", snapshotPath);
            await attach.ExecuteNonQueryAsync();
        }

        try
        {
            await using var tx = (SqliteTransaction)await conn.BeginTransactionAsync();
            await using (var off = conn.CreateCommand())
            {
                off.Transaction = tx;
                off.CommandText = "PRAGMA foreign_keys=OFF;";
                await off.ExecuteNonQueryAsync();
            }
            foreach (var t in _tables)
            {
                await using var cmd = conn.CreateCommand();
                cmd.Transaction = tx;
                cmd.CommandText = $"DELETE FROM main.\"{t}\"; INSERT INTO main.\"{t}\" SELECT * FROM bak.\"{t}\";";
                await cmd.ExecuteNonQueryAsync();
            }
            await tx.CommitAsync();
        }
        finally
        {
            await using var detach = conn.CreateCommand();
            detach.CommandText = "DETACH DATABASE bak;";
            await detach.ExecuteNonQueryAsync();
        }
    }
}
