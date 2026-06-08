using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using ResumeAPI.Data;
using ResumeAPI.DTOs;
using ResumeAPI.Models;

namespace ResumeAPI.Controllers;

[ApiController]
[Route("api/experience")]
public class ExperienceController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var list = await db.Experiences.OrderBy(e => e.Order).ToListAsync();
        return Ok(list.Select(e => new {
            e.Id, e.Company, e.Role, e.Period, e.Order,
            Bullets = JsonSerializer.Deserialize<List<string>>(e.BulletsJson) ?? []
        }));
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] ExperienceDto dto)
    {
        var e = new Experience {
            Company = dto.Company, Role = dto.Role, Period = dto.Period,
            BulletsJson = JsonSerializer.Serialize(dto.Bullets),
            Order = await db.Experiences.CountAsync()
        };
        db.Experiences.Add(e);
        await db.SaveChangesAsync();
        return Ok(e);
    }

    [HttpPut("{id}")]
    [Authorize]
    public async Task<IActionResult> Update(int id, [FromBody] ExperienceDto dto)
    {
        var e = await db.Experiences.FindAsync(id);
        if (e == null) return NotFound();
        e.Company = dto.Company; e.Role = dto.Role; e.Period = dto.Period;
        e.BulletsJson = JsonSerializer.Serialize(dto.Bullets);
        await db.SaveChangesAsync();
        return Ok(e);
    }

    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> Delete(int id)
    {
        var e = await db.Experiences.FindAsync(id);
        if (e == null) return NotFound();
        db.Experiences.Remove(e);
        await db.SaveChangesAsync();
        return NoContent();
    }
}
