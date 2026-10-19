using Moq;
using RevaliNow.Api.Data;
using RevaliNow.Api.Models;
using RevaliNow.Api.Services;
using Xunit;

namespace RevaliNow.Api.Tests;

public sealed class AuthServiceTests
{
    [Fact]
    public async Task AuthenticateAsync_ReturnsTokenForValidPatientCredentials()
    {
        const string password = "Welkom123!";
        var patient = new AuthenticatedUser(
            51, 3, "patient3", BCrypt.Net.BCrypt.HashPassword(password), "Sam", "Patient", "Patient");
        var repository = new Mock<IAuthRepository>();
        repository.Setup(item => item.FindByUsernameAsync("patient3", It.IsAny<CancellationToken>()))
            .ReturnsAsync(patient);
        var tokens = new Mock<ITokenService>();
        tokens.Setup(item => item.CreateToken(patient)).Returns("signed-token");
        var service = new AuthService(repository.Object, tokens.Object);

        var result = await service.AuthenticateAsync(new LoginRequest("patient3", password), CancellationToken.None);

        Assert.NotNull(result);
        Assert.Equal("signed-token", result.Token);
        Assert.Equal(3, result.User.PatientId);
    }

    [Fact]
    public async Task AuthenticateAsync_RejectsIncorrectPassword()
    {
        var patient = new AuthenticatedUser(
            51, 3, "patient3", BCrypt.Net.BCrypt.HashPassword("Welkom123!"), "Sam", "Patient", "Patient");
        var repository = new Mock<IAuthRepository>();
        repository.Setup(item => item.FindByUsernameAsync("patient3", It.IsAny<CancellationToken>()))
            .ReturnsAsync(patient);
        var tokens = new Mock<ITokenService>();
        var service = new AuthService(repository.Object, tokens.Object);

        var result = await service.AuthenticateAsync(new LoginRequest("patient3", "incorrect"), CancellationToken.None);

        Assert.Null(result);
        tokens.Verify(item => item.CreateToken(It.IsAny<AuthenticatedUser>()), Times.Never);
    }

    [Fact]
    public async Task AuthenticateAsync_DoesNotAuthenticateStaffAccounts()
    {
        var staff = new AuthenticatedUser(
            1, 0, "doctor", BCrypt.Net.BCrypt.HashPassword("password"), "Taylor", "Doctor", "Physician");
        var repository = new Mock<IAuthRepository>();
        repository.Setup(item => item.FindByUsernameAsync("doctor", It.IsAny<CancellationToken>()))
            .ReturnsAsync(staff);
        var tokens = new Mock<ITokenService>();
        var service = new AuthService(repository.Object, tokens.Object);

        var result = await service.AuthenticateAsync(new LoginRequest("doctor", "password"), CancellationToken.None);

        Assert.Null(result);
        tokens.Verify(item => item.CreateToken(It.IsAny<AuthenticatedUser>()), Times.Never);
    }
}
