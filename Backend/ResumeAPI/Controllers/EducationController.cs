using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ResumeAPI.Data;
using ResumeAPI.DTOs;
using ResumeAPI.Models;

namespace ResumeAPI.Controllers;

[ApiController]
[Route("api/education")]
public class EducationController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll() =>
        Ok(await db.Educations.OrderBy(e => e.Order).ToListAsync());

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] EducationDto dto)
    {
        var e = new Education { Period = dto.Period, Description = dto.Description,
            Order = await db.Educations.CountAsync() };
        db.Educations.Add(e);
        await db.SaveChangesAsync();
        return Ok(e);
    }

    [HttpPut("{id}")]
    [Authorize]
    public async Task<IActionResult> Update(int id, [FromBody] EducationDto dto)
    {
        var e = await db.Educations.FindAsync(id);
        if (e == null) return NotFound();
        e.Period = dto.Period; e.Description = dto.Description;
        await db.SaveChangesAsync();
        return Ok(e);
    }

    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> Delete(int id)
    {
        var e = await db.Educations.FindAsync(id);
        if (e == null) return NotFound();
        db.Educations.Remove(e);
        await db.SaveChangesAsync();
        return NoContent();
    }
}
