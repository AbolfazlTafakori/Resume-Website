using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ResumeAPI.Data;
using ResumeAPI.DTOs;
using ResumeAPI.Models;

namespace ResumeAPI.Controllers;

[ApiController]
[Route("api/profile")]
public class ProfileController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var p = await db.Profiles.FirstOrDefaultAsync();
        return Ok(p ?? new Profile());
    }

    [HttpPut]
    [Authorize]
    public async Task<IActionResult> Update([FromBody] ProfileDto dto)
    {
        var p = await db.Profiles.FirstOrDefaultAsync() ?? new Profile();
        bool isNew = p.Id == 0;

        p.HeroTitle      = dto.HeroTitle;
        p.HeroSubtitle   = dto.HeroSubtitle;
        p.Name           = dto.Name;
        p.Title          = dto.Title;
        p.Location       = dto.Location;
        p.Bio            = dto.Bio;
        if (dto.HomeAvatar                != null) p.HomeAvatar                = dto.HomeAvatar;
        if (dto.AboutAvatar               != null) p.AboutAvatar               = dto.AboutAvatar;
        if (dto.ContactAvatar             != null) p.ContactAvatar             = dto.ContactAvatar;
        if (dto.HomeAvatarBorderColor     != null) p.HomeAvatarBorderColor     = dto.HomeAvatarBorderColor;
        if (dto.AboutAvatarBorderColor    != null) p.AboutAvatarBorderColor    = dto.AboutAvatarBorderColor;
        if (dto.ContactAvatarBorderColor  != null) p.ContactAvatarBorderColor  = dto.ContactAvatarBorderColor;

        if (isNew) db.Profiles.Add(p);
        await db.SaveChangesAsync();
        return Ok(p);
    }
}
