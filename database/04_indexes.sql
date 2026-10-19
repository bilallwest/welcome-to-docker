SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
USE RevaliNowDb;
GO
CREATE INDEX IX_ExercisePlans_Patient_Period
    ON dbo.ExercisePlans(PatientId, StartDate, EndDate)
    INCLUDE (ExerciseId, PhysicianId, Repetitions, Sets, FrequencyPerDay);

CREATE INDEX IX_CompletedExercises_Plan_CompletedAt
    ON dbo.CompletedExercises(ExercisePlanId, CompletedAt DESC)
    INCLUDE (PatientId, IsChecked);

CREATE INDEX IX_PainEntries_Patient_RecordedAt
    ON dbo.PainEntries(PatientId, RecordedAt DESC)
    INCLUDE (PainScore);

CREATE INDEX IX_Appointments_Patient_AppointmentAt
    ON dbo.Appointments(PatientId, AppointmentAt)
    INCLUDE (PhysicianId, DurationMinutes, Type, Status);

CREATE INDEX IX_ActivityLogEntries_Patient_ActivityAt
    ON dbo.ActivityLogEntries(PatientId, ActivityAt DESC);
GO
