-- UCJIMS Stage 0 fail-fast acceptance gate.
-- Run only after all Stage 0 tables, seed data, integration demo, additional Person B data,
-- query/view/function/procedure scripts, and stage0_database_validation.sql.
-- This is read-only; any failed acceptance condition raises an application error.

SET SERVEROUTPUT ON;
PROMPT Stage 0 acceptance gate: validate fresh synthetic baseline.

DECLARE
  PROCEDURE assert_count(p_table_name IN VARCHAR2, p_expected IN NUMBER) IS
    v_actual NUMBER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || p_table_name INTO v_actual;
    IF v_actual <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20100,
        'Stage 0 row-count mismatch for ' || p_table_name || ': expected ' ||
        p_expected || ', found ' || v_actual);
    END IF;
  END assert_count;

  PROCEDURE assert_scalar(p_query IN VARCHAR2, p_expected IN NUMBER, p_label IN VARCHAR2) IS
    v_actual NUMBER;
  BEGIN
    EXECUTE IMMEDIATE p_query INTO v_actual;
    IF v_actual <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20101,
        'Stage 0 acceptance check failed: ' || p_label || '; expected ' ||
        p_expected || ', found ' || v_actual);
    END IF;
  END assert_scalar;

  PROCEDURE assert_zero(p_query IN VARCHAR2, p_label IN VARCHAR2) IS
    v_actual NUMBER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM (' || p_query || ')' INTO v_actual;
    IF v_actual <> 0 THEN
      RAISE_APPLICATION_ERROR(-20102,
        'Stage 0 integrity check failed: ' || p_label || ' (' || v_actual || ' row(s))');
    END IF;
  END assert_zero;
