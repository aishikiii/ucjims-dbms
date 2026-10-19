-- UCJIMS Stage 1: synthetic end-to-end GOLDEN_CASE fixture.
-- Run only after Stage 1 hardening, sequences and workflows have compiled.
-- Uses generated IDs; fixed business keys prevent accidental duplicate fixture creation.
-- All people, case facts and outcomes below are fictitious test data.

SET SERVEROUTPUT ON;

DECLARE
  v_count                 NUMBER;
  v_case_id               CASE_TABLE.case_id%TYPE;
  v_accused_id            PERSON.person_id%TYPE;
  v_complainant_id        PERSON.person_id%TYPE;
  v_fir_id                FIR.fir_id%TYPE;
  v_case_person_id        CASE_PERSON.case_person_id%TYPE;
  v_investigation_id      INVESTIGATION.investigation_id%TYPE;
  v_case_investigator_id  CASE_INVESTIGATOR.case_investigator_id%TYPE;
  v_evidence_id           EVIDENCE.evidence_id%TYPE;
  v_custody_out_id        CHAIN_OF_CUSTODY.custody_id%TYPE;
  v_custody_return_id     CHAIN_OF_CUSTODY.custody_id%TYPE;
  v_report_id             FORENSIC_REPORT.report_id%TYPE;
  v_hearing_id            HEARING.hearing_id%TYPE;
  v_participant_id        HEARING_PARTICIPANT.hearing_participant_id%TYPE;
  v_provision_id          LEGAL_PROVISION.provision_id%TYPE;
  v_case_provision_id     CASE_PROVISION.case_provision_id%TYPE;
  v_judgment_id           JUDGMENT.judgment_id%TYPE;
  v_sentence_id           SENTENCE.sentence_id%TYPE;
  v_inmate_id             INMATE.inmate_id%TYPE;
  v_incident_date         DATE := TRUNC(SYSDATE) - 600;
  v_registration_date     DATE;
  v_collection_date       DATE;
  v_hearing_date          DATE;
  v_sentence_start_date   DATE;
  v_expected_release_date DATE;
