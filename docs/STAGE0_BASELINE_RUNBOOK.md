# UCJIMS — Stage 0 Baseline Runbook

Repository branch: https://github.com/aishikiii/ucjims-dbms/tree/stage-0-1

## Goal and scope

Stage 0 establishes a repeatable Oracle baseline, adds a larger deterministic synthetic Person B dataset, and supplies read-only validation checks. The SQL has been statically reviewed and the new dataset has been checked for IDs, references, status values, and date order. It has **not** been executed on a live Oracle instance from this work session; that final runtime check must be done in Oracle SQL Developer.

## Before you start

- Use a **disposable development schema**. Do not run this setup against production or a shared schema.
- Connect to the intended schema in Oracle SQL Developer. Confirm the connection name before executing scripts.
- Use **Run Script (F5)** for each full file, especially files containing PL/SQL code terminated by `/`.
- Run each insert/data file only once on a clean schema. Fixed sample IDs mean a rerun produces duplicate-key errors and may leave a partially loaded dataset.
- Save the Script Output to a local text file for evidence. Never include passwords, tokens, or connection secrets in the log.

## Fresh-schema run order

1. `database/01_tables_personA.sql` — core tables.
2. `database/02_sample_data_personA.sql` — roles, users, people, cases and investigation records.
3. `database/03_queries_personA.sql` — Person A queries and `CASE_SUMMARY_VIEW`.
4. `database/02_tables_personB.sql` — evidence, custody and report tables.
5. `database/04_triggers_personB.sql` — audit table, sequence and custody insert trigger.
6. `database/03_sample_data_personB.sql` — baseline Person B rows.
7. `database/06_tables_personC.sql` — court and corrections tables.
8. `database/07_sample_data_personC.sql` — court/prison demo data.
9. `database/09_integration_demo_personC.sql` — cross-module evidence, custody and forensic records (and integration query).
10. `database/03a_additional_sample_data_personB.sql` — 30 more evidence rows, 30 custody rows and 24 forensic reports.
11. `database/05_queries_personB.sql` — Person B query set.
12. `database/08_queries_personC.sql` — Person C queries, function, procedure and view.
13. `database/stage0_database_validation.sql` — read-only validation.

Check the Script Output after every file. Do not proceed through a failed DDL or insert script without noting and resolving the error. The integration demo includes a result query after `COMMIT`; that query output is expected.

## Dataset added for Person B

`database/03a_additional_sample_data_personB.sql` contains 84 inserts: **30 `EVIDENCE`** rows (IDs 7–36), **30 `CHAIN_OF_CUSTODY`** rows (IDs 7–36), and **24 `FORENSIC_REPORT`** rows (IDs 6–29 covering evidence IDs 7–30). All new dates are historical synthetic dates, forensic examinations occur on/after the associated collection date, custody records reference the evidence rows, and custody sender/receiver IDs differ. Forensic officer IDs in the new records use the seeded Forensic Officer accounts (users 8–10).

Expected counts after the full run on a fresh schema:

| Table | Expected rows | Basis |
|---|---:|---|
| `ROLE` | 7 | Person A seed data |
| `DEPARTMENT` | 5 | Person A seed data |
| `APP_USER` | 15 | Person A seed data |
| `PERSON` | 40 | Person A seed data |
| `CASE_TABLE` | 15 | Person A seed data |
| `FIR` | 15 | Person A seed data |
| `CASE_PERSON` | 47 | Person A seed data |
| `INVESTIGATION` | 15 | Person A seed data |
| `CASE_INVESTIGATOR` | 17 | Person A seed data |
| `EVIDENCE` | 36 | 3 base + 3 integration + 30 added |
| `CHAIN_OF_CUSTODY` | 36 | 3 base + 3 integration + 30 added |
| `FORENSIC_REPORT` | 29 | 2 base + 3 integration + 24 added |
| `EVIDENCE_AUDIT` | 36 | One trigger row for each custody insert, if trigger is valid |
| `COURT` | 4 | Person C seed data |
| `HEARING` | 15 | Person C seed data |
| `HEARING_PARTICIPANT` | 24 | Person C seed data |
| `JUDGMENT` | 3 | Person C seed data |
| `LEGAL_PROVISION` | 8 | Person C seed data |
| `CASE_PROVISION` | 8 | Person C seed data |
| `SENTENCE` | 3 | Person C seed data |
| `PRISON` | 3 | Person C seed data |
| `INMATE` | 2 | Person C seed data |
| `PRISON_TRANSFER` | 2 | Person C seed data |

