# UCJIMS — Stage 2 & 3 (Backend API + Frontend)

This is a working **prototype**, scoped to prove the Oracle schema (Stage 0/1,
already done) works end-to-end through a real login + role-based dashboard —
not the full production hardening (CI/CD, deployment, monitoring) described
in later roadmap stages.

## What's here

```
ucjims-app/
├── backend/     Express + Oracle API: login (JWT), case/evidence/court endpoints, RBAC
└── frontend/    React (Vite) app: login page + role-specific dashboard
```

## Prerequisites

- Node.js 18+
- Your Oracle database already set up with the schema from `database/01_tables_personA.sql`
  through `09_integration_demo_personC.sql` (Jiya's Stage 0/1 work)
- Oracle Instant Client reachable on your machine (same one SQL*Plus already uses)

## 1. Backend setup

```bash
cd backend
npm install
cp .env.example .env
```

Edit `.env` with your real Oracle credentials (same ones you use in SQL*Plus):

```
ORACLE_USER=your_username
ORACLE_PASSWORD=your_password
ORACLE_CONNECT_STRING=localhost:1521/XEPDB1
JWT_SECRET=<pick any long random string>
```

Then seed working demo passwords (the seed data's `hash_pw_001` strings are
placeholders, not real password hashes — this script fixes that for one user
per role):

```bash
npm run seed-demo-users
```

This prints a list of usernames (one per role) — the password for all of them
is `Demo@1234`. Use these to log in.

Start the API:

```bash
npm start
```

It should print `UCJIMS API listening on port 4000`. Test it:

```bash
curl http://localhost:4000/api/health
```

## 2. Frontend setup

In a second terminal:

```bash
cd frontend
npm install
npm run dev
```

Open http://localhost:5173 — you'll land on the login page. Log in with one
of the usernames from step 1 and password `Demo@1234`.

## What each role sees

| Role | Dashboard panels |
|---|---|
| Investigator | Cases, Evidence, Court |
| Cyber Crime Analyst | Cases, Evidence |
| Forensic Officer | Evidence |
| Judge | Court (hearings + judgments) |
| Prosecutor | Court (hearings + judgments) |
| Prison Officer | Inmates |
| Admin | Everything |

This mirrors the `*_VIEW`s from `database/10_role_based_views.sql` — the API
enforces who can call which endpoint (`middleware/auth.js`'s `requireRole`),
and the frontend just hides panels a role can't use so the two layers agree.

## API endpoints (so far)

| Method | Path | Who | What |
|---|---|---|---|
| POST | /api/auth/login | anyone | returns a JWT |
| GET | /api/cases | Investigator/Admin/Judge/Prosecutor/Cyber Crime Analyst | list cases |
| GET | /api/cases/:id | same | full case summary |
| POST | /api/cases | Investigator/Admin | register case + FIR |
| GET | /api/evidence | Forensic/Investigator/Admin/Judge/Prosecutor | list evidence |
| GET | /api/evidence/:id/custody | same | chain of custody |
| POST | /api/evidence/:id/transfer | Forensic/Admin | record a custody transfer |
| GET | /api/court/hearings | Judge/Prosecutor/Admin/Investigator | list hearings |
| GET | /api/court/judgments | Judge/Prosecutor/Admin | list judgments |
| GET | /api/court/inmates | Prison Officer/Admin | list inmates |

## What's deliberately out of scope for this prototype

Per the roadmap's own Stage 2–5 split, these are NOT built here — call them
out as "future work" in your presentation if asked:

- CI/CD pipeline, staging environment, deployment/HTTPS config
- Full test suite (unit/integration/E2E)
- Password reset flow, account lockout, CSRF protection
- Full CRUD for every entity (only a representative slice is wired up —
  case registration, evidence transfer; the rest are read-only lists)
- Audit log viewer for Admin (the DB trigger from Person B writes the audit
  rows already; there's just no screen to browse them yet)

## Next steps if you have more time

1. Wire up the remaining write endpoints (add person to case, schedule
   hearing, record judgment/sentence, admit/release inmate)
2. Add a case detail page (click a row → full CASE_SUMMARY_VIEW detail)
3. Add the Admin user-management screen
4. Swap the shared demo password for per-user passwords before any real demo
