-- UCJIMS Stage 0: repeatable read-only validation checks
-- Run with F5 in Oracle SQL Developer AFTER all files listed in STAGE0_BASELINE_RUNBOOK.md.
-- Most integrity queries should return zero rows. Compare actual row counts to the runbook.
-- This file does not insert/update/delete data and does not perform the trigger smoke test.

-- 1. Required application tables: expect exactly 23 rows from this query.
SELECT table_name
FROM user_tables
WHERE table_name IN (
 'ROLE','DEPARTMENT','APP_USER','PERSON','CASE_TABLE','FIR','CASE_PERSON','INVESTIGATION','CASE_INVESTIGATOR',
 'EVIDENCE','CHAIN_OF_CUSTODY','FORENSIC_REPORT','EVIDENCE_AUDIT','COURT','HEARING','HEARING_PARTICIPANT',
 'JUDGMENT','LEGAL_PROVISION','CASE_PROVISION','SENTENCE','PRISON','INMATE','PRISON_TRANSFER')
ORDER BY table_name;

-- 2. Table row counts. Expected values are documented in the runbook.
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

-- 3. Foreign-key-style orphan checks. Each query should return zero rows.
SELECT f.fir_id FROM FIR f LEFT JOIN CASE_TABLE c ON c.case_id=f.case_id WHERE c.case_id IS NULL;
SELECT f.fir_id FROM FIR f LEFT JOIN APP_USER u ON u.user_id=f.filed_by_user_id WHERE u.user_id IS NULL;
SELECT f.fir_id FROM FIR f LEFT JOIN PERSON p ON p.person_id=f.complainant_id WHERE p.person_id IS NULL;
SELECT cp.case_person_id FROM CASE_PERSON cp LEFT JOIN CASE_TABLE c ON c.case_id=cp.case_id WHERE c.case_id IS NULL;
SELECT cp.case_person_id FROM CASE_PERSON cp LEFT JOIN PERSON p ON p.person_id=cp.person_id WHERE p.person_id IS NULL;
SELECT i.investigation_id FROM INVESTIGATION i LEFT JOIN CASE_TABLE c ON c.case_id=i.case_id WHERE c.case_id IS NULL;
SELECT ci.case_investigator_id FROM CASE_INVESTIGATOR ci LEFT JOIN CASE_TABLE c ON c.case_id=ci.case_id WHERE c.case_id IS NULL;
SELECT ci.case_investigator_id FROM CASE_INVESTIGATOR ci LEFT JOIN APP_USER u ON u.user_id=ci.investigator_user_id WHERE u.user_id IS NULL;
SELECT e.evidence_id FROM EVIDENCE e LEFT JOIN CASE_TABLE c ON c.case_id=e.case_id WHERE c.case_id IS NULL;
SELECT e.evidence_id FROM EVIDENCE e LEFT JOIN APP_USER u ON u.user_id=e.collected_by WHERE e.collected_by IS NOT NULL AND u.user_id IS NULL;
SELECT x.custody_id FROM CHAIN_OF_CUSTODY x LEFT JOIN EVIDENCE e ON e.evidence_id=x.evidence_id WHERE e.evidence_id IS NULL;
SELECT x.custody_id FROM CHAIN_OF_CUSTODY x LEFT JOIN APP_USER u ON u.user_id=x.from_user_id WHERE x.from_user_id IS NOT NULL AND u.user_id IS NULL;
SELECT x.custody_id FROM CHAIN_OF_CUSTODY x LEFT JOIN APP_USER u ON u.user_id=x.to_user_id WHERE x.to_user_id IS NOT NULL AND u.user_id IS NULL;
SELECT f.report_id FROM FORENSIC_REPORT f LEFT JOIN EVIDENCE e ON e.evidence_id=f.evidence_id WHERE e.evidence_id IS NULL;
SELECT f.report_id FROM FORENSIC_REPORT f LEFT JOIN APP_USER u ON u.user_id=f.forensic_officer_id WHERE f.forensic_officer_id IS NOT NULL AND u.user_id IS NULL;
SELECT h.hearing_id FROM HEARING h LEFT JOIN CASE_TABLE c ON c.case_id=h.case_id WHERE c.case_id IS NULL;
SELECT h.hearing_id FROM HEARING h LEFT JOIN COURT c ON c.court_id=h.court_id WHERE h.court_id IS NOT NULL AND c.court_id IS NULL;
SELECT h.hearing_id FROM HEARING h LEFT JOIN APP_USER u ON u.user_id=h.judge_id WHERE h.judge_id IS NOT NULL AND u.user_id IS NULL;
SELECT hp.hearing_participant_id FROM HEARING_PARTICIPANT hp LEFT JOIN HEARING h ON h.hearing_id=hp.hearing_id WHERE h.hearing_id IS NULL;
SELECT hp.hearing_participant_id FROM HEARING_PARTICIPANT hp LEFT JOIN PERSON p ON p.person_id=hp.person_id WHERE p.person_id IS NULL;
SELECT j.judgment_id FROM JUDGMENT j LEFT JOIN CASE_TABLE c ON c.case_id=j.case_id WHERE c.case_id IS NULL;
SELECT cp.case_provision_id FROM CASE_PROVISION cp LEFT JOIN CASE_TABLE c ON c.case_id=cp.case_id WHERE c.case_id IS NULL;
SELECT cp.case_provision_id FROM CASE_PROVISION cp LEFT JOIN LEGAL_PROVISION lp ON lp.provision_id=cp.provision_id WHERE lp.provision_id IS NULL;
SELECT s.sentence_id FROM SENTENCE s LEFT JOIN JUDGMENT j ON j.judgment_id=s.judgment_id WHERE j.judgment_id IS NULL;
SELECT s.sentence_id FROM SENTENCE s LEFT JOIN PERSON p ON p.person_id=s.person_id WHERE p.person_id IS NULL;
SELECT i.inmate_id FROM INMATE i LEFT JOIN PERSON p ON p.person_id=i.person_id WHERE p.person_id IS NULL;
SELECT i.inmate_id FROM INMATE i LEFT JOIN PRISON p ON p.prison_id=i.prison_id WHERE p.prison_id IS NULL;
SELECT i.inmate_id FROM INMATE i LEFT JOIN SENTENCE s ON s.sentence_id=i.sentence_id WHERE i.sentence_id IS NOT NULL AND s.sentence_id IS NULL;
SELECT t.transfer_id FROM PRISON_TRANSFER t LEFT JOIN INMATE i ON i.inmate_id=t.inmate_id WHERE i.inmate_id IS NULL;
SELECT t.transfer_id FROM PRISON_TRANSFER t LEFT JOIN PRISON p ON p.prison_id=t.from_prison_id WHERE t.from_prison_id IS NOT NULL AND p.prison_id IS NULL;
SELECT t.transfer_id FROM PRISON_TRANSFER t LEFT JOIN PRISON p ON p.prison_id=t.to_prison_id WHERE t.to_prison_id IS NOT NULL AND p.prison_id IS NULL;

