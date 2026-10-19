using System.Data;
using ClosedXML.Excel;
using Microsoft.Data.SqlClient;

namespace RevaliNow.Seeder;

public sealed class ExcelSeeder(SqlConnection connection)
{
    private static readonly string[] CoreTables =
    [
        "Insurers", "Users", "Patients", "Exercises", "ExercisePlans",
        "Appointments", "CompletedExercises", "PainEntries", "ActivityLogEntries"
    ];

    public async Task RunAsync(string path)
    {
        using var workbook = new XLWorkbook(path);
        using var transaction = (SqlTransaction)await connection.BeginTransactionAsync();
        try
        {
            await EnsureEmptyAsync(transaction);
            await ImportInsurersAsync(workbook, transaction);
            await ImportUsersAsync(workbook, transaction);
            await ImportPatientsAsync(workbook, transaction);
            await ImportPatientPhysiciansAsync(workbook, transaction);
            await ImportPatientAccountsAsync(transaction);
            await ImportExercisesAsync(workbook, transaction);
            await ImportExercisePlansAsync(workbook, transaction);
            await ImportAppointmentsAsync(workbook, transaction);
            await ImportCompletedExercisesAsync(workbook, transaction);
            await ImportPainEntriesAsync(workbook, transaction);
            await ImportActivityLogAsync(workbook, transaction);
            await transaction.CommitAsync();
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    private async Task EnsureEmptyAsync(SqlTransaction transaction)
    {
        foreach (var table in CoreTables)
        {
            var count = await new SqlCommand($"SELECT COUNT_BIG(*) FROM dbo.[{table}];", connection, transaction)
                .ExecuteScalarAsync();
            if (Convert.ToInt64(count) != 0)
                throw new InvalidOperationException($"dbo.{table} already contains data. Use a clean RevaliNowDb before importing.");
        }
    }

    private Task ImportInsurersAsync(XLWorkbook workbook, SqlTransaction tx) =>
        BulkAsync("Insurers", Table(("InsurerId", typeof(int)), ("Name", typeof(string)),
            Rows(workbook.Worksheet("Zorgverzekeraars"), row =>
                new object?[] { Int(row, "ZorgverzekeraarID"), Required(row, "Naam") })), tx);

    private Task ImportUsersAsync(XLWorkbook workbook, SqlTransaction tx) =>
        BulkAsync("Users", Table(
            ("UserId", typeof(int)), ("Username", typeof(string)), ("PasswordHash", typeof(string)),
            ("Role", typeof(string)), ("FirstName", typeof(string)), ("LastName", typeof(string)), ("InsurerId", typeof(int)),
            Rows(workbook.Worksheet("Gebruikers"), row =>
            {
                var role = NormalizeRole(Required(row, "Rol"));
                int? insurerId = role == "Insurer" ? Int(row, "OrganisatieID") : null;
                return [Int(row, "GebruikerID"), Required(row, "Gebruikersnaam"), "!DISABLED!", role,
                    Required(row, "Voornaam"), Required(row, "Achternaam"), insurerId];
            })), tx);

    private Task ImportPatientsAsync(XLWorkbook workbook, SqlTransaction tx) =>
        BulkAsync("Patients", Table(
            ("PatientId", typeof(int)), ("FirstName", typeof(string)), ("LastName", typeof(string)),
            ("BirthDate", typeof(DateTime)), ("Address", typeof(string)), ("PhoneNumber", typeof(string)),
            ("Email", typeof(string)), ("GeneralPractitionerId", typeof(int)), ("InsurerId", typeof(int)),
            Rows(workbook.Worksheet("Patienten"), row =>
            [
                Int(row, "PatientID"), Required(row, "Voornaam"), Required(row, "Achternaam"),
                Date(row, "Geboortedatum"), Required(row, "Adres"), Required(row, "Telefoonnummer"),
                Required(row, "Email"), Int(row, "HuisartsID"), Int(row, "ZorgverzekeraarID")
            ])), tx);

    private Task ImportPatientPhysiciansAsync(XLWorkbook workbook, SqlTransaction tx) =>
        BulkAsync("PhysicianPatients", Table(
            ("PatientId", typeof(int)), ("PhysicianId", typeof(int)),
            Rows(workbook.Worksheet("Revalidatieartsen"), row =>
                new object?[] { Int(row, "PatientID"), Int(row, "RevalidatieartsID") })), tx);

    private Task ImportPatientAccountsAsync(SqlTransaction tx)
    {
        var table = new DataTable();
        table.Columns.Add("Username", typeof(string));
        table.Columns.Add("PasswordHash", typeof(string));
        table.Columns.Add("Role", typeof(string));
        table.Columns.Add("FirstName", typeof(string));
        table.Columns.Add("LastName", typeof(string));
        table.Columns.Add("PatientId", typeof(int));
        using var command = new SqlCommand("SELECT PatientId, FirstName, LastName FROM dbo.Patients;", connection, tx);
        using var reader = command.ExecuteReader();
        while (reader.Read())
        {
            table.Rows.Add(
                $"patient{reader.GetInt32(0)}",
                BCrypt.Net.BCrypt.HashPassword("Welkom123!"),
                "Patient",
                reader.GetString(1),
                reader.GetString(2),
                reader.GetInt32(0));
        }
        reader.Close();
        return BulkAsync("Users", table, tx);
    }

    private Task ImportExercisesAsync(XLWorkbook workbook, SqlTransaction tx) =>
        BulkAsync("Exercises", Table(
            ("ExerciseId", typeof(int)), ("Name", typeof(string)), ("Description", typeof(string)),
            ("InstructionVideoUrl", typeof(string)),
            Rows(workbook.Worksheet("Oefeningen"), row =>
            {
                var url = Optional(row, "InstructieVideoURL");
                if (url is not null && !url.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
                    url = null;
                return [Int(row, "OefeningID"), Required(row, "Naam"), Required(row, "Beschrijving"), url];
            })), tx);

    private Task ImportExercisePlansAsync(XLWorkbook workbook, SqlTransaction tx) =>
        BulkAsync("ExercisePlans", Table(
            ("ExercisePlanId", typeof(int)), ("PatientId", typeof(int)), ("ExerciseId", typeof(int)),
            ("PhysicianId", typeof(int)), ("StartDate", typeof(DateTime)), ("EndDate", typeof(DateTime)),
            ("Repetitions", typeof(short)), ("Sets", typeof(short)), ("FrequencyPerDay", typeof(short)), ("Remarks", typeof(string)),
            Rows(workbook.Worksheet("Oefenplannen"), row =>
            [
                Int(row, "PatientOefenplanID"), Int(row, "PatientID"), Int(row, "OefeningID"),
                Int(row, "RevalidatieartsID"), Date(row, "StartDatum"), Date(row, "EindDatum"),
                SmallInt(row, "Herhalingen"), SmallInt(row, "Sets"), SmallInt(row, "FrequentiePerDag"),
                Optional(row, "Opmerkingen")
            ])), tx);

    private Task ImportAppointmentsAsync(XLWorkbook workbook, SqlTransaction tx) =>
        BulkAsync("Appointments", Table(
            ("AppointmentId", typeof(int)), ("PatientId", typeof(int)), ("PhysicianId", typeof(int)),
            ("AppointmentAt", typeof(DateTime)), ("DurationMinutes", typeof(short)), ("Type", typeof(string)),
            ("Status", typeof(string)),
            Rows(workbook.Worksheet("Afspraken"), row =>
            [
                Int(row, "AfspraakID"), Int(row, "PatientID"), Int(row, "RevalidatieartsID"),
                Date(row, "DatumTijdAfspraak"), SmallInt(row, "DuurMinuten"),
                Required(row, "TypeAfspraak"), NormalizeAppointmentStatus(Required(row, "Status"))
            ])), tx);

    private async Task ImportCompletedExercisesAsync(XLWorkbook workbook, SqlTransaction tx)
    {
        var patientsByPlan = new Dictionary<int, int>();
        using (var command = new SqlCommand("SELECT ExercisePlanId, PatientId FROM dbo.ExercisePlans;", connection, tx))
        using (var reader = await command.ExecuteReaderAsync())
            while (await reader.ReadAsync())
                patientsByPlan.Add(reader.GetInt32(0), reader.GetInt32(1));

        var table = Table(
            ("CompletedExerciseId", typeof(int)), ("PatientId", typeof(int)), ("ExercisePlanId", typeof(int)),
            ("CompletedAt", typeof(DateTime)), ("IsChecked", typeof(bool)),
            Rows(workbook.Worksheet("Uitgevoerde-oefeningen"), row =>
            [
                Int(row, "UitgevoerdeOefeningID"),
                patientsByPlan.TryGetValue(Int(row, "PatientOefenplanID"), out var patientId)
                    ? patientId : throw new InvalidDataException("Exercise plan ID does not exist."),
                Int(row, "PatientOefenplanID"), Date(row, "DatumTijdAfgevinkt"), Bool(row, "IsAfgevinkt")
            ]));
        await BulkAsync("CompletedExercises", table, tx);
    }

    private Task ImportPainEntriesAsync(XLWorkbook workbook, SqlTransaction tx) =>
        BulkAsync("PainEntries", Table(
            ("PainEntryId", typeof(int)), ("PatientId", typeof(int)), ("RecordedAt", typeof(DateTime)),
            ("PainScore", typeof(byte)), ("Notes", typeof(string)),
            Rows(workbook.Worksheet("Pijnindicaties"), row =>
            [
                Int(row, "PijnIndicatieID"), Int(row, "PatientID"), Date(row, "DatumTijdRegistratie"),
                Byte(row, "PijnScore"), Optional(row, "Toelichting")
            ])), tx);

    private Task ImportActivityLogAsync(XLWorkbook workbook, SqlTransaction tx) =>
        BulkAsync("ActivityLogEntries", Table(
            ("ActivityLogEntryId", typeof(int)), ("PatientId", typeof(int)), ("ActivityAt", typeof(DateTime)),
            ("Description", typeof(string)),
            Rows(workbook.Worksheet("Activiteiten-logboek"), row =>
            [
                Int(row, "LogboekID"), Int(row, "PatientID"), Date(row, "DatumTijdActiviteit"),
                Required(row, "Beschrijving")
            ])), tx);

    private async Task BulkAsync(string destination, DataTable table, SqlTransaction tx)
    {
        using var bulk = new SqlBulkCopy(connection, SqlBulkCopyOptions.KeepIdentity | SqlBulkCopyOptions.CheckConstraints, tx)
        {
            DestinationTableName = $"dbo.[{destination}]",
            BulkCopyTimeout = 120
        };
        foreach (DataColumn column in table.Columns)
            bulk.ColumnMappings.Add(column.ColumnName, column.ColumnName);
        await bulk.WriteToServerAsync(table);
    }

    private static DataTable Table(params object?[] values)
    {
        var table = new DataTable();
        var columnIndex = 0;
        while (columnIndex < values.Length && values[columnIndex] is ValueTuple<string, Type> column)
        {
            table.Columns.Add(column.Item1, column.Item2);
            columnIndex++;
        }
        for (; columnIndex < values.Length; columnIndex++)
            foreach (var row in (IEnumerable<object?[]>)values[columnIndex]!)
                table.Rows.Add(row.Select(value => value ?? DBNull.Value).ToArray());
        return table;
    }

    private static IEnumerable<object?[]> Rows(IXLWorksheet sheet, Func<HeaderRow, object?[]> convert)
    {
        var headers = sheet.Row(1).CellsUsed().ToDictionary(
            cell => cell.GetString().Trim(), cell => cell.Address.ColumnNumber, StringComparer.OrdinalIgnoreCase);
        if (headers.Count == 0) throw new InvalidDataException($"Worksheet '{sheet.Name}' has no header row.");
        foreach (var row in sheet.RowsUsed().Skip(1))
        {
            if (row.CellsUsed().All(cell => string.IsNullOrWhiteSpace(cell.GetString()))) continue;
            object?[] converted;
            try { converted = convert(new HeaderRow(row, headers)); }
            catch (Exception exception) when (exception is FormatException or InvalidDataException or OverflowException)
            {
                throw new InvalidDataException($"Invalid value in worksheet '{sheet.Name}', row {row.RowNumber()}: {exception.Message}", exception);
            }
            yield return converted;
        }
    }

    private sealed class HeaderRow(IXLRow row, IReadOnlyDictionary<string, int> headers)
    {
        public int RowNumber => row.RowNumber();

        public IXLCell Cell(params string[] names)
        {
            foreach (var name in names)
            {
                if (headers.TryGetValue(name, out var index))
                    return row.Cell(index);
            }
            throw new InvalidDataException($"Required column '{names[0]}' is missing.");
        }
    }

    private static int Int(HeaderRow row, params string[] names) => row.Cell(names).GetValue<int>();
    private static short SmallInt(HeaderRow row, params string[] names) => row.Cell(names).GetValue<short>();
    private static byte Byte(HeaderRow row, params string[] names) => row.Cell(names).GetValue<byte>();
    private static bool Bool(HeaderRow row, params string[] names) => row.Cell(names).GetValue<bool>();
    private static DateTime Date(HeaderRow row, params string[] names) => row.Cell(names).GetValue<DateTime>();
    private static string Required(HeaderRow row, params string[] names)
    {
        var value = row.Cell(names).GetString().Trim();
        return string.IsNullOrEmpty(value) ? throw new InvalidDataException($"Column '{names[0]}' may not be empty.") : value;
    }
    private static string? Optional(HeaderRow row, params string[] names)
    {
        var cell = row.Cell(names);
        var value = cell.IsEmpty() ? null : cell.GetString().Trim();
        return string.IsNullOrEmpty(value) ? null : value;
    }

    private static string NormalizeRole(string sourceRole) => sourceRole.Trim().ToLowerInvariant() switch
    {
        "patient" or "patiënt" => "Patient",
        "huisarts" or "generalpractitioner" => "GeneralPractitioner",
        "revalidatiearts" or "physician" => "Physician",
        "zorgverzekeraar" or "verzekeraar" or "insurer" => "Insurer",
        var value => throw new InvalidDataException($"Unknown user role '{value}'.")
    };

    private static string NormalizeAppointmentStatus(string status) => status.Trim() switch
    {
        "Gepland" or "Bevestigd" or "Afgerond" or "Geannuleerd" => status.Trim(),
        var value => throw new InvalidDataException($"Unknown appointment status '{value}'.")
    };
}
