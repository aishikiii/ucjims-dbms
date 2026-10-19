# UCJIMS — Stage 4 Testing and Hardening Runbook

This document details the test infrastructure, negative authorization verification, database constraint testing, and error sanitization implemented for Stage 4 of the Unified Criminal Justice Information Management System (UCJIMS).

---

## 1. Scope and Objectives

Stage 4 transitions UCJIMS from a database prototype with basic API endpoints into a hardened, tested system. The objectives achieved include:

1. **Automated Backend & RBAC Unit/Integration Testing**: Automated verification of authentication, token verification, input validation, and role-based permissions.
2. **Negative Authorization Matrix for Every Role**: Verification that non-permitted roles receive HTTP 403 Forbidden even when making direct API calls, enforcing a server-side deny-by-default policy.
3. **Database Integrity and Negative Workflow Testing**: PL/SQL test suite (`database/15_stage4_db_tests.sql`) asserting constraints, triggers, role guards, and stored procedures in Oracle.
4. **Data Masking and Error Sanitization**: Complete prevention of stack trace and raw SQL leakage to HTTP clients via `utils/dbError.js`.
5. **Continuous Integration (CI)**: Automated GitHub Actions pipeline (`.github/workflows/ci.yml`) executing static linting, test suites, frontend builds, and secret scanning on pull requests and pushes.

---

## 2. Automated Backend Test Suite (`npm test`)

The backend test suite is built on Node.js's native test runner (`node:test` and `node:assert/strict`), providing sub-second test execution with zero external test framework overhead.

### Running the Tests Locally

```bash
cd ucjims-app/ucjims-app/backend
npm test
```

### Test Suite Structure

| Test File | Test Count | Scope |
|---|---:|---|
| `tests/auth.test.js` | 5 | Bearer token parsing, expired token rejection, tampered signatures, missing headers, valid payload mapping. |
| `tests/dbError.test.js` | 7 | ORA-20000..20999 mapping to HTTP 404/409, ORA-00001 (409), ORA-02291/02290/01400 (400), generic error masking (500) preventing SQL/stack leaks. |
| `tests/rbac.test.js` | 9 | Complete RBAC matrix across all 7 roles against every domain operation (cases, evidence, court, inmates, admin). |
| `tests/validation.test.js` | 8 | Input validation for missing mandatory fields on login, case registration, hearing creation, judgment recording, inmate admission/transfer/release. |
| **Total** | **29** | **All 29 tests pass with 0 failures.** |

---

## 3. Role-Based Access Control (RBAC) Matrix

The table below documents the verified server-side permission rules. Every endpoint enforces permissions in middleware (`requireRole`); hiding UI elements in React is treated strictly as an ergonomic aid, not a security boundary.

| Endpoint / Operation | Admin | Investigator | Cyber Crime Analyst | Forensic Officer | Judge | Prosecutor | Prison Officer |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `POST /api/auth/login` | Permitted | Permitted | Permitted | Permitted | Permitted | Permitted | Permitted |
| `GET /api/auth/me` | Permitted | Permitted | Permitted | Permitted | Permitted | Permitted | Permitted |
| `GET /api/cases` | Permitted | Permitted | Permitted | **403** | Permitted | Permitted | **403** |
| `POST /api/cases` | Permitted | Permitted | **403** | **403** | **403** | **403** | **403** |
| `GET /api/evidence` | Permitted | Permitted | Permitted | Permitted | Permitted | Permitted | **403** |
| `POST /api/evidence/:id/transfer` | Permitted | **403** | **403** | Permitted | **403** | **403** | **403** |
| `GET /api/court/hearings` | Permitted | Permitted | **403** | **403** | Permitted | Permitted | **403** |
| `POST /api/court/hearings` | Permitted | **403** | **403** | **403** | Permitted | **403** | **403** |
| `GET /api/court/judgments` | Permitted | **403** | **403** | **403** | Permitted | Permitted | **403** |
| `POST /api/court/judgments` | Permitted | **403** | **403** | **403** | Permitted | **403** | **403** |
| `GET /api/court/inmates` | Permitted | **403** | **403** | **403** | **403** | **403** | Permitted |
| `POST /api/court/inmates` | Permitted | **403** | **403** | **403** | **403** | **403** | Permitted |
| `POST /api/court/inmates/:id/transfer`| Permitted | **403** | **403** | **403** | **403** | **403** | Permitted |
| `PATCH /api/court/inmates/:id/release`| Permitted | **403** | **403** | **403** | **403** | **403** | Permitted |

---

## 4. Oracle Database Negative Test Suite (`15_stage4_db_tests.sql`)

File location: `database/15_stage4_db_tests.sql`

### How to Run in Oracle SQL Developer:
1. Connect to the test schema (built via `database/run_fresh_setup.sql`).
2. Open `database/15_stage4_db_tests.sql` and press **F5 (Run Script)**.
3. Open **View > DBMS Output**, add the active connection, and view the test results.
4. **Safety Guarantee**: Every test executes within a `SAVEPOINT` that is immediately rolled back; the entire script finishes with `ROLLBACK`. No test rows are committed.

