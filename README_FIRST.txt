UCJIMS DATABASE STAGE 0 + STAGE 1 — RUN THIS FIRST

This package is for the existing aishikiii/ucjims-dbms repository on branch stage-0-1.
It contains changed/new database files, not a replacement for every existing SQL file.
The original Person A/Person B/Person C table/query scripts must remain in database/.

DATABASE FILES TO REPLACE ON stage-0-1:
  database/03_sample_data_personB.sql
  database/03a_additional_sample_data_personB.sql
  database/09_integration_demo_personC.sql
  database/stage0_database_validation.sql

NEW DATABASE FILES TO ADD ON stage-0-1:
  database/stage0_baseline_gate.sql
  database/10_stage1_hardening.sql
  database/11_stage1_sequences.sql
  database/12_stage1_workflows.sql
  database/13_golden_case_fixture.sql
  database/14_stage1_validation.sql
  database/run_fresh_setup.sql

STATIC CHECKER (not SQL to upload into database/):
  static_lint.py

RUN LOCALLY IN ORACLE SQL DEVELOPER:
1. Use a disposable, EMPTY development schema; do not use a shared or production schema.
2. Place/overlay these files into a local checkout of the stage-0-1 branch, preserving their folders.
3. Open database/run_fresh_setup.sql in SQL Developer and press F5 (Run Script).
4. The runner creates Stage 0 schema/data, runs read-only checks and the Stage 0 fail-fast gate, then automatically proceeds into Stage 1 only if Stage 0 passes. Stage 1 adds constraints/triggers/indexes/sequences/workflows, creates GOLDEN-CASE-0001, and runs the Stage 1 acceptance suite.
5. A successful output must include these lines:
     STAGE 0 PASS: ...
     GOLDEN-CASE-0001 passed. ...
     Stage 1 acceptance passed: ...
6. Run the static checker from the repository root with: python static_lint.py
7. Save the SQL Developer Script Output and inspect all invalid objects/errors before considering the database verified.

IMPORTANT:
- This setup has not been executed inside your Oracle session by this assistant. Static lint passes, but the real Oracle run is still required.
- The runner intentionally aborts if any UCJIMS table already exists. It is not a reset/drop script. Use a new empty development schema for a clean rerun.
- Seed inserts use fixed IDs and must not be manually rerun on a populated schema.
- All data is synthetic and for coursework/testing only.
- Do not merge to main until the runner and acceptance tests pass in Oracle SQL Developer.
