namespace RevaliNow.Api.Models;

public sealed record ExercisePlanDto(
    int ExercisePlanId, string Name, string Description, DateTime StartDate, DateTime EndDate,
    short Repetitions, short Sets, short FrequencyPerDay, bool CompletedToday, string? Remarks);

public sealed record AppointmentDto(
    int AppointmentId, DateTime AppointmentAt, short DurationMinutes, string Type, string Status, string PhysicianName);

public sealed record DashboardDto(
    UserDto User, IReadOnlyList<ExercisePlanDto> Plans, AppointmentDto? NextAppointment,
    IReadOnlyList<PainEntryDto> RecentPainEntries);

public sealed record AuthenticatedUser(int UserId, int PatientId, string Username, string PasswordHash, string FirstName, string LastName, string Role)
{
    public UserDto ToDto() => new(UserId, PatientId, Username, FirstName, LastName, Role);
}
