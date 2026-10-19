SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
USE RevaliNowDb;
GO
CREATE FUNCTION dbo.fn_PatientAccess(@PatientId int)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS AccessGranted
    WHERE
        TRY_CONVERT(int, SESSION_CONTEXT(N'PatientId')) = @PatientId
        OR EXISTS (
            SELECT 1
            FROM dbo.PhysicianPatients AS pp
            WHERE pp.PatientId = @PatientId
              AND pp.PhysicianId = TRY_CONVERT(int, SESSION_CONTEXT(N'UserId'))
              AND SESSION_CONTEXT(N'Role') = N'Physician'
        );
GO

CREATE SECURITY POLICY dbo.PatientIsolationPolicy
ADD FILTER PREDICATE dbo.fn_PatientAccess(PatientId) ON dbo.Patients,
ADD FILTER PREDICATE dbo.fn_PatientAccess(PatientId) ON dbo.ExercisePlans,
ADD BLOCK PREDICATE dbo.fn_PatientAccess(PatientId) ON dbo.ExercisePlans AFTER INSERT,
ADD BLOCK PREDICATE dbo.fn_PatientAccess(PatientId) ON dbo.ExercisePlans AFTER UPDATE,
ADD FILTER PREDICATE dbo.fn_PatientAccess(PatientId) ON dbo.Appointments,
ADD BLOCK PREDICATE dbo.fn_PatientAccess(PatientId) ON dbo.Appointments AFTER INSERT,
ADD BLOCK PREDICATE dbo.fn_PatientAccess(PatientId) ON dbo.Appointments AFTER UPDATE,
ADD FILTER PREDICATE dbo.fn_PatientAccess(PatientId) ON dbo.CompletedExercises,
ADD BLOCK PREDICATE dbo.fn_PatientAccess(PatientId) ON dbo.CompletedExercises AFTER INSERT,
ADD FILTER PREDICATE dbo.fn_PatientAccess(PatientId) ON dbo.PainEntries,
ADD BLOCK PREDICATE dbo.fn_PatientAccess(PatientId) ON dbo.PainEntries AFTER INSERT,
ADD FILTER PREDICATE dbo.fn_PatientAccess(PatientId) ON dbo.ActivityLogEntries
WITH (STATE = ON);
GO

CREATE TRIGGER dbo.TR_PainEntries_Audit
ON dbo.PainEntries
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.AuditLogs (PatientId, ActorUserId, EventType)
    SELECT PatientId, TRY_CONVERT(int, SESSION_CONTEXT(N'UserId')), N'PainEntryCreated'
    FROM inserted;
END;
GO

CREATE TRIGGER dbo.TR_CompletedExercises_Audit
ON dbo.CompletedExercises
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.AuditLogs (PatientId, ActorUserId, EventType)
    SELECT PatientId, TRY_CONVERT(int, SESSION_CONTEXT(N'UserId')), N'ExerciseCompleted'
    FROM inserted;
END;
GO