BEGIN
  SAVEPOINT golden_case_sp;

  SELECT COUNT(*) INTO v_count
  FROM CASE_TABLE
  WHERE case_number = 'GOLDEN-CASE-0001';
  IF v_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20041,
      'GOLDEN-CASE-0001 already exists; do not execute the fixture twice.');
  END IF;

  v_registration_date := v_incident_date + 1;
  v_collection_date := v_incident_date + 2;
  v_hearing_date := v_incident_date + 40;
  v_sentence_start_date := v_hearing_date + 1;
  v_expected_release_date := v_sentence_start_date + 540;

  -- A: case registration, people, FIR and investigation.
  v_accused_id := SEQ_PERSON.NEXTVAL;
  INSERT INTO PERSON (person_id, full_name, date_of_birth, gender, contact_info, address, identification_no)
  VALUES (v_accused_id, 'Golden Demo Accused', DATE '1990-01-01', 'Unknown', NULL,
          'Synthetic test location', 'GOLDEN-ACC-0001');

  v_complainant_id := SEQ_PERSON.NEXTVAL;
  INSERT INTO PERSON (person_id, full_name, date_of_birth, gender, contact_info, address, identification_no)
  VALUES (v_complainant_id, 'Golden Demo Complainant', DATE '1992-01-01', 'Unknown', NULL,
          'Synthetic test location', 'GOLDEN-COMP-0001');

  v_case_id := SEQ_CASE_TABLE.NEXTVAL;
  INSERT INTO CASE_TABLE
    (case_id, case_number, case_type, registration_date, incident_date, incident_location,
     description, case_status, priority)
  VALUES
    (v_case_id, 'GOLDEN-CASE-0001', 'Theft', v_registration_date, v_incident_date,
     'Synthetic Demo Location', 'GOLDEN_CASE: synthetic end-to-end database validation fixture',
     'CLOSED', 'MEDIUM');

  v_fir_id := SEQ_FIR.NEXTVAL;
  INSERT INTO FIR
    (fir_id, case_id, filed_by_user_id, complainant_id, fir_number, filing_date, station_name, fir_details)
  VALUES
    (v_fir_id, v_case_id, 1, v_complainant_id, 'GOLDEN-FIR-0001', v_registration_date,
     'Synthetic Demo Station', 'Fictitious FIR for database integration testing only');

  v_case_person_id := SEQ_CASE_PERSON.NEXTVAL;
  INSERT INTO CASE_PERSON (case_person_id, case_id, person_id, role_in_case, remarks)
  VALUES (v_case_person_id, v_case_id, v_accused_id, 'ACCUSED', 'Synthetic golden-case accused');

  v_case_person_id := SEQ_CASE_PERSON.NEXTVAL;
  INSERT INTO CASE_PERSON (case_person_id, case_id, person_id, role_in_case, remarks)
  VALUES (v_case_person_id, v_case_id, v_complainant_id, 'COMPLAINANT', 'Synthetic golden-case complainant');

  v_case_investigator_id := SEQ_CASE_INVESTIGATOR.NEXTVAL;
  INSERT INTO CASE_INVESTIGATOR
    (case_investigator_id, case_id, investigator_user_id, assigned_date, role_in_investigation)
  VALUES (v_case_investigator_id, v_case_id, 1, v_registration_date, 'LEAD');

  v_investigation_id := SEQ_INVESTIGATION.NEXTVAL;
  INSERT INTO INVESTIGATION
    (investigation_id, case_id, start_date, end_date, status, findings)
  VALUES (v_investigation_id, v_case_id, v_incident_date, v_hearing_date - 5,
          'COMPLETED', 'Synthetic findings entered for Golden Case integration test');

  -- B: evidence, custody history and forensic report. The trigger must audit both transfers.
  v_evidence_id := SEQ_EVIDENCE.NEXTVAL;
  INSERT INTO EVIDENCE
    (evidence_id, case_id, evidence_type, description, collection_date, collection_location,
     collected_by, storage_location, current_status)
  VALUES (v_evidence_id, v_case_id, 'Physical', 'Synthetic tool-mark sample', v_collection_date,
          'Synthetic Demo Location', 1, 'Evidence Room A', 'COLLECTED');

  TRANSFER_EVIDENCE(
    v_evidence_id, 8, v_collection_date + 1, 'Forensic Lab 1', 'Forensic Lab 1',
    'Forensic examination', 'Sealed', 'Synthetic transfer to forensic officer',
    v_custody_out_id);

  v_report_id := SEQ_FORENSIC_REPORT.NEXTVAL;
  INSERT INTO FORENSIC_REPORT
    (report_id, evidence_id, forensic_officer_id, examination_date, examination_details, result)
  VALUES (v_report_id, v_evidence_id, 8, v_collection_date + 3,
          'Synthetic tool-mark comparison', 'Synthetic test result; not a real forensic conclusion');

  TRANSFER_EVIDENCE(
    v_evidence_id, 1, v_collection_date + 5, 'Evidence Room A', 'Evidence Room A',
    'Return after forensic examination', 'Sealed',
    'Synthetic return transfer to investigating officer', v_custody_return_id);

  -- C: hearing, legal provision, judgment, sentence and prison lifecycle.
  v_hearing_id := SEQ_HEARING.NEXTVAL;
  INSERT INTO HEARING
    (hearing_id, case_id, court_id, judge_id, hearing_date, hearing_type,
     courtroom, hearing_status, proceedings)
  VALUES (v_hearing_id, v_case_id, 2, 4, v_hearing_date, 'Judgment Hearing',
          'Synthetic Court Room', 'COMPLETED', 'Synthetic proceedings for database validation only');

  v_participant_id := SEQ_HEARING_PARTICIPANT.NEXTVAL;
  INSERT INTO HEARING_PARTICIPANT (hearing_participant_id, hearing_id, person_id, participant_role)
  VALUES (v_participant_id, v_hearing_id, v_accused_id, 'ACCUSED');

  v_participant_id := SEQ_HEARING_PARTICIPANT.NEXTVAL;
  INSERT INTO HEARING_PARTICIPANT (hearing_participant_id, hearing_id, person_id, participant_role)
  VALUES (v_participant_id, v_hearing_id, v_complainant_id, 'COMPLAINANT');

  v_provision_id := SEQ_LEGAL_PROVISION.NEXTVAL;
  INSERT INTO LEGAL_PROVISION (provision_id, act_name, section_number, description)
  VALUES (v_provision_id, 'Bharatiya Nyaya Sanhita, 2023', '303(2)',
          'Theft and punishment provision; synthetic demo mapping');

  v_case_provision_id := SEQ_CASE_PROVISION.NEXTVAL;
  INSERT INTO CASE_PROVISION (case_provision_id, case_id, provision_id)
  VALUES (v_case_provision_id, v_case_id, v_provision_id);

  v_judgment_id := SEQ_JUDGMENT.NEXTVAL;
  INSERT INTO JUDGMENT
    (judgment_id, case_id, hearing_id, judgment_date, verdict, judgment_summary)
  VALUES (v_judgment_id, v_case_id, v_hearing_id, v_hearing_date, 'Guilty',
          'Synthetic judgment created solely to test relational integration');

  v_sentence_id := SEQ_SENTENCE.NEXTVAL;
  INSERT INTO SENTENCE
    (sentence_id, judgment_id, person_id, sentence_type, duration, fine_amount, start_date, end_date)
  VALUES (v_sentence_id, v_judgment_id, v_accused_id, 'Imprisonment', 'Approx. 18 months', NULL,
          v_sentence_start_date, v_expected_release_date);

  v_inmate_id := SEQ_INMATE.NEXTVAL;
  INSERT INTO INMATE
    (inmate_id, person_id, prison_id, sentence_id, admission_date,
     expected_release_date, actual_release_date, status)
  VALUES (v_inmate_id, v_accused_id, 1, v_sentence_id, v_sentence_start_date + 1,
          v_expected_release_date, NULL, 'INCARCERATED');

  TRANSFER_INMATE(v_inmate_id, 2, v_sentence_start_date + 90,
                  'Synthetic Golden Case transfer for Stage 1 verification');
  RELEASE_INMATE(v_inmate_id, TRUNC(SYSDATE));

  -- Assertions: any failure rolls back all Golden Case DML, including audit rows.
  SELECT COUNT(*) INTO v_count
  FROM JUDGMENT
  WHERE judgment_id = v_judgment_id AND case_id = v_case_id AND hearing_id = v_hearing_id;
  IF v_count <> 1 THEN RAISE_APPLICATION_ERROR(-20042, 'Golden judgment-to-hearing link failed'); END IF;

  SELECT COUNT(*) INTO v_count
  FROM EVIDENCE_AUDIT
  WHERE evidence_id = v_evidence_id
    AND custody_id IN (v_custody_out_id, v_custody_return_id)
    AND action_name = 'EVIDENCE_TRANSFER';
  IF v_count <> 2 THEN RAISE_APPLICATION_ERROR(-20043, 'Golden custody audit coverage failed'); END IF;

  SELECT COUNT(*) INTO v_count
  FROM INMATE
  WHERE inmate_id = v_inmate_id AND prison_id = 2
    AND status = 'RELEASED' AND actual_release_date IS NOT NULL;
  IF v_count <> 1 THEN RAISE_APPLICATION_ERROR(-20044, 'Golden transfer/release workflow failed'); END IF;

  DBMS_OUTPUT.PUT_LINE('GOLDEN-CASE-0001 passed. case_id=' || v_case_id ||
                       ', evidence_id=' || v_evidence_id || ', inmate_id=' || v_inmate_id);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO golden_case_sp;
    RAISE;
