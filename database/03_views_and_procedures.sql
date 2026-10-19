SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
USE RevaliNowDb;
GO
CREATE PROCEDURE dbo.usp_FindUserForLogin
    @Username nvarchar(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT UserId, PatientId, Username, PasswordHash, FirstName, LastName, Role
    FROM dbo.Users
    WHERE Username = @Username;
END;
GO

CREATE VIEW dbo.vw_PatientExercisePlans
AS
    SELECT p.ExercisePlanId, p.PatientId, p.ExerciseId, e.Name, e.Description,
           p.StartDate, p.EndDate, p.Repetitions, p.Sets, p.FrequencyPerDay, p.Remarks,
           CONVERT(bit, CASE WHEN EXISTS (
               SELECT 1 FROM dbo.CompletedExercises AS c
               WHERE c.ExercisePlanId = p.ExercisePlanId
                 AND c.CompletedAt >= CONVERT(date, SYSDATETIME())
                 AND c.CompletedAt < DATEADD(day, 1, CONVERT(date, SYSDATETIME()))
                 AND c.IsChecked = 1
           ) THEN 1 ELSE 0 END) AS CompletedToday
    FROM dbo.ExercisePlans AS p
    JOIN dbo.Exercises AS e ON e.ExerciseId = p.ExerciseId
    WHERE p.StartDate <= SYSDATETIME() AND p.EndDate >= SYSDATETIME();
GO

CREATE VIEW dbo.vw_PatientAppointments
AS
    SELECT a.AppointmentId, a.PatientId, a.AppointmentAt, a.DurationMinutes, a.Type, a.Status,
           CONCAT(u.FirstName, N' ', u.LastName) AS PhysicianName
    FROM dbo.Appointments AS a
    JOIN dbo.Users AS u ON u.UserId = a.PhysicianId;
GO

CREATE PROCEDURE dbo.usp_CompleteExercise
    @ExercisePlanId int
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @PatientId int = TRY_CONVERT(int, SESSION_CONTEXT(N'PatientId'));
    DECLARE @Frequency smallint;
    DECLARE @Completions int;

    SELECT @Frequency = FrequencyPerDay
    FROM dbo.ExercisePlans
    WHERE ExercisePlanId = @ExercisePlanId AND PatientId = @PatientId
      AND StartDate <= SYSDATETIME() AND EndDate >= SYSDATETIME();

    IF @Frequency IS NULL
        THROW 50001, 'Active exercise plan was not found for the signed-in patient.', 1;

    SELECT @Completions = COUNT(*)
    FROM dbo.CompletedExercises
    WHERE ExercisePlanId = @ExercisePlanId
      AND CompletedAt >= CONVERT(date, SYSDATETIME())
      AND CompletedAt < DATEADD(day, 1, CONVERT(date, SYSDATETIME()))
      AND IsChecked = 1;

    IF @Completions >= @Frequency
        THROW 50002, 'The daily completion limit for this exercise has been reached.', 1;

    INSERT dbo.CompletedExercises (PatientId, ExercisePlanId, CompletedAt, IsChecked)
    VALUES (@PatientId, @ExercisePlanId, SYSDATETIME(), 1);
END;
GO

CREATE PROCEDURE dbo.usp_RecordPainEntry
    @PainScore tinyint,
    @Notes nvarchar(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @PainScore > 10
        THROW 50003, 'Pain score must be between 0 and 10.', 1;

    DECLARE @CreatedEntry TABLE
    (
        PainEntryId int,
        RecordedAt datetime2(0),
        PainScore tinyint,
        Notes nvarchar(500)
    );

    INSERT dbo.PainEntries (PatientId, PainScore, Notes)
    OUTPUT inserted.PainEntryId, inserted.RecordedAt, inserted.PainScore, inserted.Notes
        INTO @CreatedEntry
    VALUES (TRY_CONVERT(int, SESSION_CONTEXT(N'PatientId')), @PainScore, @Notes);

    SELECT PainEntryId, RecordedAt, PainScore, Notes FROM @CreatedEntry;
END;
GO
