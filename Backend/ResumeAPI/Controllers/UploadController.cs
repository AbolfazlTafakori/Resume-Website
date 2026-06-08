using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace ResumeAPI.Controllers;

[ApiController]
[Route("api")]
public class UploadController(IWebHostEnvironment env) : ControllerBase
{
    private readonly string _uploadPath = Path.Combine(env.ContentRootPath, "uploads");

    [HttpPost("upload")]
    [Authorize]
    public async Task<IActionResult> Upload(IFormFile file)
    {
        if (file.Length == 0) return BadRequest("Empty file");

        Directory.CreateDirectory(_uploadPath);
        var ext      = Path.GetExtension(file.FileName).ToLowerInvariant();
        var filename = $"{Guid.NewGuid()}{ext}";
        var path     = Path.Combine(_uploadPath, filename);

        using var stream = System.IO.File.Create(path);
        await file.CopyToAsync(stream);

        return Ok(new { filename });
    }

    [HttpGet("uploads/{filename}")]
    public IActionResult GetFile(string filename)
    {
        var path = Path.Combine(_uploadPath, filename);
        if (!System.IO.File.Exists(path)) return NotFound();
        var mime = filename.EndsWith(".png") ? "image/png"
                 : filename.EndsWith(".jpg") || filename.EndsWith(".jpeg") ? "image/jpeg"
                 : "application/octet-stream";
        return PhysicalFile(path, mime);
    }
}
