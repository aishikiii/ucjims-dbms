-- UCJIMS Stage 1 post-fixture validation.
-- Run after 13_golden_case_fixture.sql. This script is read-only.

PROMPT 1. Table counts after the baseline plus GOLDEN-CASE-0001.
SELECT 'ROLE' AS table_name, COUNT(*) AS row_count FROM ROLE
UNION ALL SELECT 'DEPARTMENT', COUNT(*) FROM DEPARTMENT
UNION ALL SELECT 'APP_USER', COUNT(*) FROM APP_USER
UNION ALL SELECT 'PERSON', COUNT(*) FROM PERSON
UNION ALL SELECT 'CASE_TABLE', COUNT(*) FROM CASE_TABLE
UNION ALL SELECT 'FIR', COUNT(*) FROM FIR
UNION ALL SELECT 'CASE_PERSON', COUNT(*) FROM CASE_PERSON
UNION ALL SELECT 'INVESTIGATION', COUNT(*) FROM INVESTIGATION
UNION ALL SELECT 'CASE_INVESTIGATOR', COUNT(*) FROM CASE_INVESTIGATOR
UNION ALL SELECT 'EVIDENCE', COUNT(*) FROM EVIDENCE
UNION ALL SELECT 'CHAIN_OF_CUSTODY', COUNT(*) FROM CHAIN_OF_CUSTODY
UNION ALL SELECT 'FORENSIC_REPORT', COUNT(*) FROM FORENSIC_REPORT
UNION ALL SELECT 'EVIDENCE_AUDIT', COUNT(*) FROM EVIDENCE_AUDIT
UNION ALL SELECT 'COURT', COUNT(*) FROM COURT
UNION ALL SELECT 'HEARING', COUNT(*) FROM HEARING
UNION ALL SELECT 'HEARING_PARTICIPANT', COUNT(*) FROM HEARING_PARTICIPANT
UNION ALL SELECT 'JUDGMENT', COUNT(*) FROM JUDGMENT
UNION ALL SELECT 'LEGAL_PROVISION', COUNT(*) FROM LEGAL_PROVISION
UNION ALL SELECT 'CASE_PROVISION', COUNT(*) FROM CASE_PROVISION
UNION ALL SELECT 'SENTENCE', COUNT(*) FROM SENTENCE
UNION ALL SELECT 'PRISON', COUNT(*) FROM PRISON
UNION ALL SELECT 'INMATE', COUNT(*) FROM INMATE
UNION ALL SELECT 'PRISON_TRANSFER', COUNT(*) FROM PRISON_TRANSFER
ORDER BY table_name;

PROMPT 2. Referential integrity. Each query should return zero rows.
SELECT e.evidence_id FROM EVIDENCE e LEFT JOIN CASE_TABLE c ON c.case_id=e.case_id WHERE c.case_id IS NULL;
SELECT x.custody_id FROM CHAIN_OF_CUSTODY x LEFT JOIN EVIDENCE e ON e.evidence_id=x.evidence_id WHERE e.evidence_id IS NULL;
SELECT f.report_id FROM FORENSIC_REPORT f LEFT JOIN EVIDENCE e ON e.evidence_id=f.evidence_id WHERE e.evidence_id IS NULL;
SELECT j.judgment_id FROM JUDGMENT j LEFT JOIN HEARING h ON h.hearing_id=j.hearing_id AND h.case_id=j.case_id WHERE h.hearing_id IS NULL;
SELECT s.sentence_id FROM SENTENCE s LEFT JOIN JUDGMENT j ON j.judgment_id=s.judgment_id WHERE j.judgment_id IS NULL;
SELECT i.inmate_id FROM INMATE i LEFT JOIN SENTENCE s ON s.sentence_id=i.sentence_id WHERE i.sentence_id IS NOT NULL AND s.sentence_id IS NULL;
SELECT a.audit_id FROM EVIDENCE_AUDIT a LEFT JOIN CHAIN_OF_CUSTODY x ON x.custody_id=a.custody_id AND x.evidence_id=a.evidence_id WHERE x.custody_id IS NULL;

