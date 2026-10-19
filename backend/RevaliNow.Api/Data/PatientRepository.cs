using System.Security.Claims;
using Dapper;
using RevaliNow.Api.Models;

namespace RevaliNow.Api.Data;

public interface IPatientRepository
{
    Task<IReadOnlyList<ExercisePlanDto>> GetPlansAsync(ClaimsPrincipal user, CancellationToken cancellationToken);
    Task<IReadOnlyList<AppointmentDto>> GetAppointmentsAsync(ClaimsPrincipal user, CancellationToken cancellationToken);
    Task<IReadOnlyList<PainEntryDto>> GetPainEntriesAsync(ClaimsPrincipal user, CancellationToken cancellationToken);
    Task<PainEntryDto> CreatePainEntryAsync(ClaimsPrincipal user, byte score, string? notes, CancellationToken cancellationToken);
    Task CompleteExerciseAsync(ClaimsPrincipal user, int exercisePlanId, CancellationToken cancellationToken);
}

public sealed class PatientRepository(SqlConnectionFactory connections) : IPatientRepository
{
    public async Task<IReadOnlyList<ExercisePlanDto>> GetPlansAsync(ClaimsPrincipal user, CancellationToken cancellationToken)
    {
        await using var connection = await connections.OpenAsync(user, cancellationToken);
        var rows = await connection.QueryAsync<ExercisePlanDto>(new CommandDefinition(
            "SELECT ExercisePlanId, Name, Description, StartDate, EndDate, Repetitions, Sets, FrequencyPerDay, CompletedToday, Remarks FROM dbo.vw_PatientExercisePlans ORDER BY StartDate DESC;",
            cancellationToken: cancellationToken));
        return rows.AsList();
    }

    public async Task<IReadOnlyList<AppointmentDto>> GetAppointmentsAsync(ClaimsPrincipal user, CancellationToken cancellationToken)
    {
        await using var connection = await connections.OpenAsync(user, cancellationToken);
        var rows = await connection.QueryAsync<AppointmentDto>(new CommandDefinition(
            "SELECT AppointmentId, AppointmentAt, DurationMinutes, Type, Status, PhysicianName FROM dbo.vw_PatientAppointments ORDER BY AppointmentAt DESC;",
            cancellationToken: cancellationToken));
        return rows.AsList();
    }

    public async Task<IReadOnlyList<PainEntryDto>> GetPainEntriesAsync(ClaimsPrincipal user, CancellationToken cancellationToken)
    {
        await using var connection = await connections.OpenAsync(user, cancellationToken);
        var rows = await connection.QueryAsync<PainEntryDto>(new CommandDefinition(
            "SELECT TOP (30) PainEntryId, RecordedAt, PainScore, Notes FROM dbo.PainEntries ORDER BY RecordedAt DESC;",
            cancellationToken: cancellationToken));
        return rows.AsList();
    }

    public async Task<PainEntryDto> CreatePainEntryAsync(ClaimsPrincipal user, byte score, string? notes, CancellationToken cancellationToken)
    {
        await using var connection = await connections.OpenAsync(user, cancellationToken);
        return await connection.QuerySingleAsync<PainEntryDto>(new CommandDefinition(
            "dbo.usp_RecordPainEntry", new { PainScore = score, Notes = notes },
            commandType: System.Data.CommandType.StoredProcedure, cancellationToken: cancellationToken));
    }

    public async Task CompleteExerciseAsync(ClaimsPrincipal user, int exercisePlanId, CancellationToken cancellationToken)
    {
        await using var connection = await connections.OpenAsync(user, cancellationToken);
        await connection.ExecuteAsync(new CommandDefinition(
            "dbo.usp_CompleteExercise", new { ExercisePlanId = exercisePlanId },
            commandType: System.Data.CommandType.StoredProcedure, cancellationToken: cancellationToken));
    }
}
