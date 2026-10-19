using System.ComponentModel.DataAnnotations;

namespace RevaliNow.Api.Models;

public sealed record LoginRequest(
    [Required, StringLength(50, MinimumLength = 1)] string Username,
    [Required, StringLength(200, MinimumLength = 1)] string Password);

public sealed record UserDto(int UserId, int PatientId, string Username, string FirstName, string LastName, string Role);
public sealed record LoginResponse(string Token, UserDto User);
public sealed record PainEntryDto(int PainEntryId, DateTime RecordedAt, byte PainScore, string? Notes);
public sealed record CreatePainEntryRequest(
    [Range(0, 10)] byte PainScore,
    [StringLength(500)] string? Notes);
