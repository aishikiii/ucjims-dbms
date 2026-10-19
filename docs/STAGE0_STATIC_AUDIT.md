# UCJIMS Stage 0 — Static Audit Report

## Scope
Reviewed the current SQL files on branch `stage-0-1`, checked the proposed Person B additions, and reviewed the run order and read-only validation script. This report is static analysis only; it does not claim Oracle execution.

## Results

| Check | Result | Notes |
|---|---|---|
| New Person B INSERT statement count | PASS | 30 EVIDENCE + 30 CHAIN_OF_CUSTODY + 24 FORENSIC_REPORT = 84 inserts. |
| Primary-key ranges | PASS | Added evidence/custody IDs 7–36; reports IDs 6–29; follows tracked seed and integration IDs. |
| New custody-to-evidence references | PASS | Every added custody row references the corresponding added evidence ID. |
| Sender/receiver distinctness | PASS | No added custody row transfers from a user to the same user. |
| Evidence status domain | PASS | All added values match the check constraint values. |
| Report-to-evidence references | PASS | Reports IDs 6–29 map to evidence IDs 7–30. |
| Examination date ordering | PASS | All added examination dates are on or after associated evidence collection dates. |
| Table count in validation inventory | FIXED | The current schema has 23 application tables, not 24. Validation/runbook now use 23. |
| Foreign-key runtime behavior | PENDING | Requires running DDL/DML in Oracle SQL Developer. |
| PL/SQL trigger/function/procedure compilation | PENDING | Requires checking `USER_OBJECTS` and `USER_ERRORS` in Oracle. |
| Trigger-generated audit row count | PENDING | Expected to be 36 on one clean run; must be verified in Oracle. |

## Known design risks confirmed in existing schema

1. `APP_USER.password_hash` uses placeholder strings in seed data.
2. `EVIDENCE_AUDIT` does not declare foreign keys to custody/evidence/users. The validation script checks for orphaned audit rows but does not change the schema contract.
3. `JUDGMENT` has no FK to `HEARING`; decide whether a specific hearing association is required.
4. `PRISON_TRANSFER` inserts do not update the current `INMATE.prison_id`; application/DB ownership must be chosen in Stage 1.
5. Role-based data semantics cannot all be enforced by the current FKs (e.g. a user FK does not prove that the user is actually a Forensic Officer). Added forensic reports use seeded Forensic Officer user IDs 8–10.

## Acceptance condition

Do not treat Stage 0 as runtime-passed until the complete fresh-schema run has been performed in Oracle SQL Developer, validation output saved, relevant Oracle compilation errors resolved, and the trigger smoke test completed in a disposable schema.
