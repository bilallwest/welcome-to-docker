SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
USE RevaliNowDb;
GO
IF DATABASE_PRINCIPAL_ID(N'revalinow_app_role') IS NULL
    CREATE ROLE revalinow_app_role;
GO
IF DATABASE_PRINCIPAL_ID(N'revalinow_app') IS NULL
    CREATE USER revalinow_app WITHOUT LOGIN;
GO
ALTER ROLE revalinow_app_role ADD MEMBER revalinow_app;
GRANT EXECUTE ON dbo.usp_FindUserForLogin TO revalinow_app_role;
GRANT SELECT ON dbo.vw_PatientExercisePlans TO revalinow_app_role;
GRANT SELECT ON dbo.vw_PatientAppointments TO revalinow_app_role;
GRANT SELECT ON dbo.PainEntries TO revalinow_app_role;
GRANT EXECUTE ON dbo.usp_CompleteExercise TO revalinow_app_role;
GRANT EXECUTE ON dbo.usp_RecordPainEntry TO revalinow_app_role;
GO