There are **23 application tables** in the current schema inventory. The additional data and expected counts are synthetic test fixtures, not evidence about real cases.

## Validation and evidence to capture

Run `database/stage0_database_validation.sql`. Check the following:

1. The table inventory query returns all 23 expected table names.
2. Row counts match the table above. In particular, Person B totals are 36 evidence, 36 custody, 29 reports, and 36 audit rows on a clean run.
3. Every orphan-reference query returns zero rows.
4. The audit coverage checks return zero rows; investigate any missing, orphaned or duplicated audit trail before accepting the baseline.
5. Review all data-quality queries and record any exceptions. The current transfer model records history but has no database logic to update `INMATE.prison_id`; seeded current-prison values are expected to match each inmate's latest transfer.
6. `CASE_SUMMARY_VIEW`, `TRG_CUSTODY_AUDIT`, `EVIDENCE_AUDIT_SEQ`, `GET_PRISON_OCCUPANCY`, `RELEASE_INMATE`, and `V_CASE_COURT_SUMMARY` show valid status, and `USER_ERRORS` contains no relevant compiler errors.
7. In a disposable schema only, smoke-test the custody audit trigger by inserting one temporary custody row with a unique ID, verifying exactly one matching audit row, then rolling back. Use valid evidence and distinct sender/receiver users.
8. Record the Oracle Database version, Oracle SQL Developer version, schema alias, the final counts, and where the Script Output log is stored. Do not capture passwords or secrets.

## Static review results (before live Oracle run)

- New Person B dataset: 30 evidence + 30 custody + 24 report rows; 84 inserts.
- New row IDs are distinct from tracked base and integration-demo IDs.
- Every new custody row references its matching evidence ID and uses distinct sender/receiver users.
- Each new report references a new evidence ID (7–30), has a non-null synthetic Forensic Officer ID (8–10), and has an examination date on/after collection.
- New evidence status values match the `EVIDENCE.current_status` check constraint.
- Oracle compilation and runtime behavior remain pending because no Oracle session is available to this work process.

## Known issues to carry into Stage 1

- `APP_USER.password_hash` values such as `hash_pw_001` are placeholders, not verified secure hashes. They must never be used as production credentials.
- Seeded `ROLE` data does not by itself enforce UI/API authorization. Role enforcement must live in the backend and be tested independently of the UI.
- `JUDGMENT` references a case, not a specific hearing. Decide whether judgments must reference a hearing before changing the schema.
- `PRISON_TRANSFER` records transfers but does not update `INMATE.prison_id`; choose one transaction owner (backend service or database trigger) and test it.
- The current `EVIDENCE_AUDIT` table declares no foreign keys. Stage 0 checks relationships explicitly; consider constraints in a later schema revision once the desired retention/deletion policy is decided.
- Evidence status governance is separate from chain-of-custody history; define legal state transitions and audit expectations.
- Existing base sample rows should still be checked in Oracle for role/semantic consistency; foreign keys alone do not ensure that the referenced user has the intended role.

## Stage 0 exit checklist

- [ ] Clean schema setup finishes without unresolved ORA-/PLS- errors.
- [ ] All 23 application tables exist.
- [ ] All counts match the documented baseline or deviations are documented.
- [ ] Orphan-reference checks return zero rows.
- [ ] Audit trigger is valid and smoke-tested in a disposable schema.
- [ ] Relevant views, function and procedure are valid; no relevant `USER_ERRORS` remain.
- [ ] Script Output/log and Oracle/SQL Developer versions are recorded.
- [ ] Defects discovered at runtime are added to the Stage 1 defect list.
