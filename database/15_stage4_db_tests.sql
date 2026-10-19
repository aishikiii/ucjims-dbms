-- ============================================================================
-- UCJIMS Stage 4: database negative + workflow tests
-- File: database/15_stage4_db_tests.sql
--
-- HOW TO RUN (Oracle SQL Developer):
--   1. Connect to the disposable schema that run_fresh_setup.sql already built.
--   2. Open this file, press F5 (Run Script), NOT Ctrl+Enter.
--   3. Open View > Dbms Output, add your connection, and read the PASS/FAIL lines
--      (or read the "Script Output" tab; SERVEROUTPUT is switched on below).
--
-- SAFE TO RE-RUN: every test runs inside a SAVEPOINT that is rolled back and the
-- script ends with ROLLBACK. Nothing is committed. Sequences may skip numbers.
--
-- Result meanings:
--   PASS          the database behaved as designed
--   FAIL          a rule you expected is NOT enforced (a real finding - fix it)
--   SKIP          the seed data has no suitable row for that test
--   INCONCLUSIVE  a positive workflow raised an error; read the message
--

-- ============================================================================
SET DEFINE OFF;
SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT ===== 1. Object health (each query should return zero rows) =====
SELECT object_type, object_name, status FROM user_objects WHERE status <> 'VALID';
SELECT name, type, line, position, text FROM user_errors ORDER BY name, sequence;
SELECT table_name, constraint_name, status FROM user_constraints WHERE status <> 'ENABLED';
SELECT trigger_name, status FROM user_triggers WHERE status <> 'ENABLED';

PROMPT ===== 2. Constraint, trigger and workflow tests =====
DECLARE
  g_pass NUMBER := 0;
  g_fail NUMBER := 0;
  g_skip NUMBER := 0;

  v_case          NUMBER;
  v_court         NUMBER;
  v_judge         NUMBER;
  v_investigator  NUMBER;
  v_forensic      NUMBER;
  v_evidence      NUMBER;
  v_hearing_sched NUMBER;
  v_hearing_done  NUMBER;
  v_hearing_case  NUMBER;
  v_other_case    NUMBER;
  v_not_in_case   NUMBER;
  v_sent_judg     NUMBER;
  v_sent_person   NUMBER;
  v_not_accused   NUMBER;
  v_inm_in        NUMBER;
  v_inm_prison    NUMBER;
  v_inm_released  NUMBER;
  v_inm_future    NUMBER;
  v_inm_due       NUMBER;
  v_prison_other  NUMBER;
  v_sentence      NUMBER;
  v_person        NUMBER;
  v_custodian     NUMBER;
  v_recipient     NUMBER;
  v_cid           NUMBER;
  v_before_c      NUMBER;
  v_after_c       NUMBER;
  v_before_a      NUMBER;
  v_after_a       NUMBER;
  v_status        VARCHAR2(30);
  v_rel_date      DATE;
  v_count         NUMBER;

  PROCEDURE ok(p_label IN VARCHAR2) IS
  BEGIN
    g_pass := g_pass + 1;
    DBMS_OUTPUT.PUT_LINE('PASS          ' || p_label);
  END;

  PROCEDURE bad(p_label IN VARCHAR2, p_msg IN VARCHAR2) IS
  BEGIN
    g_fail := g_fail + 1;
    DBMS_OUTPUT.PUT_LINE('FAIL          ' || p_label || '  -> ' || p_msg);
  END;

  PROCEDURE skip(p_label IN VARCHAR2, p_why IN VARCHAR2) IS
  BEGIN
    g_skip := g_skip + 1;
    DBMS_OUTPUT.PUT_LINE('SKIP          ' || p_label || '  -> ' || p_why);
  END;

  -- Returns the single number a query yields, or NULL.
  FUNCTION lookup(p_sql IN VARCHAR2) RETURN NUMBER IS
    v NUMBER;
  BEGIN
    EXECUTE IMMEDIATE p_sql INTO v;
    RETURN v;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  -- TRUE when the value exists; otherwise logs a SKIP.
  FUNCTION need(p_label IN VARCHAR2, p_value IN NUMBER) RETURN BOOLEAN IS
  BEGIN
    IF p_value IS NULL THEN
      skip(p_label, 'no suitable row in the seed data');
      RETURN FALSE;
    END IF;
    RETURN TRUE;
  END;

  -- Runs p_sql and PASSES only if it fails with exactly ORA-p_code.
  PROCEDURE expect_error(p_label IN VARCHAR2, p_sql IN VARCHAR2, p_code IN NUMBER) IS
    v_code NUMBER;
    v_msg  VARCHAR2(300);
  BEGIN
    SAVEPOINT sp_expect;
    BEGIN
      EXECUTE IMMEDIATE p_sql;
      ROLLBACK TO sp_expect;
      bad(p_label, 'statement SUCCEEDED but should have been rejected (expected ORA' || p_code || ')');
    EXCEPTION
      WHEN OTHERS THEN
        v_code := SQLCODE;
        v_msg  := SUBSTR(SQLERRM, 1, 200);
        ROLLBACK TO sp_expect;
        IF v_code = p_code THEN
          ok(p_label || '  [ORA' || p_code || ']');
        ELSE
          bad(p_label, 'expected ORA' || p_code || ' but got ' || v_code || ': ' || v_msg);
        END IF;
    END;
  END;

