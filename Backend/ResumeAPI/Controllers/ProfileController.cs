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

        // Only overwrite fields that were actually supplied, so a partial
        // update (e.g. saving just an avatar) doesn't wipe the text fields.
        if (dto.HeroTitle                 != null) p.HeroTitle                 = dto.HeroTitle;
        if (dto.HeroSubtitle              != null) p.HeroSubtitle              = dto.HeroSubtitle;
        if (dto.Name                      != null) p.Name                      = dto.Name;
        if (dto.Title                     != null) p.Title                     = dto.Title;
        if (dto.Location                  != null) p.Location                  = dto.Location;
        if (dto.Bio                       != null) p.Bio                       = dto.Bio;
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
