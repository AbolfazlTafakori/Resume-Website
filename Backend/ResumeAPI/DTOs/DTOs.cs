namespace ResumeAPI.DTOs;

public record LoginRequest(string Username, string Password);
public record ChangePasswordRequest(string CurrentPassword, string NewPassword);

// All fields nullable so partial updates (e.g. saving only an avatar) bind
// without tripping ASP.NET's implicit [Required] on non-nullable strings,
// which otherwise returns 400. ProfileController only writes non-null fields.
public record ProfileDto(
    string? HeroTitle, string? HeroSubtitle,
    string? Name, string? Title, string? Location, string? Bio,
    string? HomeAvatar, string? AboutAvatar, string? ContactAvatar,
    string? HomeAvatarBorderColor,
    string? AboutAvatarBorderColor,
    string? ContactAvatarBorderColor);

public record SkillDto(string Name, string? IconPath);
public record ProjectDto(string Name, string? Overview, string? ImagePath, string? ViewUrl, string? GithubUrl);
public record EducationDto(string Period, string Description);
public record ExperienceDto(string Company, string Role, string Period, List<string> Bullets);
public record SocialItemDto(string Name, string IconPath, string Url);

public record SiteTextsDto(
    string NavLogo, string NavHome, string NavAbout, string NavPortfolio, string NavContact,
    string HomeSkillsTitle,
    string AboutPageTitle, string AboutEducationHeader, string AboutExperienceHeader,
    string PortfolioPageTitle,
    string ContactPageTitle);
