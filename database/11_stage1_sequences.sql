-- UCJIMS Stage 1: create sequences for future application-created rows.
-- Run once, after Stage 0 data, Stage 1 hardening and query/object scripts.
-- This routine starts each sequence at MAX(primary key)+1, so it is seeded-data aware.
-- EVIDENCE_AUDIT_SEQ already exists and is consumed by TRG_CUSTODY_AUDIT; do not recreate it.

SET SERVEROUTPUT ON;

DECLARE
  PROCEDURE make_sequence(
    p_sequence_name IN VARCHAR2,
    p_table_name    IN VARCHAR2,
    p_column_name   IN VARCHAR2
  ) IS
    v_next_value NUMBER;
  BEGIN
    EXECUTE IMMEDIATE
      'SELECT NVL(MAX(' || p_column_name || '), 0) + 1 FROM ' || p_table_name
      INTO v_next_value;

    EXECUTE IMMEDIATE
      'CREATE SEQUENCE ' || p_sequence_name ||
      ' START WITH ' || TO_CHAR(v_next_value, 'FM9999999999999999999999999990') ||
      ' INCREMENT BY 1 CACHE 20 NOCYCLE';

    DBMS_OUTPUT.PUT_LINE(p_sequence_name || ' starts at ' || TO_CHAR(v_next_value));
  END make_sequence;
BEGIN
  make_sequence('SEQ_ROLE', 'ROLE', 'ROLE_ID');
  make_sequence('SEQ_DEPARTMENT', 'DEPARTMENT', 'DEPARTMENT_ID');
  make_sequence('SEQ_APP_USER', 'APP_USER', 'USER_ID');
  make_sequence('SEQ_PERSON', 'PERSON', 'PERSON_ID');
  make_sequence('SEQ_CASE_TABLE', 'CASE_TABLE', 'CASE_ID');
  make_sequence('SEQ_FIR', 'FIR', 'FIR_ID');
  make_sequence('SEQ_CASE_PERSON', 'CASE_PERSON', 'CASE_PERSON_ID');
  make_sequence('SEQ_INVESTIGATION', 'INVESTIGATION', 'INVESTIGATION_ID');
  make_sequence('SEQ_CASE_INVESTIGATOR', 'CASE_INVESTIGATOR', 'CASE_INVESTIGATOR_ID');
  make_sequence('SEQ_EVIDENCE', 'EVIDENCE', 'EVIDENCE_ID');
  make_sequence('SEQ_CHAIN_OF_CUSTODY', 'CHAIN_OF_CUSTODY', 'CUSTODY_ID');
  make_sequence('SEQ_FORENSIC_REPORT', 'FORENSIC_REPORT', 'REPORT_ID');
  make_sequence('SEQ_COURT', 'COURT', 'COURT_ID');
  make_sequence('SEQ_HEARING', 'HEARING', 'HEARING_ID');
  make_sequence('SEQ_HEARING_PARTICIPANT', 'HEARING_PARTICIPANT', 'HEARING_PARTICIPANT_ID');
  make_sequence('SEQ_JUDGMENT', 'JUDGMENT', 'JUDGMENT_ID');
  make_sequence('SEQ_LEGAL_PROVISION', 'LEGAL_PROVISION', 'PROVISION_ID');
  make_sequence('SEQ_CASE_PROVISION', 'CASE_PROVISION', 'CASE_PROVISION_ID');
  make_sequence('SEQ_SENTENCE', 'SENTENCE', 'SENTENCE_ID');
  make_sequence('SEQ_PRISON', 'PRISON', 'PRISON_ID');
  make_sequence('SEQ_INMATE', 'INMATE', 'INMATE_ID');
  make_sequence('SEQ_PRISON_TRANSFER', 'PRISON_TRANSFER', 'TRANSFER_ID');
END;
/

-- API/service layer should request IDs with sequence.NEXTVAL in parameterized INSERT statements.
-- Sequence gaps after rollbacks are normal; do not infer row counts from sequence values.
SELECT sequence_name, last_number
FROM user_sequences
WHERE sequence_name LIKE 'SEQ_%' OR sequence_name = 'EVIDENCE_AUDIT_SEQ'
ORDER BY sequence_name;