PROMPT 3. Domain semantics. Each query should return zero rows.
SELECT fr.report_id, r.role_name FROM FORENSIC_REPORT fr JOIN APP_USER u ON u.user_id=fr.forensic_officer_id JOIN ROLE r ON r.role_id=u.role_id WHERE r.role_name <> 'Forensic Officer';
SELECT h.hearing_id, r.role_name FROM HEARING h JOIN APP_USER u ON u.user_id=h.judge_id JOIN ROLE r ON r.role_id=u.role_id WHERE r.role_name <> 'Judge';
SELECT s.sentence_id, s.person_id, j.case_id FROM SENTENCE s JOIN JUDGMENT j ON j.judgment_id=s.judgment_id WHERE NOT EXISTS (SELECT 1 FROM CASE_PERSON cp WHERE cp.case_id=j.case_id AND cp.person_id=s.person_id AND cp.role_in_case='ACCUSED');
SELECT hp.hearing_participant_id, hp.person_id, h.case_id FROM HEARING_PARTICIPANT hp JOIN HEARING h ON h.hearing_id=hp.hearing_id WHERE NOT EXISTS (SELECT 1 FROM CASE_PERSON cp WHERE cp.case_id=h.case_id AND cp.person_id=hp.person_id);
SELECT x.custody_id FROM CHAIN_OF_CUSTODY x WHERE x.from_user_id=x.to_user_id;
SELECT f.report_id FROM FORENSIC_REPORT f JOIN EVIDENCE e ON e.evidence_id=f.evidence_id WHERE f.examination_date < e.collection_date;
SELECT x.custody_id FROM CHAIN_OF_CUSTODY x JOIN EVIDENCE e ON e.evidence_id=x.evidence_id WHERE x.transfer_date_time < e.collection_date;
SELECT i.inmate_id, i.prison_id, t.to_prison_id FROM INMATE i JOIN (SELECT inmate_id, MAX(transfer_date) latest_date FROM PRISON_TRANSFER GROUP BY inmate_id) m ON m.inmate_id=i.inmate_id JOIN PRISON_TRANSFER t ON t.inmate_id=m.inmate_id AND t.transfer_date=m.latest_date WHERE i.prison_id<>t.to_prison_id;

PROMPT 4. Audit completeness. These should return zero rows.
SELECT x.custody_id FROM CHAIN_OF_CUSTODY x WHERE NOT EXISTS (SELECT 1 FROM EVIDENCE_AUDIT a WHERE a.custody_id=x.custody_id AND a.evidence_id=x.evidence_id);
SELECT custody_id, COUNT(*) FROM EVIDENCE_AUDIT GROUP BY custody_id HAVING COUNT(*) <> 1;

PROMPT 4b. Recompile views that Stage 1 table changes left INVALID (Oracle normally recompiles lazily on first use).
ALTER VIEW CASE_SUMMARY_VIEW COMPILE;
ALTER VIEW V_CASE_COURT_SUMMARY COMPILE;

PROMPT 5. Required Stage 1 objects must be VALID and no compilation errors should be returned.
SELECT object_name, object_type, status FROM user_objects
WHERE object_name IN ('CASE_SUMMARY_VIEW','V_CASE_COURT_SUMMARY','TRG_CUSTODY_AUDIT',
 'TRG_CUSTODY_IMMUTABLE','TRG_EVIDENCE_AUDIT_IMMUTABLE','TRG_JUDGMENT_HEARING_GUARD',
 'TRG_HEARING_JUDGMENT_GUARD','TRG_FORENSIC_REPORT_ROLE','TRG_HEARING_JUDGE_ROLE',
 'TRG_CASE_INVESTIGATOR_ROLE','TRG_HEARING_PARTICIPANT_GUARD','TRG_SENTENCE_ACCUSED_GUARD',
 'GET_PRISON_OCCUPANCY','RELEASE_INMATE','TRANSFER_INMATE','TRANSFER_EVIDENCE','EVIDENCE_AUDIT_SEQ')
ORDER BY object_type, object_name;
SELECT name, type, line, position, text FROM user_errors ORDER BY name, sequence;

PROMPT 6. The Golden Case should produce exactly one result row.
SELECT c.case_number, c.case_id, e.evidence_id, j.judgment_id, j.hearing_id,
       i.inmate_id, i.status, i.prison_id, i.actual_release_date
FROM CASE_TABLE c
JOIN EVIDENCE e ON e.case_id=c.case_id
JOIN JUDGMENT j ON j.case_id=c.case_id
JOIN INMATE i ON i.sentence_id IN (SELECT s.sentence_id FROM SENTENCE s WHERE s.judgment_id=j.judgment_id)
WHERE c.case_number='GOLDEN-CASE-0001';


