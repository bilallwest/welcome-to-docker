SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
IF DB_ID(N'RevaliNowDb') IS NULL
    CREATE DATABASE RevaliNowDb;
GO
USE RevaliNowDb;
GO

CREATE TABLE dbo.Insurers (
    InsurerId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Insurers PRIMARY KEY,
    Name nvarchar(100) NOT NULL CONSTRAINT UQ_Insurers_Name UNIQUE
);

CREATE TABLE dbo.Users (
    UserId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Users PRIMARY KEY,
    Username nvarchar(50) NOT NULL CONSTRAINT UQ_Users_Username UNIQUE,
    PasswordHash nvarchar(100) NOT NULL,
    Role nvarchar(30) NOT NULL CONSTRAINT CK_Users_Role
        CHECK (Role IN (N'Patient', N'GeneralPractitioner', N'Physician', N'Insurer')),
    FirstName nvarchar(50) NOT NULL,
    LastName nvarchar(80) NOT NULL,
    InsurerId int NULL CONSTRAINT FK_Users_Insurers REFERENCES dbo.Insurers(InsurerId),
    PatientId int NULL,
    CONSTRAINT CK_Users_PatientLink CHECK
        ((Role = N'Patient' AND PatientId IS NOT NULL) OR (Role <> N'Patient' AND PatientId IS NULL)),
    CONSTRAINT CK_Users_InsurerLink CHECK
        ((Role = N'Insurer' AND InsurerId IS NOT NULL) OR (Role <> N'Insurer' AND InsurerId IS NULL))
);

CREATE TABLE dbo.Patients (
    PatientId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Patients PRIMARY KEY,
    FirstName nvarchar(50) NOT NULL,
    LastName nvarchar(80) NOT NULL,
    BirthDate date NOT NULL CONSTRAINT CK_Patients_BirthDate CHECK (BirthDate >= '19000101'),
    Address nvarchar(100) NOT NULL,
    PhoneNumber nvarchar(20) NOT NULL,
    Email nvarchar(100) NOT NULL CONSTRAINT CK_Patients_Email CHECK (Email LIKE N'%_@_%._%'),
    GeneralPractitionerId int NOT NULL CONSTRAINT FK_Patients_GeneralPractitioners REFERENCES dbo.Users(UserId),
    InsurerId int NOT NULL CONSTRAINT FK_Patients_Insurers REFERENCES dbo.Insurers(InsurerId)
);

ALTER TABLE dbo.Users ADD CONSTRAINT FK_Users_Patients
    FOREIGN KEY (PatientId) REFERENCES dbo.Patients(PatientId);
CREATE UNIQUE INDEX UX_Users_PatientId ON dbo.Users(PatientId) WHERE PatientId IS NOT NULL;

CREATE TABLE dbo.PhysicianPatients (
    PatientId int NOT NULL CONSTRAINT FK_PhysicianPatients_Patients REFERENCES dbo.Patients(PatientId),
    PhysicianId int NOT NULL CONSTRAINT FK_PhysicianPatients_Users REFERENCES dbo.Users(UserId),
    CONSTRAINT PK_PhysicianPatients PRIMARY KEY (PatientId, PhysicianId)
);

CREATE TABLE dbo.Exercises (
    ExerciseId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Exercises PRIMARY KEY,
    Name nvarchar(100) NOT NULL CONSTRAINT UQ_Exercises_Name UNIQUE,
    Description nvarchar(500) NOT NULL,
    InstructionVideoUrl nvarchar(300) NULL CONSTRAINT CK_Exercises_Url
        CHECK (InstructionVideoUrl IS NULL OR InstructionVideoUrl LIKE N'https://%')
);