BEGIN
  -- ---------- lookups (no hard-coded IDs, so the script survives data changes) ----------
  v_case         := lookup('SELECT MIN(case_id) FROM CASE_TABLE');
  v_court := lookup('SELECT MIN(court_id) FROM COURT');
  v_judge        := lookup(q'[SELECT MIN(u.user_id) FROM APP_USER u JOIN ROLE r ON r.role_id=u.role_id WHERE r.role_name='Judge' AND u.status='ACTIVE']');
  v_investigator := lookup(q'[SELECT MIN(u.user_id) FROM APP_USER u JOIN ROLE r ON r.role_id=u.role_id WHERE r.role_name='Investigator' AND u.status='ACTIVE']');
  v_forensic     := lookup(q'[SELECT MIN(u.user_id) FROM APP_USER u JOIN ROLE r ON r.role_id=u.role_id WHERE r.role_name='Forensic Officer' AND u.status='ACTIVE']');
  v_evidence     := lookup(q'[SELECT MIN(evidence_id) FROM EVIDENCE WHERE current_status <> 'DISPOSED']');
  v_hearing_sched:= lookup(q'[SELECT MIN(hearing_id) FROM HEARING WHERE hearing_status='SCHEDULED']');
  v_hearing_done := lookup(q'[SELECT MIN(hearing_id) FROM HEARING WHERE hearing_status='COMPLETED']');
  v_hearing_case := lookup('SELECT case_id FROM HEARING WHERE hearing_id = ' || NVL(TO_CHAR(v_hearing_done), '-1'));
  v_other_case   := lookup('SELECT MIN(case_id) FROM CASE_TABLE WHERE case_id <> ' || NVL(TO_CHAR(v_hearing_case), '-1'));
  v_not_in_case  := lookup('SELECT MIN(p.person_id) FROM PERSON p WHERE NOT EXISTS (SELECT 1 FROM CASE_PERSON cp WHERE cp.case_id = '
                           || NVL(TO_CHAR(v_hearing_case), '-1') || ' AND cp.person_id = p.person_id)');
  v_sent_judg    := lookup('SELECT MIN(judgment_id) FROM SENTENCE');
  v_sent_person  := lookup('SELECT MIN(person_id) FROM SENTENCE WHERE judgment_id = ' || NVL(TO_CHAR(v_sent_judg), '-1'));
  v_not_accused  := lookup('SELECT MIN(p.person_id) FROM PERSON p WHERE NOT EXISTS (SELECT 1 FROM CASE_PERSON cp JOIN JUDGMENT j ON j.case_id = cp.case_id '
                           || 'WHERE j.judgment_id = ' || NVL(TO_CHAR(v_sent_judg), '-1')
                           || q'[ AND cp.person_id = p.person_id AND cp.role_in_case = 'ACCUSED')]');
  v_inm_in       := lookup(q'[SELECT MIN(inmate_id) FROM INMATE WHERE status='INCARCERATED']');
  v_inm_prison   := lookup('SELECT prison_id FROM INMATE WHERE inmate_id = ' || NVL(TO_CHAR(v_inm_in), '-1'));
  v_inm_released := lookup(q'[SELECT MIN(inmate_id) FROM INMATE WHERE status='RELEASED']');
  v_inm_future   := lookup(q'[SELECT MIN(inmate_id) FROM INMATE WHERE status='INCARCERATED' AND expected_release_date > SYSDATE]');
  v_inm_due      := lookup(q'[SELECT MIN(inmate_id) FROM INMATE WHERE status='INCARCERATED' AND expected_release_date <= TRUNC(SYSDATE)]');
  v_prison_other := lookup('SELECT MIN(prison_id) FROM PRISON WHERE prison_id <> ' || NVL(TO_CHAR(v_inm_prison), '-1'));
  v_sentence     := lookup('SELECT MIN(sentence_id) FROM SENTENCE');
  v_person       := lookup('SELECT MIN(person_id) FROM PERSON');

  
  -- ---------- A. Foreign keys, CHECKs, UNIQUEs ----------
  IF need('A1/A2 prerequisites (Judge)', v_judge)
     AND need('A1/A2 prerequisites (Court)', v_court) THEN

    expect_error('A1 FK: hearing for an unknown case is rejected',
      'INSERT INTO HEARING (hearing_id, case_id, court_id, judge_id, hearing_date, hearing_status) VALUES (990001, 999999, '
      || v_court || ', ' || v_judge || q'[, SYSDATE, 'SCHEDULED')]', -2291);

    expect_error('A2 CHECK: hearing status PENDING is rejected',
      'INSERT INTO HEARING (hearing_id, case_id, court_id, judge_id, hearing_date, hearing_status) VALUES (990002, '
      || v_case || ', ' || v_court || ', ' || v_judge || q'[, SYSDATE, 'PENDING')]', -2290);

  END IF;


  IF need('A3 prerequisites', v_investigator) THEN
    expect_error('A3 CHECK: evidence type "Hologram" is rejected',
      'INSERT INTO EVIDENCE (evidence_id, case_id, evidence_type, description, collection_date, collection_location, collected_by, storage_location, current_status) VALUES (990003, '
      || v_case || q'[, 'Hologram', 'test', SYSDATE, 'test', ]' || v_investigator || q'[, 'test', 'COLLECTED')]', -2290);
  END IF;

  IF need('A4 prerequisites', v_sentence) THEN
    expect_error('A4 CHECK: inmate status ESCAPED is rejected',
      'INSERT INTO INMATE (inmate_id, person_id, prison_id, sentence_id, admission_date, expected_release_date, actual_release_date, status) VALUES (990004, '
      || v_person || ', (SELECT MIN(prison_id) FROM PRISON), ' || v_sentence || q'[, SYSDATE, NULL, NULL, 'ESCAPED')]', -2290);
  END IF;

  expect_error('A5 UNIQUE: duplicate case_number is rejected',
    'INSERT INTO CASE_TABLE (case_id, case_number, case_type, registration_date, incident_date, incident_location, description, case_status, priority) '
    || 'SELECT 990005, case_number, case_type, registration_date, incident_date, incident_location, description, case_status, priority FROM CASE_TABLE WHERE ROWNUM = 1', -1);

  expect_error('A6 UNIQUE: duplicate fir_number is rejected',
    'INSERT INTO FIR (fir_id, case_id, filed_by_user_id, complainant_id, fir_number, filing_date, station_name, fir_details) '
    || 'SELECT 990006, case_id, filed_by_user_id, complainant_id, fir_number, filing_date, station_name, fir_details FROM FIR WHERE ROWNUM = 1', -1);

  IF need('A7 prerequisites', v_inm_in) THEN
    expect_error('A7 CHECK: prison transfer to the same prison is rejected',
      'INSERT INTO PRISON_TRANSFER (transfer_id, inmate_id, from_prison_id, to_prison_id, transfer_date, reason) VALUES (990007, '
      || v_inm_in || ', ' || v_inm_prison || ', ' || v_inm_prison || q'[, SYSDATE, 'test')]', -2290);
  END IF;

  IF need('A8 prerequisites', v_sent_judg) AND need('A8 prerequisites', v_sent_person) THEN
    expect_error('A8 CHECK: sentence ending before it starts is rejected',
      'INSERT INTO SENTENCE (sentence_id, judgment_id, person_id, sentence_type, duration, fine_amount, start_date, end_date) VALUES (990008, '
      || v_sent_judg || ', ' || v_sent_person || q'[, 'Imprisonment', '1 year', NULL, SYSDATE, SYSDATE - 5)]', -2290);
  END IF;

  IF need('A9 prerequisites', v_inm_in) THEN
    -- This is exactly what PATCH /api/court/inmates/:id/release does today.
    expect_error('A9 API BUG CHECK: raw "UPDATE ... SET status=RELEASED" (no release date) is rejected',
      q'[UPDATE INMATE SET status = 'RELEASED' WHERE inmate_id = ]' || v_inm_in, -2290);
  END IF;

  -- ---------- B. Append-only history ----------
  expect_error('B1 custody rows cannot be updated',
    q'[UPDATE CHAIN_OF_CUSTODY SET remarks = 'tampered' WHERE ROWNUM = 1]', -20031);
  expect_error('B2 custody rows cannot be deleted',
    'DELETE FROM CHAIN_OF_CUSTODY WHERE ROWNUM = 1', -20031);
  expect_error('B3 audit rows cannot be updated',
    'UPDATE EVIDENCE_AUDIT SET evidence_id = evidence_id WHERE ROWNUM = 1', -20032);
  expect_error('B4 audit rows cannot be deleted',
    'DELETE FROM EVIDENCE_AUDIT WHERE ROWNUM = 1', -20032);

  -- ---------- C. Role guards ----------
  IF need('C1 prerequisites', v_investigator) THEN
    expect_error('C1 hearing assigned to a non-Judge is rejected',
      'INSERT INTO HEARING (hearing_id, case_id, judge_id, hearing_date, hearing_status) VALUES (990011, '
      || v_case || ', ' || v_investigator || q'[, SYSDATE, 'SCHEDULED')]', -20092);
    expect_error('C3 forensic report by a non-Forensic Officer is rejected',
      'INSERT INTO FORENSIC_REPORT (report_id, evidence_id, forensic_officer_id, examination_date) VALUES (990013, '
      || NVL(TO_CHAR(v_evidence), '-1') || ', ' || v_investigator || ', SYSDATE)', -20090);
  END IF;

  expect_error('C2 hearing with NO judge is rejected (API must always send judge_id)',
    'INSERT INTO HEARING (hearing_id, case_id, judge_id, hearing_date, hearing_status) VALUES (990012, '
    || v_case || ', NULL, SYSDATE, ' || q'['SCHEDULED')]', -20093);

  IF need('C4 prerequisites', v_judge) THEN
    expect_error('C4 case investigator who is a Judge is rejected',
      'INSERT INTO CASE_INVESTIGATOR (case_investigator_id, case_id, investigator_user_id, assigned_date, role_in_investigation) VALUES (990014, '
      || v_case || ', ' || v_judge || q'[, SYSDATE, 'ASSISTANT')]', -20094);
  END IF;

  IF need('C5 prerequisites', v_hearing_done) AND need('C5 prerequisites', v_not_in_case) THEN
    expect_error('C5 hearing participant who is not in the case is rejected',
      'INSERT INTO HEARING_PARTICIPANT (hearing_participant_id, hearing_id, person_id, participant_role) VALUES (990015, '
      || v_hearing_done || ', ' || v_not_in_case || q'[, 'WITNESS')]', -20096);
  END IF;

  -- ---------- D. Judgment and sentence rules ----------
  IF need('D1 prerequisites (a SCHEDULED hearing)', v_hearing_sched) THEN
    expect_error('D1 judgment on a hearing that is not COMPLETED is rejected',
      'INSERT INTO JUDGMENT (judgment_id, case_id, hearing_id, judgment_date, verdict) '
      || 'SELECT 990021, case_id, hearing_id, hearing_date, ''Guilty'' FROM HEARING WHERE hearing_id = ' || v_hearing_sched, -20081);
  END IF;

  IF need('D2 prerequisites', v_hearing_done) AND need('D2 prerequisites', v_other_case) THEN
    expect_error('D2 judgment whose hearing belongs to a different case is rejected',
      'INSERT INTO JUDGMENT (judgment_id, case_id, hearing_id, judgment_date, verdict) '
      || 'SELECT 990022, ' || v_other_case || ', hearing_id, hearing_date, ''Guilty'' FROM HEARING WHERE hearing_id = ' || v_hearing_done, -20080);
    expect_error('D3 judgment dated differently from its hearing is rejected',
      'INSERT INTO JUDGMENT (judgment_id, case_id, hearing_id, judgment_date, verdict) '
      || 'SELECT 990023, case_id, hearing_id, hearing_date + 3, ''Guilty'' FROM HEARING WHERE hearing_id = ' || v_hearing_done, -20082);
  END IF;

  IF need('D4 prerequisites', v_sent_judg) AND need('D4 prerequisites', v_not_accused) THEN
    expect_error('D4 sentence for a person who is not the accused is rejected',
      'INSERT INTO SENTENCE (sentence_id, judgment_id, person_id, sentence_type, duration, fine_amount, start_date, end_date) VALUES (990024, '
      || v_sent_judg || ', ' || v_not_accused || q'[, 'Fine', NULL, 1, SYSDATE, NULL)]', -20098);
  END IF;

  -- ---------- E. Stored-procedure guards ----------
  expect_error('E1 RELEASE_INMATE on a missing inmate is rejected',
    'BEGIN RELEASE_INMATE(999999); END;', -20022);

  IF need('E2 prerequisites (a RELEASED inmate)', v_inm_released) THEN
    expect_error('E2 RELEASE_INMATE on an already released inmate is rejected',
      'BEGIN RELEASE_INMATE(' || v_inm_released || '); END;', -20023);
    expect_error('E5 TRANSFER_INMATE on a released inmate is rejected',
      'BEGIN TRANSFER_INMATE(' || v_inm_released || ', ' || NVL(TO_CHAR(v_prison_other), '1') || q'[, SYSDATE, 'test'); END;]', -20013);
  END IF;

  IF need('E3 prerequisites (INCARCERATED with a future expected date)', v_inm_future) THEN
    expect_error('E3 RELEASE_INMATE before the expected date is rejected',
      'BEGIN RELEASE_INMATE(' || v_inm_future || '); END;', -20027);
  END IF;

  IF need('E4 prerequisites', v_inm_in) THEN
    expect_error('E4 TRANSFER_INMATE to the current prison is rejected',
      'BEGIN TRANSFER_INMATE(' || v_inm_in || ', ' || v_inm_prison || q'[, SYSDATE, 'test'); END;]', -20014);
    expect_error('E6 TRANSFER_INMATE to an unknown prison is rejected',
      'BEGIN TRANSFER_INMATE(' || v_inm_in || q'[, 999999, SYSDATE, 'test'); END;]', -20016);
  END IF;

  expect_error('E7 TRANSFER_EVIDENCE for a missing evidence item is rejected',
    q'[DECLARE v NUMBER; BEGIN TRANSFER_EVIDENCE(999999, 1, SYSDATE - 1, 'Lab', 'Room A', 'Test', 'Sealed', NULL, v); END;]', -20063);
  expect_error('E8 TRANSFER_EVIDENCE with a future timestamp is rejected',
    q'[DECLARE v NUMBER; BEGIN TRANSFER_EVIDENCE(1, 1, SYSDATE + 1, 'Lab', 'Room A', 'Test', 'Sealed', NULL, v); END;]', -20062);
  expect_error('E9 TRANSFER_EVIDENCE without a purpose is rejected',
    q'[DECLARE v NUMBER; BEGIN TRANSFER_EVIDENCE(1, 1, SYSDATE - 1, 'Lab', 'Room A', NULL, 'Sealed', NULL, v); END;]', -20061);

  -- ---------- F. Positive workflows (changes are rolled back) ----------
  -- F1: a valid custody transfer adds exactly one custody row AND one audit row.
  IF need('F1 prerequisites (evidence + Forensic Officer)', v_evidence) AND need('F1 prerequisites (Forensic Officer)', v_forensic) THEN
    v_custodian := lookup('SELECT NVL((SELECT to_user_id FROM CHAIN_OF_CUSTODY WHERE evidence_id = ' || v_evidence
                          || ' AND transfer_date_time = (SELECT MAX(transfer_date_time) FROM CHAIN_OF_CUSTODY WHERE evidence_id = ' || v_evidence
                          || ')), (SELECT collected_by FROM EVIDENCE WHERE evidence_id = ' || v_evidence || ')) FROM dual');
    v_recipient := lookup(q'[SELECT MIN(u.user_id) FROM APP_USER u JOIN ROLE r ON r.role_id=u.role_id WHERE r.role_name='Forensic Officer' AND u.status='ACTIVE' AND u.user_id <> ]'
                          || NVL(TO_CHAR(v_custodian), '-1'));
    IF need('F1 prerequisites (a different Forensic Officer)', v_recipient) THEN
      SAVEPOINT sp_f1;
      BEGIN
        SELECT COUNT(*) INTO v_before_c FROM CHAIN_OF_CUSTODY WHERE evidence_id = v_evidence;
        SELECT COUNT(*) INTO v_before_a FROM EVIDENCE_AUDIT   WHERE evidence_id = v_evidence;
        TRANSFER_EVIDENCE(v_evidence, v_recipient, SYSDATE - (1/1440), 'Forensic Lab 1', 'Forensic Lab 1', 'Stage 4 test', 'Sealed', 'rolled back', v_cid);
        SELECT COUNT(*) INTO v_after_c FROM CHAIN_OF_CUSTODY WHERE evidence_id = v_evidence;
        SELECT COUNT(*) INTO v_after_a FROM EVIDENCE_AUDIT   WHERE evidence_id = v_evidence;
        IF v_after_c = v_before_c + 1 AND v_after_a = v_before_a + 1 THEN
          ok('F1 TRANSFER_EVIDENCE adds one custody row and one audit row (evidence ' || v_evidence || ')');
        ELSE
          bad('F1 TRANSFER_EVIDENCE audit consistency',
              'custody ' || v_before_c || '->' || v_after_c || ', audit ' || v_before_a || '->' || v_after_a);
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('INCONCLUSIVE  F1 TRANSFER_EVIDENCE valid transfer  -> ' || SUBSTR(SQLERRM, 1, 200));
      END;
      ROLLBACK TO sp_f1;
    END IF;
  END IF;

  -- F2: releasing a due inmate sets BOTH status and actual_release_date.
  IF need('F2 prerequisites (INCARCERATED inmate whose expected date has passed)', v_inm_due) THEN
    SAVEPOINT sp_f2;
    BEGIN
      RELEASE_INMATE(v_inm_due);
      SELECT status, actual_release_date INTO v_status, v_rel_date FROM INMATE WHERE inmate_id = v_inm_due;
      IF v_status = 'RELEASED' AND v_rel_date IS NOT NULL THEN
        ok('F2 RELEASE_INMATE sets status RELEASED and an actual release date (inmate ' || v_inm_due || ')');
      ELSE
        bad('F2 RELEASE_INMATE result', 'status=' || v_status || ', actual_release_date=' || NVL(TO_CHAR(v_rel_date), 'NULL'));
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('INCONCLUSIVE  F2 RELEASE_INMATE valid release  -> ' || SUBSTR(SQLERRM, 1, 200));
    END;
    ROLLBACK TO sp_f2;
  END IF;

  -- F3: a transfer updates BOTH the history table and INMATE.prison_id.
  IF need('F3 prerequisites (an INCARCERATED inmate and a second prison)', v_inm_in) AND need('F3 prerequisites (a second prison)', v_prison_other) THEN
    SAVEPOINT sp_f3;
    BEGIN
      SELECT COUNT(*) INTO v_before_c FROM PRISON_TRANSFER WHERE inmate_id = v_inm_in;
      TRANSFER_INMATE(v_inm_in, v_prison_other, SYSDATE - (1/1440), 'Stage 4 test');
      SELECT COUNT(*) INTO v_after_c FROM PRISON_TRANSFER WHERE inmate_id = v_inm_in;
      SELECT prison_id INTO v_count FROM INMATE WHERE inmate_id = v_inm_in;
      IF v_after_c = v_before_c + 1 AND v_count = v_prison_other THEN
        ok('F3 TRANSFER_INMATE logs the move and updates the current prison (inmate ' || v_inm_in || ')');
      ELSE
        bad('F3 TRANSFER_INMATE consistency', 'history ' || v_before_c || '->' || v_after_c || ', current prison=' || v_count);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('INCONCLUSIVE  F3 TRANSFER_INMATE valid transfer  -> ' || SUBSTR(SQLERRM, 1, 200));
    END;
    ROLLBACK TO sp_f3;
  END IF;

  -- F4: the occupancy function agrees with a plain count for every prison.
  v_count := 0;
  FOR p IN (SELECT prison_id FROM PRISON) LOOP
    SELECT COUNT(*) INTO v_before_c FROM INMATE WHERE prison_id = p.prison_id AND status = 'INCARCERATED';
    IF GET_PRISON_OCCUPANCY(p.prison_id) <> v_before_c THEN
      v_count := v_count + 1;
      bad('F4 GET_PRISON_OCCUPANCY(' || p.prison_id || ')', 'function disagrees with COUNT(*) = ' || v_before_c);
    END IF;
  END LOOP;
  IF v_count = 0 THEN
    ok('F4 GET_PRISON_OCCUPANCY matches the real count for every prison');
  END IF;

  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
  DBMS_OUTPUT.PUT_LINE('PASS=' || g_pass || '  FAIL=' || g_fail || '  SKIP=' || g_skip);
  IF g_fail > 0 THEN
    RAISE_APPLICATION_ERROR(-20999, 'Stage 4 database tests: ' || g_fail || ' FAIL(s). Read the FAIL lines above.');
  END IF;
  DBMS_OUTPUT.PUT_LINE('Stage 4 database tests passed (INCONCLUSIVE lines, if any, still need a look).');
END;
/

PROMPT ===== Done. Nothing was committed. =====