### Test Categories Checked by the Script:
1. **Object Health**: Queries `USER_OBJECTS`, `USER_ERRORS`, `USER_CONSTRAINTS`, `USER_TRIGGERS` to ensure 0 invalid objects.
2. **Section A (Constraints & Uniqueness)**:
   - A1: Rejection of hearing referencing nonexistent case (ORA-02291).
   - A2: Rejection of invalid hearing status (ORA-02290).
   - A3: Rejection of invalid evidence type (ORA-02290).
   - A4: Rejection of invalid inmate status (ORA-02290).
   - A5/A6: Duplicate case number and FIR number rejection (ORA-00001).
   - A7: Rejection of prison transfer to same prison (ORA-02290).
   - A8: Rejection of sentence ending before it starts (ORA-02290).
   - A9: Rejection of raw `UPDATE INMATE SET status='RELEASED'` without an actual release date (ORA-02290).
3. **Section B (Append-Only History Protection)**:
   - B1/B2: Rejection of UPDATE or DELETE on `CHAIN_OF_CUSTODY` (ORA-20031).
   - B3/B4: Rejection of UPDATE or DELETE on `EVIDENCE_AUDIT` (ORA-20032).
4. **Section C (Role Guard Triggers)**:
   - C1/C2: Rejection of hearing assigned to non-judge or NULL judge (ORA-20092/20093).
   - C3: Rejection of forensic report authored by non-forensic user (ORA-20090).
   - C4: Rejection of case investigator who is a judge (ORA-20094).
   - C5: Rejection of hearing participant who is not in the case (ORA-20096).
5. **Section D (Judgment & Sentence Rules)**:
   - D1: Rejection of judgment on non-completed hearing (ORA-20081).
   - D2: Rejection of judgment whose hearing belongs to another case (ORA-20080).
   - D3: Rejection of judgment date mismatch with completed hearing date (ORA-20082).
   - D4: Rejection of sentence applied to person who is not the accused (ORA-20098).
6. **Section E (Stored Procedure Guard Checks)**:
   - E1-E3: `RELEASE_INMATE` validation on missing, already released, or premature release dates.
   - E4-E6: `TRANSFER_INMATE` validation on same prison, released inmate, or missing destination.
   - E7-E9: `TRANSFER_EVIDENCE` validation on missing evidence, future timestamp, or empty purpose.
7. **Section F (Positive Workflow Consistency)**:
   - F1: Atomic execution of `TRANSFER_EVIDENCE` (1 custody row + 1 audit row + updated status).
   - F2: Atomic execution of `RELEASE_INMATE` (sets `status='RELEASED'` and `actual_release_date`).
   - F3: Atomic execution of `TRANSFER_INMATE` (updates `INMATE.prison_id` and logs to `PRISON_TRANSFER`).
   - F4: Agreement between `GET_PRISON_OCCUPANCY` and physical row counts for all prisons.

---

## 5. Error Sanitization & Data Masking Architecture

To protect sensitive criminal justice data and internal schema layouts, `utils/dbError.js` wraps all database error handling:

1. **Custom Application Errors (ORA-20000 to ORA-20999)**:
   - Extracted and cleaned: strips Oracle prefixes (`ORA-20066:`), stack traces (`ORA-06512:`), and returns standard JSON:
     ```json
     {
       "error": "Custody events must be strictly chronological",
       "code": "ORA-20066"
     }
     ```
   - Errors containing `"not found"` map to HTTP 404; other business rule violations map to HTTP 409 Conflict.
2. **Relational Violations**:
   - Unique constraints (`ORA-00001`) return HTTP 409 with `"Duplicate value"`.
   - Foreign key violations (`ORA-02291`) return HTTP 400 with `"Referenced record does not exist"`.
   - Check constraints (`ORA-02290`) and NOT NULL checks (`ORA-01400`) return HTTP 400 with `"Invalid or missing value"`.
3. **Internal & Unhandled Errors**:
   - Logged to server console only.
   - HTTP response body receives only the generic fallback message (e.g. `{"error": "Failed to register case"}`) with HTTP 500. Stack traces, raw table names, and SQL statements are never sent across HTTP.

---

## 6. Continuous Integration (CI) Workflow

The automated CI pipeline is defined in `.github/workflows/ci.yml`. It runs on pushes and pull requests across `main`, `stage-0-1`, and `stage-4-5` branches:

- **Job 1: Database Static Lint**: Executes `python static_lint.py` to assert dataset arity, date ordering, foreign key consistency, and trigger definitions.
- **Job 2: Backend Test Suite**: Installs dependencies and runs all 29 automated tests via `npm test`.
- **Job 3: Frontend Build**: Runs `npm run build` using Vite to verify bundling, module imports, and JSX compilation.
- **Job 4: Security Scan**: Inspects repository for committed private keys, certificates, or unmasked credentials.
