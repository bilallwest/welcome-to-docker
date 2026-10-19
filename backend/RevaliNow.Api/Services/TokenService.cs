using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using RevaliNow.Api.Models;

namespace RevaliNow.Api.Services;

public interface ITokenService
{
    string CreateToken(AuthenticatedUser user);
}

public sealed class TokenService(IConfiguration configuration) : ITokenService
{
    public string CreateToken(AuthenticatedUser user)
    {
        var key = configuration["Jwt:Key"]
            ?? throw new InvalidOperationException("JWT signing key is not configured.");
        var issuer = configuration["Jwt:Issuer"] ?? "RevaliNow";
        var audience = configuration["Jwt:Audience"] ?? "RevaliNow.Web";
        var expires = int.TryParse(configuration["Jwt:ExpiryMinutes"], out var value) ? value : 60;
        var credentials = new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key)), SecurityAlgorithms.HmacSha256);
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new Claim("PatientId", user.PatientId.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Role, user.Role),
            new Claim("firstName", user.FirstName),
            new Claim("lastName", user.LastName)
        };
        var token = new JwtSecurityToken(issuer, audience, claims,
            expires: DateTime.UtcNow.AddMinutes(expires), signingCredentials: credentials);
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
