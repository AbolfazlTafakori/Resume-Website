using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ResumeAPI.Data;
using ResumeAPI.DTOs;
using ResumeAPI.Models;

namespace ResumeAPI.Controllers;

[ApiController]
[Route("api/sitetexts")]
public class SiteTextsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var t = await db.SiteTexts.FirstOrDefaultAsync();
        return Ok(t ?? new SiteTexts());
    }

    [HttpPut]
    [Authorize]
    public async Task<IActionResult> Update([FromBody] SiteTextsDto dto)
    {
        var t = await db.SiteTexts.FirstOrDefaultAsync() ?? new SiteTexts();
        bool isNew = t.Id == 0;

        t.NavLogo      = dto.NavLogo;
        t.NavHome      = dto.NavHome;
        t.NavAbout     = dto.NavAbout;
        t.NavPortfolio = dto.NavPortfolio;
        t.NavContact   = dto.NavContact;

        t.HomeSkillsTitle = dto.HomeSkillsTitle;

        t.AboutPageTitle        = dto.AboutPageTitle;
        t.AboutEducationHeader  = dto.AboutEducationHeader;
        t.AboutExperienceHeader = dto.AboutExperienceHeader;

        t.PortfolioPageTitle = dto.PortfolioPageTitle;
        t.ContactPageTitle   = dto.ContactPageTitle;

        if (isNew) db.SiteTexts.Add(t);
        await db.SaveChangesAsync();
        return Ok(t);
    }
}