PROMPT 7. Stage 1 fail-fast acceptance gate.
DECLARE
  v_golden_inmate_id INMATE.inmate_id%TYPE;
  v_golden_custody_id CHAIN_OF_CUSTODY.custody_id%TYPE;
  v_golden_audit_id EVIDENCE_AUDIT.audit_id%TYPE;
  v_transfer_count_before NUMBER;
  v_transfer_count_after  NUMBER;
  v_seed_transfer_count   NUMBER;
  v_seed_transfer_count_after NUMBER;
  v_seed_prison_id        INMATE.prison_id%TYPE;
  v_seed_prison_after     INMATE.prison_id%TYPE;
  v_seed_status_after     INMATE.status%TYPE;
  v_seed_release_after    INMATE.actual_release_date%TYPE;
  v_evidence_custody_count NUMBER;
  v_evidence_custody_after NUMBER;
  v_test_custody_id       CHAIN_OF_CUSTODY.custody_id%TYPE;
  v_evidence7_custody_before NUMBER;
  v_evidence7_custody_after  NUMBER;
  v_judgment_count_before NUMBER;
  v_judgment_count_after  NUMBER;
  v_generic_count_before  NUMBER;
  v_generic_count_after   NUMBER;
  v_linked_hearing_status HEARING.hearing_status%TYPE;
  v_hearing_status_after  HEARING.hearing_status%TYPE;
  PROCEDURE assert_count(p_table_name IN VARCHAR2, p_expected IN NUMBER) IS
    v_actual NUMBER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || p_table_name INTO v_actual;
    IF v_actual <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20210,
        'Stage 1 row-count mismatch for ' || p_table_name || ': expected ' ||
        p_expected || ', found ' || v_actual);
    END IF;
  END assert_count;

  PROCEDURE assert_zero(p_query IN VARCHAR2, p_check_name IN VARCHAR2) IS
    v_actual NUMBER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM (' || p_query || ')' INTO v_actual;
    IF v_actual <> 0 THEN
      RAISE_APPLICATION_ERROR(-20211,
        'Stage 1 integrity check failed: ' || p_check_name || ' (' || v_actual || ' row(s))');
    END IF;
  END assert_zero;

  PROCEDURE assert_scalar(p_query IN VARCHAR2, p_expected IN NUMBER, p_check_name IN VARCHAR2) IS
    v_actual NUMBER;
  BEGIN
    EXECUTE IMMEDIATE p_query INTO v_actual;
    IF v_actual <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20212,
        'Stage 1 acceptance check failed: ' || p_check_name || ' expected ' ||
        p_expected || ', found ' || v_actual);
    END IF;
  END assert_scalar;

