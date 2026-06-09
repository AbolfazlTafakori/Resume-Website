using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Collections.Concurrent;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using ResumeAPI.Data;
using ResumeAPI.DTOs;

namespace ResumeAPI.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(AppDbContext db, IConfiguration config) : ControllerBase
{
    // Simple in-memory brute-force protection: max 5 attempts per IP per 10 minutes
    private static readonly ConcurrentDictionary<string, (int Count, DateTime Window)> _loginAttempts = new();

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest req)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var now = DateTime.UtcNow;

        var entry = _loginAttempts.GetOrAdd(ip, _ => (0, now));
        if (now - entry.Window > TimeSpan.FromMinutes(10))
            entry = (0, now);

        if (entry.Count >= 5)
        {
            var wait = (int)(10 - (now - entry.Window).TotalMinutes) + 1;
            return StatusCode(429, $"Too many attempts. Try again in {wait} minutes.");
        }

        var user = await db.AdminUsers.FirstOrDefaultAsync(u => u.Username == req.Username);
        // Always run BCrypt to prevent username enumeration via timing
        var hash = user?.PasswordHash ?? BCrypt.Net.BCrypt.HashPassword("__dummy__");
        if (user == null || !BCrypt.Net.BCrypt.Verify(req.Password, hash))
        {
            _loginAttempts[ip] = (entry.Count + 1, entry.Window);
            return Unauthorized();
        }

        // Reset on success
        _loginAttempts.TryRemove(ip, out _);
        var token = GenerateToken(user.Username);
        return Ok(new { token });
    }

    [HttpPost("change-password")]
    [Microsoft.AspNetCore.Authorization.Authorize]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest req)
    {
        var username = User.Identity?.Name;
        var user = await db.AdminUsers.FirstOrDefaultAsync(u => u.Username == username);
        if (user == null || !BCrypt.Net.BCrypt.Verify(req.CurrentPassword, user.PasswordHash))
            return BadRequest("Current password is incorrect");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.NewPassword);
        await db.SaveChangesAsync();
        return Ok();
    }

    private string GenerateToken(string username)
    {
        var key  = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(config["Jwt:Key"]!));
        var cred = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var tok  = new JwtSecurityToken(
            issuer:   config["Jwt:Issuer"],
            audience: config["Jwt:Audience"],
            claims:   [new Claim(ClaimTypes.Name, username)],
            expires:  DateTime.UtcNow.AddDays(7),
            signingCredentials: cred);
        return new JwtSecurityTokenHandler().WriteToken(tok);
    }
}