-- 4. Audit coverage checks. The schema's audit table has no FK constraints, so validate explicitly.
-- Both queries should return zero rows when the trigger captured every custody insert exactly once.
SELECT c.custody_id
FROM CHAIN_OF_CUSTODY c
WHERE NOT EXISTS (SELECT 1 FROM EVIDENCE_AUDIT a WHERE a.custody_id=c.custody_id AND a.evidence_id=c.evidence_id);
SELECT a.audit_id, a.custody_id, a.evidence_id
FROM EVIDENCE_AUDIT a
LEFT JOIN CHAIN_OF_CUSTODY c ON c.custody_id=a.custody_id AND c.evidence_id=a.evidence_id
WHERE c.custody_id IS NULL;
SELECT custody_id, COUNT(*) AS audit_rows
FROM EVIDENCE_AUDIT
GROUP BY custody_id
HAVING COUNT(*) <> 1;

-- 5. Data-quality checks. Review rows returned; do not silently discard exceptions.
SELECT evidence_id, current_status FROM EVIDENCE
WHERE current_status IS NULL OR current_status NOT IN ('COLLECTED','UNDER_EXAMINATION','RETURNED','DISPOSED');
SELECT f.report_id, f.evidence_id, f.examination_date, e.collection_date
FROM FORENSIC_REPORT f JOIN EVIDENCE e ON e.evidence_id=f.evidence_id
WHERE f.examination_date < e.collection_date;
SELECT x.custody_id, x.evidence_id, x.from_user_id, x.to_user_id
FROM CHAIN_OF_CUSTODY x WHERE x.from_user_id=x.to_user_id;
SELECT x.custody_id, x.transfer_date_time, e.collection_date
FROM CHAIN_OF_CUSTODY x JOIN EVIDENCE e ON e.evidence_id=x.evidence_id
WHERE x.transfer_date_time < e.collection_date;
SELECT t.transfer_id FROM PRISON_TRANSFER t WHERE t.from_prison_id=t.to_prison_id;
SELECT i.inmate_id, i.prison_id, t.to_prison_id, t.transfer_date
FROM INMATE i
JOIN (SELECT inmate_id, MAX(transfer_date) AS latest_date FROM PRISON_TRANSFER GROUP BY inmate_id) latest
  ON latest.inmate_id=i.inmate_id
