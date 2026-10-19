# RevaliNow

RevaliNow is a Dutch-language rehabilitation portal built from a Vue 3 web app, an ASP.NET Core API and a SQL Server database. The API uses Dapper, JWT bearer authentication and patient-scoped SQL Server Row-Level Security (RLS).

## What is included

- Patient login, daily overview, exercise plans, marking exercises complete, pain-score history and appointments.
- SQL Server schema with relational constraints, checks, temporal history, audit triggers, views, stored procedures, indexes and RLS.
- Excel seeder for the nine RevaliNow data sheets plus the `Revalidatieartsen` patient/physician relationship sheet needed for RLS.
- xUnit tests for patient login and Vitest tests for dashboard summary behavior.

## Start the database

1. Install Docker Desktop and start it.
2. Copy `database/.env.example` to `database/.env` and set a unique strong `SA_PASSWORD` (at least eight characters including uppercase, lowercase, a number and a symbol).
3. In PowerShell, from the repository root, run:

   ```powershell
   docker compose --env-file database\.env -f database\docker-compose.yml up -d
   ```

   Wait until `docker ps` reports the container as healthy.
4. Connect with SSMS or the VS Code MSSQL extension at `localhost,1433`, SQL login `sa`, and the password you set.
5. Run the SQL files in order, once each: `database\01_create_schema.sql` through `database\05_permissions.sql`.
6. Create a SQL Server login using a secret you do not commit, and map it to the pre-created, least-privilege database user:

   ```sql
   CREATE LOGIN [revalinow_app_login] WITH PASSWORD = N'<your-private-strong-password>', CHECK_POLICY = ON;
   USE RevaliNowDb;
   ALTER USER [revalinow_app] WITH LOGIN = [revalinow_app_login];
   ```

   Use this application login, **not** `sa`, for the API. A sysadmin login bypasses RLS. The one-time seeder needs bulk-insert permissions, so use the `sa` connection only for that import, then stop using it.

The Docker data volume is persistent. `docker compose ... down -v` permanently deletes that database volume; do not run it unless you intend to erase the database.

## Load the school workbook

The source workbook is intentionally not committed because it contains patient data. Keep the original `Eindopdracht-data-v3.xlsx` outside the repository. The importer expects the Dutch sheet and column names in that workbook.

Set the seeder connection string in the current PowerShell session, then run:

```powershell
$env:ConnectionStrings__Seeder = "Server=localhost,1433;Database=RevaliNowDb;User Id=sa;Password=<private-sa-password>;Encrypt=True;TrustServerCertificate=True"
dotnet run --project backend\RevaliNow.Seeder -- "C:\path\to\Eindopdracht-data-v3.xlsx"
```

The import runs in one transaction, preserves source IDs, validates the data against SQL constraints, and refuses to import into a database that already contains data. It loads patient-provider relationships from `Revalidatieartsen` as supporting RLS data. Patient demo accounts are `patient<ID>` with password `Welkom123!`; employee accounts are disabled because the workbook has no known employee passwords.

## Run the API

Install the .NET 10 SDK (or target the .NET version selected by your school). From PowerShell:

```powershell
cd backend\RevaliNow.Api
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:Default" "Server=localhost,1433;Database=RevaliNowDb;User Id=revalinow_app_login;Password=<private-app-password>;Encrypt=True;TrustServerCertificate=True"
dotnet user-secrets set "Jwt:Key" "<a random secret of at least 32 bytes>"
dotnet run --urls http://localhost:5080
```

The interactive API documentation is at `http://localhost:5080/swagger`; liveness is at `/health`. The API sets the authenticated `UserId`, `PatientId`, and role in SQL `SESSION_CONTEXT` whenever it opens a database connection. Do not run the API as `sa`.

## Run the website

Install Node.js 22 or newer, then from the repository root:

```powershell
Copy-Item .env.example .env.local
npm ci
npm run dev
```

Open `http://localhost:5173`. The web app calls the API at `http://localhost:5080` by default. Override it with `VITE_API_URL` in `.env.local` if needed.

## Test and build

```powershell
npm test
npm run build
dotnet test backend\RevaliNow.sln
dotnet build backend\RevaliNow.sln
```

For a frontend container, run `docker build -t revalinow-web .` and `docker run --rm -p 8080:80 revalinow-web`. Configure `VITE_API_URL` at build time if the API is not at its default address.

## Data scope and privacy

Only the rehabilitation module is imported: insurers, users, patients, exercises, plans, completed exercises, pain entries, activity logs, and appointments. Other workbook modules (such as medication and claims) are intentionally excluded. `Revalidatieartsen` is loaded only as the patient-to-physician access relationship used by RLS. Never add the original workbook, connection strings, signing keys, or screenshots containing patient information to Git.