BEGIN
  assert_scalar(
    'SELECT COUNT(*) FROM user_tables WHERE table_name IN (' ||
    '''ROLE'',''DEPARTMENT'',''APP_USER'',''PERSON'',''CASE_TABLE'',''FIR'',''CASE_PERSON'',' ||
    '''INVESTIGATION'',''CASE_INVESTIGATOR'',''EVIDENCE'',''CHAIN_OF_CUSTODY'',''FORENSIC_REPORT'',' ||
    '''EVIDENCE_AUDIT'',''COURT'',''HEARING'',''HEARING_PARTICIPANT'',''JUDGMENT'',''LEGAL_PROVISION'',' ||
    '''CASE_PROVISION'',''SENTENCE'',''PRISON'',''INMATE'',''PRISON_TRANSFER'')',
    23, 'all 23 application tables exist');

  assert_count('ROLE', 7);
  assert_count('DEPARTMENT', 5);
  assert_count('APP_USER', 15);
  assert_count('PERSON', 40);
  assert_count('CASE_TABLE', 15);
  assert_count('FIR', 15);
  assert_count('CASE_PERSON', 47);
  assert_count('INVESTIGATION', 15);
  assert_count('CASE_INVESTIGATOR', 17);
  assert_count('EVIDENCE', 36);
  assert_count('CHAIN_OF_CUSTODY', 54);
  assert_count('FORENSIC_REPORT', 29);
  assert_count('EVIDENCE_AUDIT', 54);
  assert_count('COURT', 4);
  assert_count('HEARING', 15);
  assert_count('HEARING_PARTICIPANT', 24);
  assert_count('JUDGMENT', 3);
  assert_count('LEGAL_PROVISION', 8);
  assert_count('CASE_PROVISION', 8);
  assert_count('SENTENCE', 3);
  assert_count('PRISON', 3);
  assert_count('INMATE', 2);
  assert_count('PRISON_TRANSFER', 2);

  assert_zero('SELECT f.fir_id FROM FIR f LEFT JOIN CASE_TABLE c ON c.case_id=f.case_id WHERE c.case_id IS NULL', 'FIR case references');
  assert_zero('SELECT f.fir_id FROM FIR f LEFT JOIN APP_USER u ON u.user_id=f.filed_by_user_id WHERE u.user_id IS NULL', 'FIR filing-user references');
  assert_zero('SELECT f.fir_id FROM FIR f LEFT JOIN PERSON p ON p.person_id=f.complainant_id WHERE p.person_id IS NULL', 'FIR complainant references');
  assert_zero('SELECT cp.case_person_id FROM CASE_PERSON cp LEFT JOIN CASE_TABLE c ON c.case_id=cp.case_id WHERE c.case_id IS NULL', 'case-person case references');
  assert_zero('SELECT cp.case_person_id FROM CASE_PERSON cp LEFT JOIN PERSON p ON p.person_id=cp.person_id WHERE p.person_id IS NULL', 'case-person person references');
  assert_zero('SELECT i.investigation_id FROM INVESTIGATION i LEFT JOIN CASE_TABLE c ON c.case_id=i.case_id WHERE c.case_id IS NULL OR (i.end_date IS NOT NULL AND i.end_date<i.start_date)', 'investigation references/date order');
  assert_zero('SELECT ci.case_investigator_id FROM CASE_INVESTIGATOR ci LEFT JOIN CASE_TABLE c ON c.case_id=ci.case_id LEFT JOIN APP_USER u ON u.user_id=ci.investigator_user_id LEFT JOIN ROLE r ON r.role_id=u.role_id WHERE c.case_id IS NULL OR u.user_id IS NULL OR r.role_name NOT IN (''Investigator'',''Cyber Crime Analyst'')', 'case investigator references/role');
  assert_zero('SELECT c.case_id FROM CASE_TABLE c WHERE c.incident_date IS NOT NULL AND c.registration_date<c.incident_date', 'case registration after incident');
  assert_zero('SELECT e.evidence_id FROM EVIDENCE e LEFT JOIN CASE_TABLE c ON c.case_id=e.case_id LEFT JOIN APP_USER u ON u.user_id=e.collected_by WHERE c.case_id IS NULL OR u.user_id IS NULL', 'evidence case/collector references');
  assert_zero('SELECT x.custody_id FROM CHAIN_OF_CUSTODY x LEFT JOIN EVIDENCE e ON e.evidence_id=x.evidence_id LEFT JOIN APP_USER f ON f.user_id=x.from_user_id LEFT JOIN APP_USER t ON t.user_id=x.to_user_id WHERE e.evidence_id IS NULL OR f.user_id IS NULL OR (x.to_user_id IS NOT NULL AND t.user_id IS NULL) OR x.from_user_id=x.to_user_id', 'custody evidence/users and sender/recipient');
  assert_zero('SELECT fr.report_id FROM FORENSIC_REPORT fr LEFT JOIN EVIDENCE e ON e.evidence_id=fr.evidence_id LEFT JOIN APP_USER u ON u.user_id=fr.forensic_officer_id LEFT JOIN ROLE r ON r.role_id=u.role_id WHERE e.evidence_id IS NULL OR u.user_id IS NULL OR r.role_name<>''Forensic Officer'' OR fr.examination_date<e.collection_date', 'forensic report references/role/date');
  assert_zero('SELECT h.hearing_id FROM HEARING h LEFT JOIN CASE_TABLE c ON c.case_id=h.case_id LEFT JOIN COURT ct ON ct.court_id=h.court_id LEFT JOIN APP_USER u ON u.user_id=h.judge_id LEFT JOIN ROLE r ON r.role_id=u.role_id WHERE c.case_id IS NULL OR (h.court_id IS NOT NULL AND ct.court_id IS NULL) OR (h.judge_id IS NOT NULL AND (u.user_id IS NULL OR r.role_name<>''Judge''))', 'hearing references/judge role');
  assert_zero('SELECT hp.hearing_participant_id FROM HEARING_PARTICIPANT hp LEFT JOIN HEARING h ON h.hearing_id=hp.hearing_id LEFT JOIN PERSON p ON p.person_id=hp.person_id WHERE h.hearing_id IS NULL OR p.person_id IS NULL OR NOT EXISTS (SELECT 1 FROM CASE_PERSON cp WHERE cp.case_id=h.case_id AND cp.person_id=hp.person_id)', 'hearing participants belong to hearing case');
  assert_zero('SELECT j.judgment_id FROM JUDGMENT j LEFT JOIN CASE_TABLE c ON c.case_id=j.case_id WHERE c.case_id IS NULL', 'judgment case references');
  assert_zero('SELECT cp.case_provision_id FROM CASE_PROVISION cp LEFT JOIN CASE_TABLE c ON c.case_id=cp.case_id LEFT JOIN LEGAL_PROVISION lp ON lp.provision_id=cp.provision_id WHERE c.case_id IS NULL OR lp.provision_id IS NULL', 'case-provision references');
  assert_zero('SELECT s.sentence_id FROM SENTENCE s LEFT JOIN JUDGMENT j ON j.judgment_id=s.judgment_id LEFT JOIN PERSON p ON p.person_id=s.person_id WHERE j.judgment_id IS NULL OR p.person_id IS NULL OR NOT EXISTS (SELECT 1 FROM CASE_PERSON cp WHERE cp.case_id=j.case_id AND cp.person_id=s.person_id AND cp.role_in_case=''ACCUSED'') OR (s.start_date IS NOT NULL AND s.end_date IS NOT NULL AND s.end_date<s.start_date) OR s.fine_amount<0', 'sentence references/date/recipient');
  assert_zero('SELECT i.inmate_id FROM INMATE i LEFT JOIN PERSON p ON p.person_id=i.person_id LEFT JOIN PRISON pr ON pr.prison_id=i.prison_id LEFT JOIN SENTENCE s ON s.sentence_id=i.sentence_id WHERE p.person_id IS NULL OR pr.prison_id IS NULL OR (i.sentence_id IS NOT NULL AND s.sentence_id IS NULL) OR (i.expected_release_date IS NOT NULL AND i.expected_release_date<i.admission_date) OR (i.actual_release_date IS NOT NULL AND i.actual_release_date<i.admission_date) OR (i.status=''RELEASED'' AND i.actual_release_date IS NULL) OR (i.status IN (''INCARCERATED'',''PAROLED'') AND i.actual_release_date IS NOT NULL)', 'inmate references/release state');
  assert_zero('SELECT t.transfer_id FROM PRISON_TRANSFER t LEFT JOIN INMATE i ON i.inmate_id=t.inmate_id LEFT JOIN PRISON f ON f.prison_id=t.from_prison_id LEFT JOIN PRISON p ON p.prison_id=t.to_prison_id WHERE i.inmate_id IS NULL OR f.prison_id IS NULL OR p.prison_id IS NULL OR t.from_prison_id=t.to_prison_id OR t.transfer_date<i.admission_date', 'prison transfer references/date');
  assert_zero('SELECT a.audit_id FROM EVIDENCE_AUDIT a LEFT JOIN CHAIN_OF_CUSTODY c ON c.custody_id=a.custody_id AND c.evidence_id=a.evidence_id LEFT JOIN APP_USER f ON f.user_id=a.from_user_id LEFT JOIN APP_USER t ON t.user_id=a.to_user_id WHERE c.custody_id IS NULL OR f.user_id IS NULL OR (a.to_user_id IS NOT NULL AND t.user_id IS NULL)', 'audit source/user references');
  assert_zero('SELECT c.custody_id FROM CHAIN_OF_CUSTODY c WHERE NOT EXISTS (SELECT 1 FROM EVIDENCE_AUDIT a WHERE a.custody_id=c.custody_id AND a.evidence_id=c.evidence_id)', 'every custody event audited');
  assert_zero('SELECT custody_id FROM EVIDENCE_AUDIT GROUP BY custody_id HAVING COUNT(*)<>1', 'exactly one audit row per custody event');
  assert_zero('SELECT c.custody_id FROM CHAIN_OF_CUSTODY c JOIN EVIDENCE e ON e.evidence_id=c.evidence_id WHERE c.transfer_date_time<e.collection_date', 'custody never predates collection');
  assert_zero('SELECT fr.report_id FROM FORENSIC_REPORT fr JOIN EVIDENCE e ON e.evidence_id=fr.evidence_id WHERE fr.examination_date<e.collection_date', 'examination never predates collection');
  assert_zero('SELECT e.evidence_id FROM EVIDENCE e JOIN (SELECT evidence_id, from_user_id, ROW_NUMBER() OVER (PARTITION BY evidence_id ORDER BY transfer_date_time, custody_id) rn FROM CHAIN_OF_CUSTODY) first_event ON first_event.evidence_id=e.evidence_id AND first_event.rn=1 WHERE first_event.from_user_id<>e.collected_by OR first_event.from_user_id IS NULL', 'first custody event starts with collector');
  assert_zero('SELECT custody_id FROM (SELECT custody_id, evidence_id, from_user_id, transfer_date_time, LAG(to_user_id) OVER (PARTITION BY evidence_id ORDER BY transfer_date_time,custody_id) previous_to_user, LAG(transfer_date_time) OVER (PARTITION BY evidence_id ORDER BY transfer_date_time,custody_id) previous_time FROM CHAIN_OF_CUSTODY) WHERE previous_time IS NOT NULL AND (previous_to_user IS NULL OR from_user_id<>previous_to_user OR transfer_date_time<=previous_time)', 'custody chain is chronological and continuous');
  assert_zero('SELECT e.evidence_id FROM EVIDENCE e JOIN (SELECT c.evidence_id,c.to_user_id,c.condition,ROW_NUMBER() OVER(PARTITION BY c.evidence_id ORDER BY c.transfer_date_time DESC,c.custody_id DESC) rn FROM CHAIN_OF_CUSTODY c) x ON x.evidence_id=e.evidence_id AND x.rn=1 LEFT JOIN APP_USER u ON u.user_id=x.to_user_id LEFT JOIN ROLE r ON r.role_id=u.role_id WHERE (x.to_user_id IS NULL AND (e.current_status<>''DISPOSED'' OR e.storage_location IS NOT NULL OR x.condition<>''Disposed'')) OR (x.to_user_id=e.collected_by AND e.current_status<>''RETURNED'') OR (x.to_user_id IS NOT NULL AND x.to_user_id<>e.collected_by AND r.role_name=''Forensic Officer'' AND e.current_status<>''UNDER_EXAMINATION'') OR (x.to_user_id IS NOT NULL AND x.to_user_id<>e.collected_by AND NVL(r.role_name,''?'')<>''Forensic Officer'' AND e.current_status<>''COLLECTED'')', 'evidence current status matches the final custody event');
  assert_zero('SELECT e.evidence_id FROM EVIDENCE e JOIN (SELECT evidence_id, to_user_id, ROW_NUMBER() OVER (PARTITION BY evidence_id ORDER BY transfer_date_time DESC, custody_id DESC) rn FROM CHAIN_OF_CUSTODY) last_event ON last_event.evidence_id=e.evidence_id AND last_event.rn=1 WHERE last_event.to_user_id IS NULL AND e.current_status<>''DISPOSED''', 'disposed items have terminal disposal event');

  assert_scalar('SELECT COUNT(*) FROM user_objects WHERE object_name IN (''CASE_SUMMARY_VIEW'',''V_CASE_COURT_SUMMARY'',''TRG_CUSTODY_AUDIT'',''GET_PRISON_OCCUPANCY'',''RELEASE_INMATE'') AND status=''VALID''', 5, 'Stage 0 views, trigger, function and procedure are valid');
  assert_scalar('SELECT COUNT(*) FROM user_sequences WHERE sequence_name=''EVIDENCE_AUDIT_SEQ''', 1, 'evidence audit sequence exists');
  assert_zero('SELECT name FROM user_errors WHERE name IN (''CASE_SUMMARY_VIEW'',''V_CASE_COURT_SUMMARY'',''TRG_CUSTODY_AUDIT'',''GET_PRISON_OCCUPANCY'',''RELEASE_INMATE'')', 'no Stage 0 PL/SQL/view compilation errors');

  DBMS_OUTPUT.PUT_LINE('STAGE 0 PASS: table counts, links, evidence histories, audit completeness and base objects all meet the baseline.');
END;
/
