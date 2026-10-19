# Unified Criminal Justice Information Management System (UCJIMS)

UCJIMS is an enterprise-grade role-based system designed to coordinate information flow across police investigation, forensic analysis, judicial proceedings, and correctional facilities.

This repository provides an end-to-end implementation transitioning from an initial Oracle database prototype to a hardened, tested, containerized role-based application.

---

## Repository Structure

```
ucjims-dbms/
├── .github/
│   └── workflows/ci.yml         # Automated GitHub Actions CI pipeline (lint, tests, build)
├── database/                    # Oracle SQL scripts (Stage 0 to Stage 5)
│   ├── 01_tables_personA.sql    # Core identity, case, and FIR schema
│   ├── 02_sample_data_personA.sql # Person A synthetic seed data
│   ├── 02_tables_personB.sql    # Evidence and forensics schema
│   ├── 03_sample_data_personB.sql # Base evidence seed data
│   ├── 03a_additional_sample_data_personB.sql # Expanded synthetic evidence records
│   ├── 04_triggers_personB.sql  # Audit triggers and sequence
│   ├── 06_tables_personC.sql    # Court, hearings, sentences, and prison schema
│   ├── 07_sample_data_personC.sql # Court and corrections seed data
│   ├── 09_integration_demo_personC.sql # Cross-domain integration data
│   ├── 10_stage1_hardening.sql  # Constraints, BNS alignment, and role guards
│   ├── 11_stage1_sequences.sql  # Sequence generation for application inserts
│   ├── 12_stage1_workflows.sql  # Hardened stored procedures (TRANSFER_EVIDENCE, etc.)
│   ├── 13_golden_case_fixture.sql # End-to-end golden case fixture
│   ├── 14_stage1_validation.sql # Database acceptance validation gate
│   ├── 15_stage4_db_tests.sql   # Stage 4 database negative & workflow test suite
│   ├── 16_stage5_app_user.sql   # Stage 5 least-privilege DB user provisioning
│   └── run_fresh_setup.sql      # Master runner for fresh schema initialization
├── docs/                        # Architecture and operational documentation
│   ├── STAGE0_BASELINE_RUNBOOK.md
│   ├── STAGE0_STATIC_AUDIT.md
│   ├── STAGE4_TESTING_AND_HARDENING.md   # Stage 4 test runbook & RBAC matrix
│   ├── STAGE5_DEPLOYMENT_OPERATIONS.md   # Stage 5 deployment, least-privilege & runbooks
│   └── personA_documentation.md
├── ucjims-app/ucjims-app/       # Application layer
│   ├── backend/                 # Express.js REST API with Oracle connection pool
│   │   ├── config/              # Oracle connection pool & schema switching
│   │   ├── middleware/          # JWT authentication and deny-by-default RBAC
│   │   ├── routes/              # Auth, cases, evidence, and court/inmate endpoints
│   │   ├── scripts/             # Demo user password seeding script
│   │   ├── tests/               # Stage 4 automated test suite (29 tests)
│   │   └── utils/               # Centralized Oracle error sanitizer
│   ├── frontend/                # React (Vite) responsive UI
│   │   └── src/                 # Role-gated panels, forms, and API client
│   ├── nginx/                   # Stage 5 production reverse proxy configuration
│   └── docker-compose.yml       # Stage 5 containerized stack orchestration
└── static_lint.py               # Static dataset and constraint validator
```

---

## Roadmap Milestones

- [x] **Stage 0: Baseline & Static Audit** (Repeatable SQL schema, synthetic datasets).
- [x] **Stage 1: Hardening & Sequences** (Referential integrity, append-only triggers, stored procedures, golden case fixture).
- [x] **Stage 2: Backend API** (Express REST API, JWT auth, parameterized queries).
- [x] **Stage 3: Role-Specific UI** (React frontend with role-gated dashboards and write workflows).
- [x] **Stage 4: Testing & Hardening** (29 automated unit/integration tests, negative RBAC matrix, PL/SQL negative tests, error masking).
- [x] **Stage 5: Deployment & Operations** (Least-privilege database user `UCJIMS_APP`, multi-environment configs, Docker Compose, Nginx reverse proxy with rate limiting, CI/CD pipeline, and backup runbook).

---

## Quickstart Guide

