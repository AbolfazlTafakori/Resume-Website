using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ResumeAPI.Data;
using ResumeAPI.DTOs;
using ResumeAPI.Models;

namespace ResumeAPI.Controllers;

[ApiController]
[Route("api/projects")]
public class ProjectsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await db.Projects.OrderByDescending(p => p.Order).ToListAsync());

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] ProjectDto dto)
    {
        var p = new Project { Name = dto.Name, Overview = dto.Overview,
            ImagePath = dto.ImagePath, ViewUrl = dto.ViewUrl, GithubUrl = dto.GithubUrl,
            Order = await db.Projects.CountAsync() };
        db.Projects.Add(p);
        await db.SaveChangesAsync();
        return Ok(p);
    }

    [HttpPut("{id}")]
    [Authorize]
    public async Task<IActionResult> Update(int id, [FromBody] ProjectDto dto)
    {
        var p = await db.Projects.FindAsync(id);
        if (p == null) return NotFound();
        p.Name = dto.Name;
        if (dto.Overview  != null) p.Overview  = dto.Overview;
        p.ViewUrl   = dto.ViewUrl;
        p.GithubUrl = dto.GithubUrl;
        if (dto.ImagePath != null) p.ImagePath = dto.ImagePath;
        await db.SaveChangesAsync();
        return Ok(p);
    }

    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> Delete(int id)
    {
        var p = await db.Projects.FindAsync(id);
        if (p == null) return NotFound();
        db.Projects.Remove(p);
        await db.SaveChangesAsync();
        return NoContent();
    }
}
