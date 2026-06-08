using Microsoft.EntityFrameworkCore;
using ResumeAPI.Models;

namespace ResumeAPI.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Profile>   Profiles   => Set<Profile>();
    public DbSet<Skill>     Skills     => Set<Skill>();
    public DbSet<Project>   Projects   => Set<Project>();
    public DbSet<Education> Educations => Set<Education>();
    public DbSet<Experience> Experiences => Set<Experience>();
    public DbSet<Social>    Socials    => Set<Social>();
    public DbSet<AdminUser> AdminUsers  => Set<AdminUser>();
    public DbSet<SiteTexts> SiteTexts   => Set<SiteTexts>();
}
