using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ResumeAPI.Data;
using ResumeAPI.DTOs;
using ResumeAPI.Models;

namespace ResumeAPI.Controllers;

[ApiController]
[Route("api/skills")]
public class SkillsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await db.Skills.OrderBy(s => s.Order).ToListAsync());

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] SkillDto dto)
    {
        var s = new Skill { Name = dto.Name, IconPath = dto.IconPath,
            Order = await db.Skills.CountAsync() };
        db.Skills.Add(s);
        await db.SaveChangesAsync();
        return Ok(s);
    }

    [HttpPut("{id}")]
    [Authorize]
    public async Task<IActionResult> Update(int id, [FromBody] SkillDto dto)
    {
        var s = await db.Skills.FindAsync(id);
        if (s == null) return NotFound();
        s.Name = dto.Name;
        if (dto.IconPath != null) s.IconPath = dto.IconPath;
        await db.SaveChangesAsync();
        return Ok(s);
    }

    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> Delete(int id)
    {
        var s = await db.Skills.FindAsync(id);
        if (s == null) return NotFound();
        db.Skills.Remove(s);
        await db.SaveChangesAsync();
        return NoContent();
    }
}
