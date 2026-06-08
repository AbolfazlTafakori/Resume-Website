using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using ResumeAPI.Data;
using ResumeAPI.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

// ---- DATABASE (SQLite) ----
var dbPath = Environment.GetEnvironmentVariable("DB_PATH")
    ?? Path.Combine(AppContext.BaseDirectory, "resume.db");

builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseSqlite($"Data Source={dbPath}"));

// ---- JWT ----
var jwtKey = Environment.GetEnvironmentVariable("JWT_KEY")
    ?? builder.Configuration["Jwt:Key"]!;

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(opt =>
    {
        opt.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer           = true,
            ValidateAudience         = true,
            ValidateLifetime         = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer              = builder.Configuration["Jwt:Issuer"],
            ValidAudience            = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey         = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
        };
    });

builder.Services.AddAuthorization();

// ---- CORS ----
// In production ALLOWED_ORIGINS env var = "https://yourdomain.com"
// Leave empty to allow all (useful during install setup)
var allowedOrigins = Environment.GetEnvironmentVariable("ALLOWED_ORIGINS");
builder.Services.AddCors(opt =>
    opt.AddDefaultPolicy(p =>
    {
        if (!string.IsNullOrEmpty(allowedOrigins))
            p.WithOrigins(allowedOrigins.Split(',', StringSplitOptions.RemoveEmptyEntries));
        else
            p.AllowAnyOrigin();
        p.AllowAnyHeader().AllowAnyMethod();
    }));

var app = builder.Build();

// ---- SEED DATABASE ----
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.EnsureCreated();

    if (!db.AdminUsers.Any())
    {
        var adminUsername = Environment.GetEnvironmentVariable("ADMIN_USERNAME") ?? "admin";
        var adminPassword = Environment.GetEnvironmentVariable("ADMIN_PASSWORD") ?? "admin123";
        db.AdminUsers.Add(new AdminUser
        {
            Username     = adminUsername,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(adminPassword)
        });
        db.SaveChanges();
    }

    if (!db.Profiles.Any())
    {
        db.Profiles.Add(new Profile());
        db.SaveChanges();
    }

    if (!db.SiteTexts.Any())
    {
        db.SiteTexts.Add(new SiteTexts());
        db.SaveChanges();
    }

    if (!db.Skills.Any())
    {
        var defaultSkills = new[] {
            ("C#",     "preset:csharp.png",  0),
            (".NET",   "preset:Dot-NET.png", 1),
            ("SQL",    "preset:SQL.png",     2),
            ("Docker", "preset:Docker.png",  3),
            ("Git",    "preset:Git.png",     4),
            ("GitHub", "preset:GitHub.png",  5),
            ("HTML",   "preset:HTML.png",    6),
            ("CSS",    "preset:CSS.png",     7),
        };
        foreach (var (name, icon, order) in defaultSkills)
            db.Skills.Add(new Skill { Name = name, IconPath = icon, Order = order });
        db.SaveChanges();
    }

    if (!db.Socials.Any())
    {
        db.Socials.AddRange(
            new Social { Name="LinkedIn", IconPath="preset:LinkedIn", Url="#", Order=0 },
            new Social { Name="Email",    IconPath="preset:Email",    Url="#", Order=1 },
            new Social { Name="GitHub",   IconPath="preset:GitHub",   Url="#", Order=2 },
            new Social { Name="Telegram", IconPath="preset:Telegram", Url="#", Order=3 }
        );
        db.SaveChanges();
    }
}

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
