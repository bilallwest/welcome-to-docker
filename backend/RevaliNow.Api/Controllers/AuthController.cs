using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using RevaliNow.Api.Models;
using RevaliNow.Api.Services;

namespace RevaliNow.Api.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController(AuthService auth) : ControllerBase
{
    [AllowAnonymous]
    [HttpPost("login")]
    [ProducesResponseType<LoginResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest request, CancellationToken cancellationToken)
    {
        var response = await auth.AuthenticateAsync(request, cancellationToken);
        return response is null ? Unauthorized(new ProblemDetails { Title = "Inloggen mislukt", Detail = "Gebruikersnaam of wachtwoord is onjuist." }) : Ok(response);
    }

    [Authorize(Roles = "Patient")]
    [HttpGet("me")]
    public ActionResult<UserDto> CurrentUser()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var patientId = int.Parse(User.FindFirstValue("PatientId")!);
        return Ok(new UserDto(userId, patientId, User.Identity?.Name ?? "",
            User.FindFirstValue("firstName") ?? "", User.FindFirstValue("lastName") ?? "", "Patient"));
    }
}
