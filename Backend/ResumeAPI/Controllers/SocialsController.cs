using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ResumeAPI.Data;
using ResumeAPI.DTOs;
using ResumeAPI.Models;

namespace ResumeAPI.Controllers;

[ApiController]
[Route("api/socials")]
public class SocialsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var list = await db.Socials.OrderBy(s => s.Order).ToListAsync();
        return Ok(list);
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] SocialItemDto dto)
    {
        int nextOrder = db.Socials.Any() ? db.Socials.Max(s => s.Order) + 1 : 0;
        var s = new Social { Name = dto.Name, IconPath = dto.IconPath, Url = dto.Url, Order = nextOrder };
        db.Socials.Add(s);
        await db.SaveChangesAsync();
        return Ok(s);
    }

    [HttpPut("{id}")]
    [Authorize]
    public async Task<IActionResult> Update(int id, [FromBody] SocialItemDto dto)
    {
        var s = await db.Socials.FindAsync(id);
        if (s == null) return NotFound();
        s.Name = dto.Name; s.IconPath = dto.IconPath; s.Url = dto.Url;
        await db.SaveChangesAsync();
        return Ok(s);
    }

    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> Delete(int id)
    {
        var s = await db.Socials.FindAsync(id);
        if (s == null) return NotFound();
        db.Socials.Remove(s);
        await db.SaveChangesAsync();
        return Ok();
    }
}