JOIN PRISON_TRANSFER t ON t.inmate_id=latest.inmate_id AND t.transfer_date=latest.latest_date
WHERE i.prison_id<>t.to_prison_id;
SELECT inmate_id, status, admission_date, expected_release_date, actual_release_date
FROM INMATE
WHERE (status='RELEASED' AND actual_release_date IS NULL)
   OR (status='INCARCERATED' AND actual_release_date IS NOT NULL);

-- 6. Oracle object status and compiler diagnostics.
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN ('CASE_SUMMARY_VIEW','TRG_CUSTODY_AUDIT','EVIDENCE_AUDIT_SEQ',
                      'GET_PRISON_OCCUPANCY','RELEASE_INMATE','V_CASE_COURT_SUMMARY')
ORDER BY object_type, object_name;
SELECT name, type, line, position, text FROM user_errors ORDER BY name, sequence;

-- 7. Manual trigger smoke test (not performed by this read-only script).
-- ONLY in a disposable development schema: insert one CHAIN_OF_CUSTODY row using a unique ID,
-- valid EVIDENCE and two distinct APP_USER IDs. Confirm exactly one matching EVIDENCE_AUDIT row,
-- then ROLLBACK. Do not do this against production or shared data.


-- 8. Domain-role semantics. Each query should return zero rows.
-- A valid foreign key alone cannot prove the referenced account has the correct role.
SELECT fr.report_id, u.user_id, r.role_name
FROM FORENSIC_REPORT fr
JOIN APP_USER u ON u.user_id = fr.forensic_officer_id
JOIN ROLE r ON r.role_id = u.role_id
WHERE r.role_name <> 'Forensic Officer';

SELECT h.hearing_id, h.judge_id, r.role_name
FROM HEARING h
JOIN APP_USER u ON u.user_id = h.judge_id
JOIN ROLE r ON r.role_id = u.role_id
WHERE r.role_name <> 'Judge';

SELECT ci.case_investigator_id, ci.investigator_user_id, r.role_name
FROM CASE_INVESTIGATOR ci
JOIN APP_USER u ON u.user_id = ci.investigator_user_id
JOIN ROLE r ON r.role_id = u.role_id
WHERE r.role_name NOT IN ('Investigator','Cyber Crime Analyst');

SELECT s.sentence_id, s.person_id, j.case_id
FROM SENTENCE s
JOIN JUDGMENT j ON j.judgment_id=s.judgment_id
WHERE NOT EXISTS (
  SELECT 1 FROM CASE_PERSON cp
  WHERE cp.case_id=j.case_id AND cp.person_id=s.person_id AND cp.role_in_case='ACCUSED'
);

SELECT hp.hearing_participant_id, hp.hearing_id, hp.person_id, h.case_id
FROM HEARING_PARTICIPANT hp
JOIN HEARING h ON h.hearing_id=hp.hearing_id
WHERE NOT EXISTS (
  SELECT 1 FROM CASE_PERSON cp
  WHERE cp.case_id=h.case_id AND cp.person_id=hp.person_id
);


