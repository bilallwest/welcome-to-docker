using RevaliNow.Api.Data;
using RevaliNow.Api.Models;

namespace RevaliNow.Api.Services;

public sealed class AuthService(IAuthRepository users, ITokenService tokens)
{
    public async Task<LoginResponse?> AuthenticateAsync(LoginRequest request, CancellationToken cancellationToken)
    {
        var user = await users.FindByUsernameAsync(request.Username.Trim(), cancellationToken);
        if (user is null || user.Role != "Patient" || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            return null;

        return new LoginResponse(tokens.CreateToken(user), user.ToDto());
    }
}
