# RevaliNow — technisch ontwerp

## Architectuur

```text
Vue 3 / Pinia / Vue Router (localhost:5173)
  -> REST + JWT Bearer
ASP.NET Core API (localhost:5080)
  -> Controller -> service/repository -> Dapper
SQL Server 2022 (Docker, localhost:1433)
```

The Vue app contains only presentation and client-side form validation. The API authenticates patients, issues short-lived JWTs, validates requests, and opens an individual SQL connection for each repository operation. Before querying, it sets `UserId`, `PatientId`, and `Role` through `sp_set_session_context`; the SQL Server RLS policy filters patient records. Write operations use stored procedures. Database credentials and the JWT key are supplied through .NET user-secrets or environment variables, never source control.

## Data model

`Users` contains patient and staff identities. `Patients` links to their general practitioner and insurer. `ExercisePlans` joins patients, exercises and prescribing physicians. Appointments, completed exercises, pain entries and activity logs are patient-owned. Exercise plans and appointments are system-versioned temporal tables. A separate `PhysicianPatients` join table records which physician may access which patient. `AuditLogs` records pain-entry and exercise-completion events.

The seeder imports the nine in-scope data worksheets and the physician/patient relationship worksheet. It preserves workbook IDs, creates `patient<ID>` accounts with BCrypt password hashes, and marks employee logins disabled because no usable employee credentials are supplied. Input data is not checked into Git.

## Security and data integrity

- JWT authorization is limited to the `Patient` API role.
- SQL RLS allows patients to see only their own patient rows and assigned physicians to see rows for their assigned patients.
- API database access must use the non-sysadmin `revalinow_app_login`; `sa` bypasses SQL RLS.
- Foreign keys, uniqueness constraints, check constraints, temporal history and operation audit triggers are defined in SQL scripts `01`–`05`.
- Query parameters are passed through Dapper; SQL is not composed from user input.
- Pain entries are bounded to scores from 0 to 10. Exercise completion verifies current patient ownership, active plan dates and configured daily frequency.
- The application is a school/demo project, not a certified medical record system. Use only the provided test workbook and do not put real patient data in screenshots or Git.

## API surface

| Method | Route | Purpose |
|---|---|---|
| POST | `/api/auth/login` | Authenticate a patient and return a JWT |
| GET | `/api/patient/dashboard` | Patient-specific summary |
| GET | `/api/patient/plans` | Active exercise plans and today's completion state |
| POST | `/api/patient/plans/{id}/complete` | Record a completion, subject to the daily limit |
| GET | `/api/patient/appointments` | Patient's appointments |
| GET | `/api/patient/pain-entries` | Recent pain history |
| POST | `/api/patient/pain-entries` | Record a score and optional note |

## User experience and accessibility

The interface uses a responsive sidebar, clear Dutch labels, visible loading and error states, keyboard-operable controls, a button-based pain scale with accessible names, and semantic page regions. Pain trends use a labelled 0–10 chart. The app does not fabricate data when the API cannot be reached.

## Manual usability-test checklist

1. Sign in as `patient3`; confirm the overview loads without a console error.
2. Check the exercise list and confirm exercise completion appears after refresh.
3. Submit a pain score, verify it appears in history, and try submitting without selecting a score.
4. Check upcoming and previous appointments at both desktop and phone widths.
5. Try an invalid login and a disconnected API; errors should be clear and no success state should appear.
6. With two test accounts, confirm patient 3 cannot retrieve patient 6 data by changing a URL or request body.
7. Keyboard through the login form, navigation, pain scale and save button; inspect focus and contrast with axe/Lighthouse.

Capture screenshots only with synthetic/test data; store deliverable screenshots locally under `docs/screenshots/` (ignored by Git).