-- 9. Current-state/history consistency checks. Each query should return zero rows.
-- Under examination means no terminal return/disposal event has been recorded.
SELECT e.evidence_id, e.current_status
FROM EVIDENCE e
WHERE e.current_status = 'RETURNED'
  AND NOT EXISTS (
    SELECT 1 FROM CHAIN_OF_CUSTODY c
    WHERE c.evidence_id=e.evidence_id AND c.to_user_id=e.collected_by
      AND c.transfer_date_time = (SELECT MAX(c2.transfer_date_time) FROM CHAIN_OF_CUSTODY c2 WHERE c2.evidence_id=e.evidence_id)
  );
SELECT e.evidence_id, e.current_status
FROM EVIDENCE e
WHERE e.current_status = 'DISPOSED'
  AND NOT EXISTS (
    SELECT 1 FROM CHAIN_OF_CUSTODY c
    WHERE c.evidence_id=e.evidence_id AND c.to_user_id IS NULL
      AND c.condition = 'Disposed'
      AND c.transfer_date_time = (SELECT MAX(c2.transfer_date_time) FROM CHAIN_OF_CUSTODY c2 WHERE c2.evidence_id=e.evidence_id)
  );

SELECT e.evidence_id, e.current_status
FROM EVIDENCE e
JOIN (SELECT evidence_id, to_user_id, ROW_NUMBER() OVER (PARTITION BY evidence_id ORDER BY transfer_date_time DESC, custody_id DESC) rn
      FROM CHAIN_OF_CUSTODY) last_event
  ON last_event.evidence_id=e.evidence_id AND last_event.rn=1
LEFT JOIN APP_USER u ON u.user_id=last_event.to_user_id
LEFT JOIN ROLE r ON r.role_id=u.role_id
WHERE e.current_status='COLLECTED'
  AND (last_event.to_user_id IS NULL OR last_event.to_user_id=e.collected_by OR r.role_name='Forensic Officer');

SELECT e.evidence_id, c.to_user_id, r.role_name
FROM EVIDENCE e
JOIN CHAIN_OF_CUSTODY c ON c.evidence_id=e.evidence_id
LEFT JOIN APP_USER u ON u.user_id=c.to_user_id
LEFT JOIN ROLE r ON r.role_id=u.role_id
WHERE e.current_status='UNDER_EXAMINATION'
  AND c.transfer_date_time = (SELECT MAX(c2.transfer_date_time) FROM CHAIN_OF_CUSTODY c2 WHERE c2.evidence_id=e.evidence_id)
  AND (r.role_name IS NULL OR r.role_name <> 'Forensic Officer');


-- 10. Chain-of-custody sequence continuity. Each evidence history must start with its collector,
-- and each later sender must be the immediately preceding event's recipient.
SELECT e.evidence_id, e.collected_by, first_event.from_user_id
FROM EVIDENCE e
JOIN (
  SELECT evidence_id, from_user_id,
         ROW_NUMBER() OVER (PARTITION BY evidence_id ORDER BY transfer_date_time, custody_id) AS rn
  FROM CHAIN_OF_CUSTODY
) first_event ON first_event.evidence_id=e.evidence_id AND first_event.rn=1
WHERE first_event.from_user_id IS NULL OR first_event.from_user_id <> e.collected_by;

SELECT evidence_id, custody_id, from_user_id, previous_to_user_id
FROM (
  SELECT c.evidence_id, c.custody_id, c.from_user_id,
         LAG(c.to_user_id) OVER (PARTITION BY c.evidence_id ORDER BY c.transfer_date_time, c.custody_id) AS previous_to_user_id
  FROM CHAIN_OF_CUSTODY c
)
WHERE previous_to_user_id IS NOT NULL AND (from_user_id IS NULL OR from_user_id <> previous_to_user_id);

