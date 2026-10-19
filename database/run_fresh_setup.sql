-- UCJIMS database Stage 0 + Stage 1 clean setup runner.
-- WARNING: Run only in a disposable, empty development schema. Raw seed scripts use fixed IDs.
-- Open this file in Oracle SQL Developer and use Run Script (F5), not Ctrl+Enter.
-- This sequence includes the expanded synthetic dataset and permanently seeds GOLDEN-CASE-0001.

SET DEFINE OFF;
SET SERVEROUTPUT ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

PROMPT Preflight: ensure none of the UCJIMS tables already exists in this schema.
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM user_tables
  WHERE table_name IN (
    'ROLE','DEPARTMENT','APP_USER','PERSON','CASE_TABLE','FIR','CASE_PERSON','INVESTIGATION','CASE_INVESTIGATOR',
    'EVIDENCE','CHAIN_OF_CUSTODY','FORENSIC_REPORT','EVIDENCE_AUDIT','COURT','HEARING','HEARING_PARTICIPANT',
    'JUDGMENT','LEGAL_PROVISION','CASE_PROVISION','SENTENCE','PRISON','INMATE','PRISON_TRANSFER'
  );
  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20050,
      'UCJIMS tables already exist. Use a new empty development schema; this setup is not a reset script.');
  END IF;
END;
/

PROMPT ===== Stage 0: baseline schema and sample data =====
@@01_tables_personA.sql
@@02_sample_data_personA.sql
@@03_queries_personA.sql
@@02_tables_personB.sql
@@04_triggers_personB.sql
@@03_sample_data_personB.sql
@@06_tables_personC.sql
@@07_sample_data_personC.sql
@@09_integration_demo_personC.sql
@@03a_additional_sample_data_personB.sql
@@05_queries_personB.sql
@@08_queries_personC.sql
@@stage0_database_validation.sql
@@stage0_baseline_gate.sql

PROMPT ===== Stage 1: hardening, sequences, workflows, Golden Case =====
@@10_stage1_hardening.sql
@@11_stage1_sequences.sql
@@12_stage1_workflows.sql
@@13_golden_case_fixture.sql
@@14_stage1_validation.sql

PROMPT ===== UCJIMS Stage 0 + Stage 1 scripts finished. Review all output above. =====