CREATE TABLE dbo.ExercisePlans (
    ExercisePlanId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ExercisePlans PRIMARY KEY,
    PatientId int NOT NULL CONSTRAINT FK_ExercisePlans_Patients REFERENCES dbo.Patients(PatientId),
    ExerciseId int NOT NULL CONSTRAINT FK_ExercisePlans_Exercises REFERENCES dbo.Exercises(ExerciseId),
    PhysicianId int NOT NULL,
    StartDate datetime2(0) NOT NULL,
    EndDate datetime2(0) NOT NULL,
    Repetitions smallint NOT NULL CONSTRAINT CK_ExercisePlans_Repetitions CHECK (Repetitions > 0),
    Sets smallint NOT NULL CONSTRAINT CK_ExercisePlans_Sets CHECK (Sets > 0),
    FrequencyPerDay smallint NOT NULL CONSTRAINT CK_ExercisePlans_Frequency CHECK (FrequencyPerDay > 0),
    Remarks nvarchar(200) NULL,
    SysStartTime datetime2(0) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    SysEndTime datetime2(0) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime),
    CONSTRAINT UQ_ExercisePlans_IdPatient UNIQUE (ExercisePlanId, PatientId),
    CONSTRAINT FK_ExercisePlans_PhysicianPatients FOREIGN KEY (PatientId, PhysicianId)
        REFERENCES dbo.PhysicianPatients(PatientId, PhysicianId),
    CONSTRAINT CK_ExercisePlans_Period CHECK (EndDate >= StartDate)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.ExercisePlansHistory));

CREATE TABLE dbo.Appointments (
    AppointmentId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_Appointments PRIMARY KEY,
    PatientId int NOT NULL CONSTRAINT FK_Appointments_Patients REFERENCES dbo.Patients(PatientId),
    PhysicianId int NOT NULL,
    AppointmentAt datetime2(0) NOT NULL,
    DurationMinutes smallint NOT NULL CONSTRAINT CK_Appointments_Duration CHECK (DurationMinutes BETWEEN 5 AND 480),
    Type nvarchar(50) NOT NULL,
    Status nvarchar(30) NOT NULL CONSTRAINT CK_Appointments_Status
        CHECK (Status IN (N'Gepland', N'Bevestigd', N'Afgerond', N'Geannuleerd')),
    SysStartTime datetime2(0) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    SysEndTime datetime2(0) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime),
    CONSTRAINT FK_Appointments_PhysicianPatients FOREIGN KEY (PatientId, PhysicianId)
        REFERENCES dbo.PhysicianPatients(PatientId, PhysicianId)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.AppointmentsHistory));

CREATE TABLE dbo.CompletedExercises (
    CompletedExerciseId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_CompletedExercises PRIMARY KEY,
    PatientId int NOT NULL CONSTRAINT FK_CompletedExercises_Patients REFERENCES dbo.Patients(PatientId),
    ExercisePlanId int NOT NULL,
    CompletedAt datetime2(0) NOT NULL,
    IsChecked bit NOT NULL CONSTRAINT DF_CompletedExercises_IsChecked DEFAULT (1),
    CONSTRAINT UQ_CompletedExercises_PlanTime UNIQUE (ExercisePlanId, CompletedAt),
    CONSTRAINT FK_CompletedExercises_PlanPatient FOREIGN KEY (ExercisePlanId, PatientId)
        REFERENCES dbo.ExercisePlans(ExercisePlanId, PatientId)
);

CREATE TABLE dbo.PainEntries (
    PainEntryId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_PainEntries PRIMARY KEY,
    PatientId int NOT NULL CONSTRAINT FK_PainEntries_Patients REFERENCES dbo.Patients(PatientId),
    RecordedAt datetime2(0) NOT NULL CONSTRAINT DF_PainEntries_RecordedAt DEFAULT (SYSDATETIME()),
    PainScore tinyint NOT NULL CONSTRAINT CK_PainEntries_Score CHECK (PainScore BETWEEN 0 AND 10),
    Notes nvarchar(500) NULL
);

CREATE TABLE dbo.ActivityLogEntries (
    ActivityLogEntryId int IDENTITY(1,1) NOT NULL CONSTRAINT PK_ActivityLogEntries PRIMARY KEY,
    PatientId int NOT NULL CONSTRAINT FK_ActivityLogEntries_Patients REFERENCES dbo.Patients(PatientId),
    UserId int NULL CONSTRAINT FK_ActivityLogEntries_Users REFERENCES dbo.Users(UserId),
    ActivityAt datetime2(0) NOT NULL,
    Description nvarchar(500) NOT NULL
);

CREATE TABLE dbo.AuditLogs (
    AuditLogId bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_AuditLogs PRIMARY KEY,
    PatientId int NOT NULL,
    ActorUserId int NULL,
    EventType nvarchar(50) NOT NULL,
    EventAt datetime2(0) NOT NULL CONSTRAINT DF_AuditLogs_EventAt DEFAULT (SYSDATETIME())
);
GO