END;
/

-- Readable end-to-end result. Expected: one row with two custody events/audit entries,
-- a linked hearing and judgment, sentence, released inmate, current prison and transfer history.
SELECT c.case_number, c.case_status, f.fir_number,
       acc.full_name AS accused, inv.status AS investigation_status,
       e.evidence_id, e.current_status AS evidence_status,
       (SELECT COUNT(*) FROM CHAIN_OF_CUSTODY x WHERE x.evidence_id=e.evidence_id) AS custody_events,
       (SELECT COUNT(*) FROM EVIDENCE_AUDIT a WHERE a.evidence_id=e.evidence_id) AS audit_events,
       h.hearing_date, j.verdict, lp.act_name, lp.section_number,
       s.sentence_type, i.status AS inmate_status, pr.prison_name,
       (SELECT COUNT(*) FROM PRISON_TRANSFER pt WHERE pt.inmate_id=i.inmate_id) AS prison_transfers
FROM CASE_TABLE c
JOIN FIR f ON f.case_id=c.case_id
JOIN CASE_PERSON cp ON cp.case_id=c.case_id AND cp.role_in_case='ACCUSED'
JOIN PERSON acc ON acc.person_id=cp.person_id
JOIN INVESTIGATION inv ON inv.case_id=c.case_id
JOIN EVIDENCE e ON e.case_id=c.case_id
JOIN FORENSIC_REPORT fr ON fr.evidence_id=e.evidence_id
JOIN HEARING h ON h.case_id=c.case_id
JOIN JUDGMENT j ON j.case_id=c.case_id AND j.hearing_id=h.hearing_id
JOIN CASE_PROVISION cpr ON cpr.case_id=c.case_id
JOIN LEGAL_PROVISION lp ON lp.provision_id=cpr.provision_id
JOIN SENTENCE s ON s.judgment_id=j.judgment_id AND s.person_id=acc.person_id
JOIN INMATE i ON i.sentence_id=s.sentence_id
JOIN PRISON pr ON pr.prison_id=i.prison_id
WHERE c.case_number='GOLDEN-CASE-0001'
GROUP BY c.case_number, c.case_status, f.fir_number, acc.full_name, inv.status,
         e.evidence_id, e.current_status, h.hearing_date, j.verdict,
         lp.act_name, lp.section_number, s.sentence_type, i.status, pr.prison_name, i.inmate_id;
