using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ResumeAPI.Controllers;

[ApiController]
[Route("api")]
public class UploadController(IWebHostEnvironment env) : ControllerBase
{
    private readonly string _uploadPath = Path.Combine(env.ContentRootPath, "uploads");

    private static readonly HashSet<string> _allowedExt  = [".jpg", ".jpeg", ".png", ".gif", ".webp"];
    private static readonly HashSet<string> _allowedMime = ["image/jpeg", "image/png", "image/gif", "image/webp"];
    private const long MaxFileSize = 10 * 1024 * 1024; // 10 MB

    [HttpPost("upload")]
    [Authorize]
    public async Task<IActionResult> Upload(IFormFile file)
    {
        if (file.Length == 0) return BadRequest("Empty file");
        if (file.Length > MaxFileSize) return BadRequest("File too large (max 10 MB)");

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!_allowedExt.Contains(ext)) return BadRequest("Only image files are allowed");
        if (!_allowedMime.Contains(file.ContentType.ToLowerInvariant())) return BadRequest("Invalid content type");

        Directory.CreateDirectory(_uploadPath);
        var filename = $"{Guid.NewGuid()}{ext}";
        var path     = Path.Combine(_uploadPath, filename);

        using var stream = System.IO.File.Create(path);
        await file.CopyToAsync(stream);

        return Ok(new { filename });
    }

    [HttpGet("uploads/{filename}")]
    public IActionResult GetFile(string filename)
    {
        // Prevent path traversal — only allow simple filenames with no directory separators
        if (filename.Contains('/') || filename.Contains('\\') || filename.Contains(".."))
            return BadRequest();

        var safeName = Path.GetFileName(filename);
        var path     = Path.Combine(_uploadPath, safeName);

        // Verify the resolved path is still inside the upload directory
        var fullPath   = Path.GetFullPath(path);
        var uploadRoot = Path.GetFullPath(_uploadPath);
        if (!fullPath.StartsWith(uploadRoot + Path.DirectorySeparatorChar))
            return BadRequest();

        if (!System.IO.File.Exists(fullPath)) return NotFound();

        var ext  = Path.GetExtension(safeName).ToLowerInvariant();
        var mime = ext switch {
            ".png"  => "image/png",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".gif"  => "image/gif",
            ".webp" => "image/webp",
            _       => "application/octet-stream"
        };
        return PhysicalFile(fullPath, mime);
    }
}
