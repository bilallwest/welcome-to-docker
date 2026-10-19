using System.Security.Claims;
using Dapper;
using Microsoft.Data.SqlClient;

namespace RevaliNow.Api.Data;

public sealed class SqlConnectionFactory(IConfiguration configuration)
{
    public async Task<SqlConnection> OpenAsync(ClaimsPrincipal? principal = null, CancellationToken cancellationToken = default)
    {
        var connectionString = configuration.GetConnectionString("Default");
        if (string.IsNullOrWhiteSpace(connectionString))
            throw new InvalidOperationException("Configure ConnectionStrings__Default before starting the API.");

        var connection = new SqlConnection(connectionString);
        try
        {
            await connection.OpenAsync(cancellationToken);
            var userId = ParseClaim(principal, ClaimTypes.NameIdentifier);
            var patientId = ParseClaim(principal, "PatientId");
            var role = principal?.FindFirst(ClaimTypes.Role)?.Value;
            await connection.ExecuteAsync(new CommandDefinition(
                "EXEC sys.sp_set_session_context @key=N'UserId', @value=@UserId; " +
                "EXEC sys.sp_set_session_context @key=N'PatientId', @value=@PatientId; " +
                "EXEC sys.sp_set_session_context @key=N'Role', @value=@Role;",
                new { UserId = userId, PatientId = patientId, Role = role },
                cancellationToken: cancellationToken));
            return connection;
        }
        catch
        {
            await connection.DisposeAsync();
            throw;
        }
    }

    private static int? ParseClaim(ClaimsPrincipal? principal, string claimType) =>
        int.TryParse(principal?.FindFirst(claimType)?.Value, out var value) ? value : null;
}