-- For every forensic report, require at least one earlier custody handoff to a Forensic Officer.
-- The result should be empty (the report date is stored without a time component).
SELECT fr.report_id, fr.evidence_id, fr.examination_date
FROM FORENSIC_REPORT fr
WHERE NOT EXISTS (
  SELECT 1
  FROM CHAIN_OF_CUSTODY c
  JOIN APP_USER u ON u.user_id=c.to_user_id
  JOIN ROLE r ON r.role_id=u.role_id
  WHERE c.evidence_id=fr.evidence_id
    AND r.role_name='Forensic Officer'
    AND c.transfer_date_time < fr.examination_date
);


-- 11. Fail-fast acceptance gate: expected counts and core integrity checks.
-- This block raises an Oracle application error if the baseline differs from the clean-schema fixture.
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

  PROCEDURE assert_zero(p_query IN VARCHAR2, p_check_name IN VARCHAR2) IS
    v_count NUMBER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM (' || p_query || ')' INTO v_count;
    IF v_count <> 0 THEN
      RAISE_APPLICATION_ERROR(-20101,
        'Stage 0 integrity check failed: ' || p_check_name || ' (' || v_count || ' row(s))');
    END IF;
  END assert_zero;

  PROCEDURE assert_scalar(p_query IN VARCHAR2, p_expected IN NUMBER, p_check_name IN VARCHAR2) IS
    v_actual NUMBER;
  BEGIN
    EXECUTE IMMEDIATE p_query INTO v_actual;
    IF v_actual <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20102,
        'Stage 0 acceptance check failed: ' || p_check_name || ' expected ' ||
        p_expected || ', found ' || v_actual);
    END IF;
  END assert_scalar;
