using Microsoft.Data.SqlClient;
using RevaliNow.Seeder;

var excelPath = args.FirstOrDefault(argument => !argument.StartsWith("--", StringComparison.Ordinal));
if (string.IsNullOrWhiteSpace(excelPath) || !File.Exists(excelPath))
{
    Console.Error.WriteLine("Usage: dotnet run --project backend/RevaliNow.Seeder -- <path-to-Eindopdracht-data-v3.xlsx>");
    return 2;
}

var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__Seeder");
if (string.IsNullOrWhiteSpace(connectionString))
{
    Console.Error.WriteLine("Set ConnectionStrings__Seeder to the database connection string before importing.");
    return 2;
}

try
{
    await using var connection = new SqlConnection(connectionString);
    await connection.OpenAsync();
    await new ExcelSeeder(connection).RunAsync(excelPath);
    Console.WriteLine("Import completed. Staff accounts are disabled; patient demo accounts use patient<ID> / Welkom123!.");
    return 0;
}
catch (Exception exception) when (exception is not OperationCanceledException)
{
    Console.Error.WriteLine($"Import failed: {exception.Message}");
    return 1;
}
