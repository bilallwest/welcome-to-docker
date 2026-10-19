using Dapper;
using RevaliNow.Api.Models;

namespace RevaliNow.Api.Data;

public interface IAuthRepository
{
    Task<AuthenticatedUser?> FindByUsernameAsync(string username, CancellationToken cancellationToken);
}

public sealed class AuthRepository(SqlConnectionFactory connections) : IAuthRepository
{
    public async Task<AuthenticatedUser?> FindByUsernameAsync(string username, CancellationToken cancellationToken)
    {
        await using var connection = await connections.OpenAsync(cancellationToken: cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<AuthenticatedUser>(
            new CommandDefinition("dbo.usp_FindUserForLogin", new { Username = username },
                commandType: System.Data.CommandType.StoredProcedure, cancellationToken: cancellationToken));
    }
}