BEGIN
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

  assert_zero('SELECT e.evidence_id FROM EVIDENCE e LEFT JOIN CASE_TABLE c ON c.case_id=e.case_id WHERE c.case_id IS NULL', 'evidence-to-case reference');
  assert_zero('SELECT x.custody_id FROM CHAIN_OF_CUSTODY x LEFT JOIN EVIDENCE e ON e.evidence_id=x.evidence_id WHERE e.evidence_id IS NULL', 'custody-to-evidence reference');
  assert_zero('SELECT f.report_id FROM FORENSIC_REPORT f LEFT JOIN EVIDENCE e ON e.evidence_id=f.evidence_id WHERE e.evidence_id IS NULL', 'report-to-evidence reference');
  assert_zero('SELECT a.audit_id FROM EVIDENCE_AUDIT a LEFT JOIN CHAIN_OF_CUSTODY c ON c.custody_id=a.custody_id AND c.evidence_id=a.evidence_id WHERE c.custody_id IS NULL', 'audit-to-custody reference');
  assert_zero('SELECT a.audit_id FROM EVIDENCE_AUDIT a LEFT JOIN EVIDENCE e ON e.evidence_id=a.evidence_id WHERE e.evidence_id IS NULL', 'audit-to-evidence reference');
  assert_zero('SELECT a.audit_id FROM EVIDENCE_AUDIT a LEFT JOIN APP_USER u ON u.user_id=a.from_user_id WHERE a.from_user_id IS NOT NULL AND u.user_id IS NULL', 'audit sender reference');
  assert_zero('SELECT a.audit_id FROM EVIDENCE_AUDIT a LEFT JOIN APP_USER u ON u.user_id=a.to_user_id WHERE a.to_user_id IS NOT NULL AND u.user_id IS NULL', 'audit receiver reference');
  assert_zero('SELECT c.custody_id FROM CHAIN_OF_CUSTODY c WHERE NOT EXISTS (SELECT 1 FROM EVIDENCE_AUDIT a WHERE a.custody_id=c.custody_id AND a.evidence_id=c.evidence_id)', 'missing custody audit');
  assert_zero('SELECT custody_id FROM EVIDENCE_AUDIT GROUP BY custody_id HAVING COUNT(*) <> 1', 'duplicate/missing audit rows');
  assert_zero('SELECT fr.report_id FROM FORENSIC_REPORT fr JOIN APP_USER u ON u.user_id=fr.forensic_officer_id JOIN ROLE r ON r.role_id=u.role_id WHERE r.role_name <> ''Forensic Officer''', 'forensic report assigned to wrong role');
  assert_zero('SELECT h.hearing_id FROM HEARING h JOIN APP_USER u ON u.user_id=h.judge_id JOIN ROLE r ON r.role_id=u.role_id WHERE r.role_name <> ''Judge''', 'hearing assigned to wrong judge role');
  assert_zero('SELECT s.sentence_id FROM SENTENCE s JOIN JUDGMENT j ON j.judgment_id=s.judgment_id WHERE NOT EXISTS (SELECT 1 FROM CASE_PERSON cp WHERE cp.case_id=j.case_id AND cp.person_id=s.person_id AND cp.role_in_case=''ACCUSED'')', 'sentence recipient is not an accused party of the judged case');
  assert_zero('SELECT hp.hearing_participant_id FROM HEARING_PARTICIPANT hp JOIN HEARING h ON h.hearing_id=hp.hearing_id WHERE NOT EXISTS (SELECT 1 FROM CASE_PERSON cp WHERE cp.case_id=h.case_id AND cp.person_id=hp.person_id)', 'hearing participant not associated with case');
  assert_zero('SELECT c.case_id FROM CASE_TABLE c WHERE c.incident_date IS NOT NULL AND c.incident_date > c.registration_date', 'case registration before incident date');
  assert_zero('SELECT i.investigation_id FROM INVESTIGATION i WHERE i.end_date IS NOT NULL AND i.end_date < i.start_date', 'investigation end before start');
  assert_zero('SELECT x.custody_id FROM CHAIN_OF_CUSTODY x JOIN EVIDENCE e ON e.evidence_id=x.evidence_id WHERE x.transfer_date_time < e.collection_date', 'custody before collection');
  assert_zero('SELECT fr.report_id FROM FORENSIC_REPORT fr JOIN EVIDENCE e ON e.evidence_id=fr.evidence_id WHERE fr.examination_date < e.collection_date', 'report before collection');
  assert_zero('SELECT x.custody_id FROM CHAIN_OF_CUSTODY x WHERE x.from_user_id=x.to_user_id', 'same sender and receiver');
  assert_zero('SELECT e.evidence_id FROM EVIDENCE e JOIN (SELECT evidence_id, from_user_id, ROW_NUMBER() OVER (PARTITION BY evidence_id ORDER BY transfer_date_time, custody_id) rn FROM CHAIN_OF_CUSTODY) f ON f.evidence_id=e.evidence_id AND f.rn=1 WHERE f.from_user_id IS NULL OR f.from_user_id <> e.collected_by', 'first custody sender differs from collector');
  assert_zero('SELECT evidence_id, custody_id FROM (SELECT c.evidence_id, c.custody_id, c.from_user_id, LAG(c.to_user_id) OVER (PARTITION BY c.evidence_id ORDER BY c.transfer_date_time, c.custody_id) previous_to_user_id FROM CHAIN_OF_CUSTODY c) WHERE previous_to_user_id IS NOT NULL AND (from_user_id IS NULL OR from_user_id <> previous_to_user_id)', 'custody chain has broken handoff continuity');
  assert_zero('SELECT e.evidence_id FROM EVIDENCE e WHERE e.current_status=''RETURNED'' AND NOT EXISTS (SELECT 1 FROM CHAIN_OF_CUSTODY c WHERE c.evidence_id=e.evidence_id AND c.to_user_id=e.collected_by AND c.transfer_date_time=(SELECT MAX(c2.transfer_date_time) FROM CHAIN_OF_CUSTODY c2 WHERE c2.evidence_id=e.evidence_id))', 'returned evidence missing return custody event');
  assert_zero('SELECT e.evidence_id FROM EVIDENCE e WHERE e.current_status=''DISPOSED'' AND NOT EXISTS (SELECT 1 FROM CHAIN_OF_CUSTODY c WHERE c.evidence_id=e.evidence_id AND c.to_user_id IS NULL AND c.condition=''Disposed'' AND c.transfer_date_time=(SELECT MAX(c2.transfer_date_time) FROM CHAIN_OF_CUSTODY c2 WHERE c2.evidence_id=e.evidence_id))', 'disposed evidence missing disposal event');
  assert_zero('SELECT e.evidence_id FROM EVIDENCE e JOIN CHAIN_OF_CUSTODY c ON c.evidence_id=e.evidence_id LEFT JOIN APP_USER u ON u.user_id=c.to_user_id LEFT JOIN ROLE r ON r.role_id=u.role_id WHERE e.current_status=''UNDER_EXAMINATION'' AND c.transfer_date_time=(SELECT MAX(c2.transfer_date_time) FROM CHAIN_OF_CUSTODY c2 WHERE c2.evidence_id=e.evidence_id) AND (r.role_name IS NULL OR r.role_name<>''Forensic Officer'')', 'evidence under examination not with a forensic officer');
  assert_zero('SELECT e.evidence_id FROM EVIDENCE e JOIN (SELECT evidence_id, to_user_id, ROW_NUMBER() OVER (PARTITION BY evidence_id ORDER BY transfer_date_time DESC, custody_id DESC) rn FROM CHAIN_OF_CUSTODY) x ON x.evidence_id=e.evidence_id AND x.rn=1 LEFT JOIN APP_USER u ON u.user_id=x.to_user_id LEFT JOIN ROLE r ON r.role_id=u.role_id WHERE e.current_status=''COLLECTED'' AND (x.to_user_id IS NULL OR x.to_user_id=e.collected_by OR r.role_name=''Forensic Officer'')', 'collected evidence is not already under examination/returned/disposed');
  assert_zero('SELECT fr.report_id FROM FORENSIC_REPORT fr WHERE NOT EXISTS (SELECT 1 FROM CHAIN_OF_CUSTODY c JOIN APP_USER u ON u.user_id=c.to_user_id JOIN ROLE r ON r.role_id=u.role_id WHERE c.evidence_id=fr.evidence_id AND r.role_name=''Forensic Officer'' AND c.transfer_date_time < fr.examination_date)', 'forensic report without prior forensic handoff');
  assert_zero('SELECT i.inmate_id FROM INMATE i JOIN (SELECT inmate_id, MAX(transfer_date) latest_date FROM PRISON_TRANSFER GROUP BY inmate_id) m ON m.inmate_id=i.inmate_id JOIN PRISON_TRANSFER t ON t.inmate_id=m.inmate_id AND t.transfer_date=m.latest_date WHERE i.prison_id<>t.to_prison_id', 'inmate current prison differs from latest transfer');
  assert_zero('SELECT fr.report_id FROM FORENSIC_REPORT fr LEFT JOIN APP_USER u ON u.user_id=fr.forensic_officer_id LEFT JOIN ROLE r ON r.role_id=u.role_id WHERE r.role_name IS NULL OR r.role_name <> ''Forensic Officer''', 'forensic report assigned to wrong role or missing officer');
  assert_zero('SELECT h.hearing_id FROM HEARING h LEFT JOIN APP_USER u ON u.user_id=h.judge_id LEFT JOIN ROLE r ON r.role_id=u.role_id WHERE r.role_name IS NULL OR r.role_name <> ''Judge''', 'hearing assigned to wrong or missing judge role');
  assert_scalar('SELECT COUNT(*) FROM user_objects WHERE object_name IN (''CASE_SUMMARY_VIEW'',''V_CASE_COURT_SUMMARY'',''TRG_CUSTODY_AUDIT'',''GET_PRISON_OCCUPANCY'',''RELEASE_INMATE'') AND status=''VALID''', 5, 'Stage 0 required views, trigger, function and procedure are valid');
  assert_scalar('SELECT COUNT(*) FROM user_sequences WHERE sequence_name=''EVIDENCE_AUDIT_SEQ''', 1, 'Stage 0 audit sequence exists');
  assert_zero('SELECT name FROM user_errors WHERE name IN (''CASE_SUMMARY_VIEW'',''V_CASE_COURT_SUMMARY'',''TRG_CUSTODY_AUDIT'',''GET_PRISON_OCCUPANCY'',''RELEASE_INMATE'')', 'Stage 0 required objects have no compilation errors');

  DBMS_OUTPUT.PUT_LINE('Stage 0 assertions passed: clean-schema row counts and core integrity checks match.');
END;
/
