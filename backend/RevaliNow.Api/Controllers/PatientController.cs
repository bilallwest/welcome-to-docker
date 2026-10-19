using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using RevaliNow.Api.Data;
using RevaliNow.Api.Models;

namespace RevaliNow.Api.Controllers;

[ApiController]
[Authorize(Roles = "Patient")]
[Route("api/patient")]
public sealed class PatientController(IPatientRepository patients) : ControllerBase
{
    [HttpGet("dashboard")]
    public async Task<ActionResult<DashboardDto>> Dashboard(CancellationToken cancellationToken)
    {
        var user = CurrentUser();
        var plans = await patients.GetPlansAsync(User, cancellationToken);
        var appointments = await patients.GetAppointmentsAsync(User, cancellationToken);
        var pain = await patients.GetPainEntriesAsync(User, cancellationToken);
        return Ok(new DashboardDto(
            user,
            plans,
            appointments.Where(a => a.AppointmentAt >= DateTime.Now).OrderBy(a => a.AppointmentAt).FirstOrDefault(),
            pain.Take(7).ToArray()));
    }

    [HttpGet("plans")]
    public async Task<ActionResult<IReadOnlyList<ExercisePlanDto>>> Plans(CancellationToken cancellationToken) =>
        Ok(await patients.GetPlansAsync(User, cancellationToken));

    [HttpGet("appointments")]
    public async Task<ActionResult<IReadOnlyList<AppointmentDto>>> Appointments(CancellationToken cancellationToken) =>
        Ok(await patients.GetAppointmentsAsync(User, cancellationToken));

    [HttpGet("pain-entries")]
    public async Task<ActionResult<IReadOnlyList<PainEntryDto>>> PainEntries(CancellationToken cancellationToken) =>
        Ok(await patients.GetPainEntriesAsync(User, cancellationToken));

    [HttpPost("pain-entries")]
    public async Task<ActionResult<PainEntryDto>> CreatePainEntry(CreatePainEntryRequest request, CancellationToken cancellationToken)
    {
        var result = await patients.CreatePainEntryAsync(User, request.PainScore, request.Notes?.Trim(), cancellationToken);
        return CreatedAtAction(nameof(PainEntries), result);
    }

    [HttpPost("plans/{exercisePlanId:int}/complete")]
    public async Task<IActionResult> CompleteExercise(int exercisePlanId, CancellationToken cancellationToken)
    {
        try
        {
            await patients.CompleteExerciseAsync(User, exercisePlanId, cancellationToken);
            return NoContent();
        }
        catch (SqlException exception) when (exception.Number is 50001 or 50002)
        {
            return Conflict(new ProblemDetails { Title = "Oefening niet afgevinkt", Detail = exception.Message });
        }
    }

    private UserDto CurrentUser()
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var patientId = int.Parse(User.FindFirstValue("PatientId")!);
        return new UserDto(userId, patientId, User.Identity?.Name ?? "",
            User.FindFirstValue("firstName") ?? "", User.FindFirstValue("lastName") ?? "","Patient");
    }
}
