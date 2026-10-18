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