BEGIN
  assert_count('ROLE', 7);
  assert_count('DEPARTMENT', 5);
  assert_count('APP_USER', 15);
  assert_count('PERSON', 42);
  assert_count('CASE_TABLE', 16);
  assert_count('FIR', 16);
  assert_count('CASE_PERSON', 49);
  assert_count('INVESTIGATION', 16);
  assert_count('CASE_INVESTIGATOR', 18);
  assert_count('EVIDENCE', 37);
  assert_count('CHAIN_OF_CUSTODY', 56);
  assert_count('FORENSIC_REPORT', 30);
  assert_count('EVIDENCE_AUDIT', 56);
  assert_count('COURT', 4);
  assert_count('HEARING', 16);
  assert_count('HEARING_PARTICIPANT', 26);
  assert_count('JUDGMENT', 4);
  assert_count('LEGAL_PROVISION', 9);
  assert_count('CASE_PROVISION', 9);
  assert_count('SENTENCE', 4);
  assert_count('PRISON', 3);
  assert_count('INMATE', 3);
  assert_count('PRISON_TRANSFER', 3);

  assert_scalar('SELECT COUNT(*) FROM CASE_TABLE WHERE case_number=''GOLDEN-CASE-0001''', 1, 'Golden Case exists once');
  assert_zero('SELECT e.evidence_id FROM EVIDENCE e LEFT JOIN CASE_TABLE c ON c.case_id=e.case_id WHERE c.case_id IS NULL', 'evidence has valid case');
  assert_zero('SELECT x.custody_id FROM CHAIN_OF_CUSTODY x LEFT JOIN EVIDENCE e ON e.evidence_id=x.evidence_id WHERE e.evidence_id IS NULL', 'custody has valid evidence');
  assert_zero('SELECT fr.report_id FROM FORENSIC_REPORT fr LEFT JOIN EVIDENCE e ON e.evidence_id=fr.evidence_id WHERE e.evidence_id IS NULL', 'report has valid evidence');
  assert_zero('SELECT j.judgment_id FROM JUDGMENT j LEFT JOIN HEARING h ON h.hearing_id=j.hearing_id AND h.case_id=j.case_id WHERE h.hearing_id IS NULL', 'judgment points to hearing for same case');
  assert_zero('SELECT a.audit_id FROM EVIDENCE_AUDIT a LEFT JOIN CHAIN_OF_CUSTODY c ON c.custody_id=a.custody_id AND c.evidence_id=a.evidence_id WHERE c.custody_id IS NULL', 'audit has valid source custody');
  assert_zero('SELECT custody_id FROM EVIDENCE_AUDIT GROUP BY custody_id HAVING COUNT(*) <> 1', 'one audit row per custody event');
  assert_zero('SELECT c.custody_id FROM CHAIN_OF_CUSTODY c WHERE NOT EXISTS (SELECT 1 FROM EVIDENCE_AUDIT a WHERE a.custody_id=c.custody_id AND a.evidence_id=c.evidence_id)', 'all custody rows are audited');
  assert_zero('SELECT fr.report_id FROM FORENSIC_REPORT fr LEFT JOIN APP_USER u ON u.user_id=fr.forensic_officer_id LEFT JOIN ROLE r ON r.role_id=u.role_id WHERE r.role_name IS NULL OR r.role_name <> ''Forensic Officer''', 'forensic report user role');
  assert_zero('SELECT h.hearing_id FROM HEARING h LEFT JOIN APP_USER u ON u.user_id=h.judge_id LEFT JOIN ROLE r ON r.role_id=u.role_id WHERE r.role_name IS NULL OR r.role_name <> ''Judge''', 'hearing judge role');
  assert_zero('SELECT s.sentence_id FROM SENTENCE s JOIN JUDGMENT j ON j.judgment_id=s.judgment_id WHERE NOT EXISTS (SELECT 1 FROM CASE_PERSON cp WHERE cp.case_id=j.case_id AND cp.person_id=s.person_id AND cp.role_in_case=''ACCUSED'')', 'sentence person is accused in matching case');
  assert_zero('SELECT hp.hearing_participant_id FROM HEARING_PARTICIPANT hp JOIN HEARING h ON h.hearing_id=hp.hearing_id WHERE NOT EXISTS (SELECT 1 FROM CASE_PERSON cp WHERE cp.case_id=h.case_id AND cp.person_id=hp.person_id)', 'hearing participant belongs to case');
  assert_zero('SELECT hp.hearing_participant_id FROM HEARING_PARTICIPANT hp JOIN HEARING h ON h.hearing_id=hp.hearing_id LEFT JOIN CASE_PERSON cp ON cp.case_id=h.case_id AND cp.person_id=hp.person_id AND cp.role_in_case=hp.participant_role WHERE hp.participant_role IN (''ACCUSED'',''VICTIM'',''WITNESS'',''COMPLAINANT'',''OFFICIAL'') AND cp.case_person_id IS NULL', 'hearing participant role matches case-person role');
  assert_zero('SELECT c.evidence_id FROM EVIDENCE c JOIN (SELECT evidence_id, from_user_id, ROW_NUMBER() OVER (PARTITION BY evidence_id ORDER BY transfer_date_time, custody_id) rn FROM CHAIN_OF_CUSTODY) f ON f.evidence_id=c.evidence_id AND f.rn=1 WHERE f.from_user_id IS NULL OR f.from_user_id <> c.collected_by', 'first custody event begins with collector');
  assert_zero('SELECT evidence_id, custody_id FROM (SELECT c.evidence_id, c.custody_id, c.from_user_id, LAG(c.to_user_id) OVER (PARTITION BY c.evidence_id ORDER BY c.transfer_date_time, c.custody_id) previous_to_user_id FROM CHAIN_OF_CUSTODY c) WHERE previous_to_user_id IS NOT NULL AND (from_user_id IS NULL OR from_user_id <> previous_to_user_id)', 'chain-of-custody continuity');
  assert_zero('SELECT i.inmate_id FROM INMATE i JOIN (SELECT inmate_id, MAX(transfer_date) latest_date FROM PRISON_TRANSFER GROUP BY inmate_id) m ON m.inmate_id=i.inmate_id JOIN PRISON_TRANSFER t ON t.inmate_id=m.inmate_id AND t.transfer_date=m.latest_date WHERE i.prison_id<>t.to_prison_id', 'current prison equals last transfer destination');
  assert_zero('SELECT i.inmate_id FROM INMATE i WHERE (i.status=''RELEASED'' AND i.actual_release_date IS NULL) OR (i.status IN (''INCARCERATED'',''PAROLED'') AND i.actual_release_date IS NOT NULL)', 'inmate release state and date agree');

  assert_scalar('SELECT COUNT(*) FROM user_objects WHERE object_name IN (''CASE_SUMMARY_VIEW'',''V_CASE_COURT_SUMMARY'',''TRG_CUSTODY_AUDIT'',''TRG_CUSTODY_IMMUTABLE'',''TRG_EVIDENCE_AUDIT_IMMUTABLE'',''TRG_JUDGMENT_HEARING_GUARD'',''TRG_HEARING_JUDGMENT_GUARD'',''TRG_FORENSIC_REPORT_ROLE'',''TRG_HEARING_JUDGE_ROLE'',''TRG_CASE_INVESTIGATOR_ROLE'',''TRG_HEARING_PARTICIPANT_GUARD'',''TRG_SENTENCE_ACCUSED_GUARD'',''GET_PRISON_OCCUPANCY'',''RELEASE_INMATE'',''TRANSFER_INMATE'',''TRANSFER_EVIDENCE'') AND status=''VALID''', 16, 'all required views, triggers, functions and procedures are valid');
  assert_scalar('SELECT COUNT(*) FROM user_sequences WHERE sequence_name IN (''SEQ_ROLE'',''SEQ_DEPARTMENT'',''SEQ_APP_USER'',''SEQ_PERSON'',''SEQ_CASE_TABLE'',''SEQ_FIR'',''SEQ_CASE_PERSON'',''SEQ_INVESTIGATION'',''SEQ_CASE_INVESTIGATOR'',''SEQ_EVIDENCE'',''SEQ_CHAIN_OF_CUSTODY'',''SEQ_FORENSIC_REPORT'',''SEQ_COURT'',''SEQ_HEARING'',''SEQ_HEARING_PARTICIPANT'',''SEQ_JUDGMENT'',''SEQ_LEGAL_PROVISION'',''SEQ_CASE_PROVISION'',''SEQ_SENTENCE'',''SEQ_PRISON'',''SEQ_INMATE'',''SEQ_PRISON_TRANSFER'')', 22, 'all 22 application ID sequences exist');
  assert_scalar('SELECT COUNT(*) FROM user_sequences WHERE sequence_name=''EVIDENCE_AUDIT_SEQ''', 1, 'audit sequence exists');
  assert_zero('SELECT name FROM user_errors WHERE name IN (''CASE_SUMMARY_VIEW'',''V_CASE_COURT_SUMMARY'',''TRG_CUSTODY_AUDIT'',''TRG_CUSTODY_IMMUTABLE'',''TRG_EVIDENCE_AUDIT_IMMUTABLE'',''TRG_JUDGMENT_HEARING_GUARD'',''TRG_HEARING_JUDGMENT_GUARD'',''TRG_FORENSIC_REPORT_ROLE'',''TRG_HEARING_JUDGE_ROLE'',''TRG_CASE_INVESTIGATOR_ROLE'',''TRG_HEARING_PARTICIPANT_GUARD'',''TRG_SENTENCE_ACCUSED_GUARD'',''GET_PRISON_OCCUPANCY'',''RELEASE_INMATE'',''TRANSFER_INMATE'',''TRANSFER_EVIDENCE'')', 'no compiler errors in required database objects');
  assert_scalar('SELECT COUNT(*) FROM EVIDENCE_AUDIT a JOIN CHAIN_OF_CUSTODY c ON c.custody_id=a.custody_id WHERE c.evidence_id=(SELECT e.evidence_id FROM EVIDENCE e JOIN CASE_TABLE ca ON ca.case_id=e.case_id WHERE ca.case_number=''GOLDEN-CASE-0001'')', 2, 'Golden Case has two audited custody transfers');
  assert_zero('SELECT e.evidence_id FROM EVIDENCE e JOIN CASE_TABLE c ON c.case_id=e.case_id WHERE c.case_number=''GOLDEN-CASE-0001'' AND (e.current_status<>''RETURNED'' OR e.storage_location<>''Evidence Room A'')', 'Golden evidence status and storage location follow final custody event');
  assert_scalar('SELECT COUNT(*) FROM LEGAL_PROVISION WHERE provision_id=3 AND act_name=''Bharatiya Nyaya Sanhita, 2023'' AND section_number=''308'' AND description=''Extortion''', 1, 'post-effective-date extortion uses BNS section 308');
  assert_scalar('SELECT COUNT(*) FROM LEGAL_PROVISION WHERE provision_id=6 AND act_name=''Bharatiya Nyaya Sanhita, 2023'' AND section_number=''309'' AND description=''Robbery''', 1, 'post-effective-date robbery uses BNS section 309');
  assert_scalar('SELECT COUNT(*) FROM user_constraints WHERE constraint_name=''UQ_EA_CUSTODY_ID'' AND constraint_type=''U'' AND status=''ENABLED''', 1, 'one-to-one custody/audit unique constraint is enabled');

  SELECT i.inmate_id INTO v_golden_inmate_id
  FROM INMATE i JOIN SENTENCE s ON s.sentence_id=i.sentence_id
  JOIN JUDGMENT j ON j.judgment_id=s.judgment_id
  JOIN CASE_TABLE c ON c.case_id=j.case_id
  WHERE c.case_number='GOLDEN-CASE-0001';

  SELECT COUNT(*) INTO v_transfer_count_before
  FROM PRISON_TRANSFER WHERE inmate_id=v_golden_inmate_id;
  BEGIN
    TRANSFER_INMATE(v_golden_inmate_id, 1, TRUNC(SYSDATE), 'Expected rejection: released inmate');
    RAISE_APPLICATION_ERROR(-20213, 'Negative test failed: released inmate was transferred');
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE <> -20013 THEN RAISE; END IF;
  END;
  SELECT COUNT(*) INTO v_transfer_count_after
  FROM PRISON_TRANSFER WHERE inmate_id=v_golden_inmate_id;
  IF v_transfer_count_after <> v_transfer_count_before THEN
    RAISE_APPLICATION_ERROR(-20214, 'Rejected transfer changed transfer history');
  END IF;

  BEGIN
    RELEASE_INMATE(v_golden_inmate_id, TRUNC(SYSDATE));
    RAISE_APPLICATION_ERROR(-20215, 'Negative test failed: already-released inmate was released again');
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE <> -20023 THEN RAISE; END IF;
  END;

  SELECT MIN(x.custody_id) INTO v_golden_custody_id
  FROM CHAIN_OF_CUSTODY x
  JOIN EVIDENCE e ON e.evidence_id=x.evidence_id
  JOIN CASE_TABLE c ON c.case_id=e.case_id
  WHERE c.case_number='GOLDEN-CASE-0001';
  SAVEPOINT stage1_custody_immutable_sp;
  BEGIN
    UPDATE CHAIN_OF_CUSTODY SET remarks=remarks WHERE custody_id=v_golden_custody_id;
    RAISE_APPLICATION_ERROR(-20216, 'Negative test failed: custody history update was allowed');
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE <> -20031 THEN
        ROLLBACK TO stage1_custody_immutable_sp;
        RAISE;
      END IF;
  END;
  ROLLBACK TO stage1_custody_immutable_sp;

  SELECT MIN(a.audit_id) INTO v_golden_audit_id
  FROM EVIDENCE_AUDIT a
  JOIN CHAIN_OF_CUSTODY x ON x.custody_id=a.custody_id
  JOIN EVIDENCE e ON e.evidence_id=x.evidence_id
  JOIN CASE_TABLE c ON c.case_id=e.case_id
  WHERE c.case_number='GOLDEN-CASE-0001';
  SAVEPOINT stage1_audit_immutable_sp;
  BEGIN
    UPDATE EVIDENCE_AUDIT SET remarks=remarks WHERE audit_id=v_golden_audit_id;
    RAISE_APPLICATION_ERROR(-20218, 'Negative test failed: audit history update was allowed');
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE <> -20032 THEN
        ROLLBACK TO stage1_audit_immutable_sp;
        RAISE;
      END IF;
  END;
  ROLLBACK TO stage1_audit_immutable_sp;

  -- Date-order negative tests against seeded inmate 2, whose latest transfer was 2026-02-10.
  SELECT COUNT(*) INTO v_seed_transfer_count FROM PRISON_TRANSFER WHERE inmate_id=2;
  SELECT prison_id INTO v_seed_prison_id FROM INMATE WHERE inmate_id=2;
  BEGIN
    TRANSFER_INMATE(2, 3, DATE '2026-02-05', 'Negative test: transfer before latest history');
    RAISE_APPLICATION_ERROR(-20219, 'Negative test failed: out-of-order prison transfer was allowed');
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE <> -20029 THEN RAISE; END IF;
  END;
  SELECT COUNT(*) INTO v_seed_transfer_count_after FROM PRISON_TRANSFER WHERE inmate_id=2;
  SELECT prison_id INTO v_seed_prison_after FROM INMATE WHERE inmate_id=2;
  IF v_seed_transfer_count_after <> v_seed_transfer_count OR v_seed_prison_after <> v_seed_prison_id THEN
    RAISE_APPLICATION_ERROR(-20220, 'Rejected out-of-order transfer changed the inmate or transfer history');
  END IF;

  BEGIN
    RELEASE_INMATE(2, DATE '2026-02-05');
    RAISE_APPLICATION_ERROR(-20221, 'Negative test failed: release before latest transfer was allowed');
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE <> -20030 THEN RAISE; END IF;
  END;
  SELECT status, actual_release_date INTO v_seed_status_after, v_seed_release_after
  FROM INMATE WHERE inmate_id=2;
  IF v_seed_status_after <> 'INCARCERATED' OR v_seed_release_after IS NOT NULL THEN
    RAISE_APPLICATION_ERROR(-20222, 'Rejected out-of-order release changed inmate status');
  END IF;

  SELECT COUNT(*) INTO v_evidence_custody_count FROM CHAIN_OF_CUSTODY WHERE evidence_id=6;
  BEGIN
    TRANSFER_EVIDENCE(6, 1, SYSDATE, 'Evidence Room A', 'Evidence Room A', 'Negative test', 'Sealed',
                      'Disposed evidence must remain terminal', v_test_custody_id);
    RAISE_APPLICATION_ERROR(-20223, 'Negative test failed: disposed evidence was transferred');
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE <> -20064 THEN RAISE; END IF;
  END;
  SELECT COUNT(*) INTO v_evidence_custody_after FROM CHAIN_OF_CUSTODY WHERE evidence_id=6;
  IF v_evidence_custody_after <> v_evidence_custody_count THEN
    RAISE_APPLICATION_ERROR(-20224, 'Rejected transfer changed disposed evidence history');
  END IF;

  SELECT COUNT(*) INTO v_evidence7_custody_before FROM CHAIN_OF_CUSTODY WHERE evidence_id=7;
  BEGIN
    TRANSFER_EVIDENCE(7, 1, TO_DATE('2025-06-02 08:00','YYYY-MM-DD HH24:MI'),
                      'Evidence Room A', 'Evidence Room A', 'Negative test', 'Sealed',
                      'Out-of-order custody event must be rejected', v_test_custody_id);
    RAISE_APPLICATION_ERROR(-20227, 'Negative test failed: out-of-order evidence transfer was allowed');
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE <> -20066 THEN RAISE; END IF;
  END;
  SELECT COUNT(*) INTO v_evidence7_custody_after FROM CHAIN_OF_CUSTODY WHERE evidence_id=7;
  IF v_evidence7_custody_after <> v_evidence7_custody_before THEN
    RAISE_APPLICATION_ERROR(-20228, 'Rejected out-of-order evidence transfer changed custody history');
  END IF;

  SELECT COUNT(*) INTO v_judgment_count_before FROM JUDGMENT;
  BEGIN
    INSERT INTO JUDGMENT
      (judgment_id, case_id, hearing_id, judgment_date, verdict, judgment_summary)
    VALUES
      (99999, 2, 13, DATE '2026-11-18', 'Guilty', 'Negative test: hearing is only scheduled');
    RAISE_APPLICATION_ERROR(-20225, 'Negative test failed: judgment on a scheduled hearing was allowed');
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE <> -20081 THEN RAISE; END IF;
  END;
  SELECT COUNT(*) INTO v_judgment_count_after FROM JUDGMENT;
  IF v_judgment_count_after <> v_judgment_count_before THEN
    RAISE_APPLICATION_ERROR(-20226, 'Rejected judgment changed the judgment table');
  END IF;

  -- Role-guard negative tests: valid foreign keys are not sufficient if the account has the wrong role.
  SELECT COUNT(*) INTO v_generic_count_before FROM FORENSIC_REPORT;
  BEGIN
    INSERT INTO FORENSIC_REPORT (report_id,evidence_id,forensic_officer_id,examination_date,examination_details,result)
    VALUES (99998,1,1,SYSDATE,'Negative role test','Should be rejected: investigator is not a forensic officer');
    RAISE_APPLICATION_ERROR(-20229, 'Negative test failed: investigator was accepted as forensic officer');
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE <> -20090 THEN RAISE; END IF;
  END;
  SELECT COUNT(*) INTO v_generic_count_after FROM FORENSIC_REPORT;
  IF v_generic_count_after <> v_generic_count_before THEN
    RAISE_APPLICATION_ERROR(-20230, 'Rejected forensic-role insert changed report count');
  END IF;

  SELECT COUNT(*) INTO v_generic_count_before FROM HEARING;
  BEGIN
    INSERT INTO HEARING (hearing_id,case_id,court_id,judge_id,hearing_date,hearing_type,courtroom,hearing_status,proceedings)
    VALUES (9998,1,1,1,SYSDATE,'Negative role test','Test Room','SCHEDULED',NULL);
    RAISE_APPLICATION_ERROR(-20231, 'Negative test failed: investigator was accepted as hearing judge');
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE <> -20092 THEN RAISE; END IF;
  END;
  SELECT COUNT(*) INTO v_generic_count_after FROM HEARING;
  IF v_generic_count_after <> v_generic_count_before THEN
    RAISE_APPLICATION_ERROR(-20232, 'Rejected judge-role insert changed hearing count');
  END IF;

  SELECT COUNT(*) INTO v_generic_count_before FROM CASE_INVESTIGATOR;
  BEGIN
    INSERT INTO CASE_INVESTIGATOR (case_investigator_id,case_id,investigator_user_id,assigned_date,role_in_investigation)
    VALUES (99998,1,4,SYSDATE,'LEAD');
    RAISE_APPLICATION_ERROR(-20233, 'Negative test failed: judge was accepted as case investigator');
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE <> -20094 THEN RAISE; END IF;
  END;
  SELECT COUNT(*) INTO v_generic_count_after FROM CASE_INVESTIGATOR;
  IF v_generic_count_after <> v_generic_count_before THEN
    RAISE_APPLICATION_ERROR(-20234, 'Rejected investigator-role insert changed assignment count');
  END IF;

  SELECT COUNT(*) INTO v_generic_count_before FROM HEARING_PARTICIPANT;
  BEGIN
    INSERT INTO HEARING_PARTICIPANT (hearing_participant_id,hearing_id,person_id,participant_role)
    VALUES (99998,1,34,'WITNESS');
    RAISE_APPLICATION_ERROR(-20235, 'Negative test failed: participant role mismatch was accepted');
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE <> -20096 THEN RAISE; END IF;
  END;
  SELECT COUNT(*) INTO v_generic_count_after FROM HEARING_PARTICIPANT;
  IF v_generic_count_after <> v_generic_count_before THEN
    RAISE_APPLICATION_ERROR(-20236, 'Rejected participant-role insert changed participant count');
  END IF;

  SELECT COUNT(*) INTO v_generic_count_before FROM SENTENCE;
  BEGIN
    INSERT INTO SENTENCE (sentence_id,judgment_id,person_id,sentence_type,fine_amount,start_date)
    VALUES (99998,1,34,'Fine',100,SYSDATE);
    RAISE_APPLICATION_ERROR(-20237, 'Negative test failed: victim was accepted as sentenced accused');
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE <> -20098 THEN RAISE; END IF;
  END;
  SELECT COUNT(*) INTO v_generic_count_after FROM SENTENCE;
  IF v_generic_count_after <> v_generic_count_before THEN
    RAISE_APPLICATION_ERROR(-20238, 'Rejected sentence insert changed sentence count');
  END IF;

  SELECT hearing_status INTO v_linked_hearing_status FROM HEARING WHERE hearing_id=3;
  BEGIN
    UPDATE HEARING SET hearing_status='ADJOURNED' WHERE hearing_id=3;
    RAISE_APPLICATION_ERROR(-20239, 'Negative test failed: completed judgment hearing could be changed');
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE <> -20085 THEN RAISE; END IF;
  END;
  SELECT hearing_status INTO v_hearing_status_after FROM HEARING WHERE hearing_id=3;
  IF v_hearing_status_after <> v_linked_hearing_status THEN
    RAISE_APPLICATION_ERROR(-20240, 'Rejected hearing change altered linked hearing state');
  END IF;

  DBMS_OUTPUT.PUT_LINE('Stage 1 acceptance passed: counts, references, role guards, judgment guards, append-only history, evidence custody and prison lifecycle checks verified.');
END;
/