### Prerequisites
- Node.js 18+ (tested on Node 20 / 24)
- Python 3.10+
- Oracle Database 19c / 21c / 23ai (or Oracle XE)

### 1. Database Initialization (Stage 0 & 1)
1. Open Oracle SQL Developer connected to a clean, disposable development schema.
2. Open `database/run_fresh_setup.sql` and run as script (**F5**).
3. Verify that the output concludes with:
   - `STAGE 0 PASS`
   - `GOLDEN-CASE-0001 passed`
   - `Stage 1 acceptance passed`
4. Run the static checker from the repository root:
   ```bash
   python static_lint.py
   ```

### 2. Backend Setup & Demo User Seeding
```bash
cd ucjims-app/ucjims-app/backend
npm install
cp .env.example .env
# Edit .env with your Oracle connection credentials
```

Seed working demo passwords (one account per role):
```bash
npm run seed-demo-users
```
*(This updates demo user password hashes and outputs credentials to `demo_credentials.txt`)*

Start the development API server:
```bash
npm start
```
Verify the health check:
```bash
curl http://localhost:4000/api/health
```

### 3. Frontend Setup
In a second terminal:
```bash
cd ucjims-app/ucjims-app/frontend
npm install
npm run dev
```
Open `http://localhost:5173` in your browser and log in with one of the generated role credentials.

---

## Stage 4: Testing & Negative Authorization

### 1. Automated Backend & RBAC Tests
Run the 29-test automated test suite:
```bash
cd ucjims-app/ucjims-app/backend
npm test
```
This tests:
- Bearer token authentication and expired/tampered token rejection.
- Server-side deny-by-default RBAC across all 7 roles.
- Zero-leakage database error sanitization (ORA-20000..20999 mapping to clean JSON).
- Request parameter validation across all write endpoints.

### 2. Database Negative & Workflow Tests
In Oracle SQL Developer, run `database/15_stage4_db_tests.sql` using **F5**.
All tests run inside individual `SAVEPOINT`s and finish with `ROLLBACK`.

Detailed documentation: [STAGE4_TESTING_AND_HARDENING.md](file:///c:/Users/archi/dbms-project/ucjims-dbms/docs/STAGE4_TESTING_AND_HARDENING.md)

---

## Stage 5: Production Deployment & Security

### 1. Provisioning Least-Privilege Database Account
Run `database/16_stage5_app_user.sql` in Oracle to create `UCJIMS_APP`. The application user cannot drop tables, owns zero objects, and only executes permitted procedures.

Set `ORACLE_USER=UCJIMS_APP` and `ORACLE_SCHEMA=UCJIMS_OWNER` in your production environment.

### 2. Containerized Deployment
```bash
cd ucjims-app/ucjims-app
docker compose up -d --build
```
This boots:
- `backend`: Express API running as non-root user `node` on port 4000.
- `frontend`: Optimized Vite production build.
- `proxy`: Hardened Nginx reverse proxy on port 80/443 with TLS, rate-limiting (login brute-force protection), CSP, and HSTS headers.

Detailed documentation: [STAGE5_DEPLOYMENT_OPERATIONS.md](file:///c:/Users/archi/dbms-project/ucjims-dbms/docs/STAGE5_DEPLOYMENT_OPERATIONS.md)

---

## Verified Role Permissions

| Role | Permitted Capabilities | Denied Capabilities |
|---|---|---|
| **Admin** | Full system administration, user management, audit review. | Cannot bypass append-only triggers. |
| **Investigator** | Register FIR/cases, view cases, view evidence, view hearings. | Cannot record judgments, custody transfers, or release inmates. |
| **Cyber Crime Analyst** | View assigned cases and digital evidence. | Cannot schedule hearings, transfer custody, or record judgments. |
| **Forensic Officer** | View evidence, custody history, record custody transfers. | Cannot view cases, schedule hearings, or manage inmates. |
| **Judge** | View cases, court hearings, schedule hearings, record judgments. | Cannot register cases, transfer custody, or manage inmates. |
| **Prosecutor** | View cases, view evidence, view hearings, view judgments. | Cannot register cases, schedule hearings, or manage inmates. |
| **Prison Officer** | View inmates, admit inmates, transfer inmates, release inmates. | Cannot view cases, evidence, hearings, or judgments. |

---

## License & Synthetic Data Notice
All data in this repository is synthetic and designed for academic demonstration and testing.
