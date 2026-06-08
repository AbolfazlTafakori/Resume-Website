namespace ResumeAPI.Models;

public class Profile
{
    public int Id { get; set; }
    public string HeroTitle    { get; set; } = "Backend web developer !";
    public string HeroSubtitle { get; set; } = "Hi, I'm Mrnobudi, passionate Back end Web Developer From IRAN";
    public string Name         { get; set; } = "Mrnobudi";
    public string Title        { get; set; } = "Back-end Developer";
    public string Location     { get; set; } = "USA, Dallas";
    public string Bio          { get; set; } = "";
    public string? HomeAvatar    { get; set; }
    public string? AboutAvatar   { get; set; }
    public string? ContactAvatar { get; set; }
    public string  AvatarBorderColor { get; set; } = "#5b8dee";
}

public class Skill
{
    public int    Id       { get; set; }
    public string Name     { get; set; } = "";
    public string? IconPath { get; set; }
    public int    Order    { get; set; }
}

public class Project
{
    public int    Id        { get; set; }
    public string Name      { get; set; } = "";
    public string? ImagePath { get; set; }
    public string? ViewUrl   { get; set; }
    public string? GithubUrl { get; set; }
    public int    Order     { get; set; }
}

public class Education
{
    public int    Id          { get; set; }
    public string Period      { get; set; } = "";
    public string Description { get; set; } = "";
    public int    Order       { get; set; }
}

public class Experience
{
    public int    Id      { get; set; }
    public string Company { get; set; } = "";
    public string Role    { get; set; } = "";
    public string Period  { get; set; } = "";
    public string BulletsJson { get; set; } = "[]";
    public int    Order   { get; set; }
}

public class Social
{
    public int    Id       { get; set; }
    public string Name     { get; set; } = "";
    public string IconPath { get; set; } = "";
    public string Url      { get; set; } = "";
    public int    Order    { get; set; }
}

public class AdminUser
{
    public int    Id           { get; set; }
    public string Username     { get; set; } = "admin";
    public string PasswordHash { get; set; } = "";
}

public class SiteTexts
{
    public int Id { get; set; }

    // ---- NAV (shared across all pages) ----
    public string NavLogo      { get; set; } = "Mrnobudi";
    public string NavHome      { get; set; } = "Home";
    public string NavAbout     { get; set; } = "About";
    public string NavPortfolio { get; set; } = "Portfolio";
    public string NavContact   { get; set; } = "Let's talk";

    // ---- HOME PAGE ----
    public string HomeSkillsTitle { get; set; } = "Skills";

    // ---- ABOUT PAGE ----
    public string AboutPageTitle        { get; set; } = "About me";
    public string AboutEducationHeader  { get; set; } = "Education";
    public string AboutExperienceHeader { get; set; } = "Experience";

    // ---- PORTFOLIO PAGE ----
    public string PortfolioPageTitle { get; set; } = "Portfolio";

    // ---- CONTACT PAGE ----
    public string ContactPageTitle { get; set; } = "Contact";
}
