-- UCJIMS Stage 1: database constraints, referential integrity, indexes and legacy data correction.
-- Run exactly once after Stage 0 data/objects and Stage 0 validation have completed successfully.
-- Intended for the project's fresh, disposable development schema; not a rerunnable deployment migration.

SET SERVEROUTPUT ON;

PROMPT Stage 1.1 - align post-01-Jul-2024 synthetic offences to BNS sections.
-- Case C2024009 is an October 2024 extortion incident; C2024008 is a September 2024 robbery incident.
-- BNS section 308 addresses extortion and section 309 addresses robbery. The BNS took effect on 1 July 2024.
DECLARE
  v_extortion_rows NUMBER;
  v_robbery_rows   NUMBER;
BEGIN
  UPDATE LEGAL_PROVISION
  SET act_name = 'Bharatiya Nyaya Sanhita, 2023',
      section_number = '308',
      description = 'Extortion'
  WHERE provision_id = 3
    AND act_name = 'Indian Penal Code'
    AND section_number = '384';
  v_extortion_rows := SQL%ROWCOUNT;

  UPDATE LEGAL_PROVISION
  SET act_name = 'Bharatiya Nyaya Sanhita, 2023',
      section_number = '309',
      description = 'Robbery'
  WHERE provision_id = 6
    AND act_name = 'Indian Penal Code'
    AND section_number = '392';
  v_robbery_rows := SQL%ROWCOUNT;

  IF v_extortion_rows <> 1 THEN
    RAISE_APPLICATION_ERROR(-20051,
      'Expected to correct exactly one synthetic extortion provision (ID 3); found ' || v_extortion_rows);
  END IF;
  IF v_robbery_rows <> 1 THEN
    RAISE_APPLICATION_ERROR(-20052,
      'Expected to correct exactly one synthetic robbery provision (ID 6); found ' || v_robbery_rows);
  END IF;
END;
/

-- Link every seeded judgment to the completed hearing held on its judgment date.
-- Fail early with a clear message if a judgment cannot be linked before adding the column.
DECLARE
  v_judgment_count NUMBER;
  v_linkable_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_judgment_count FROM JUDGMENT;
  SELECT COUNT(*) INTO v_linkable_count
  FROM JUDGMENT j
  WHERE EXISTS (
    SELECT 1 FROM HEARING h
    WHERE h.case_id = j.case_id
      AND h.hearing_date = j.judgment_date
      AND h.hearing_status = 'COMPLETED'
  );
  IF v_judgment_count <> v_linkable_count THEN
    RAISE_APPLICATION_ERROR(-20053,
      'Cannot link every judgment to a completed hearing on the same case/date. Judgments=' ||
      v_judgment_count || ', linkable=' || v_linkable_count);
  END IF;
END;
/

ALTER TABLE HEARING
  ADD CONSTRAINT uq_hearing_id_case UNIQUE (hearing_id, case_id);

ALTER TABLE JUDGMENT ADD (hearing_id NUMBER);

UPDATE JUDGMENT j
SET hearing_id = (
  SELECT MIN(h.hearing_id)
  FROM HEARING h
  WHERE h.case_id = j.case_id
    AND h.hearing_date = j.judgment_date
    AND h.hearing_status = 'COMPLETED'
);

ALTER TABLE JUDGMENT MODIFY (hearing_id NOT NULL);
ALTER TABLE JUDGMENT
  ADD CONSTRAINT fk_judgment_hearing_case
  FOREIGN KEY (hearing_id, case_id)
  REFERENCES HEARING (hearing_id, case_id);

CREATE OR REPLACE TRIGGER trg_judgment_hearing_guard
BEFORE INSERT OR UPDATE OF hearing_id, case_id, judgment_date ON JUDGMENT
FOR EACH ROW
DECLARE
  v_hearing_case_id HEARING.case_id%TYPE;
  v_hearing_date    HEARING.hearing_date%TYPE;
  v_hearing_status  HEARING.hearing_status%TYPE;
BEGIN
  SELECT case_id, hearing_date, hearing_status
    INTO v_hearing_case_id, v_hearing_date, v_hearing_status
    FROM HEARING
   WHERE hearing_id = :NEW.hearing_id;

  IF v_hearing_case_id <> :NEW.case_id THEN
    RAISE_APPLICATION_ERROR(-20080, 'Judgment hearing must belong to the same case');
  END IF;
  IF v_hearing_status <> 'COMPLETED' THEN
    RAISE_APPLICATION_ERROR(-20081, 'A judgment can only reference a completed hearing');
  END IF;
  IF TRUNC(v_hearing_date) <> TRUNC(:NEW.judgment_date) THEN
    RAISE_APPLICATION_ERROR(-20082, 'Judgment date must match the linked completed hearing date');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20083, 'Linked hearing does not exist');
END;
/

PROMPT Stage 1.2 - widen participant roles and correct seeded victim-role mismatches.
ALTER TABLE HEARING_PARTICIPANT DROP CONSTRAINT chk_participant_role;
ALTER TABLE HEARING_PARTICIPANT
  ADD CONSTRAINT chk_participant_role
  CHECK (participant_role IN ('ACCUSED','VICTIM','WITNESS','COMPLAINANT','OFFICIAL','LAWYER','PROSECUTOR'));

DECLARE
  v_corrected_rows NUMBER;
BEGIN
  UPDATE HEARING_PARTICIPANT
     SET participant_role = 'VICTIM'
   WHERE hearing_participant_id IN (2,4,10,13,15,19,21,24)
     AND participant_role = 'WITNESS';
  v_corrected_rows := SQL%ROWCOUNT;
  IF v_corrected_rows <> 8 THEN
    RAISE_APPLICATION_ERROR(-20054,
      'Expected to correct 8 seeded hearing participants from WITNESS to VICTIM; changed ' || v_corrected_rows);
  END IF;
END;
/

PROMPT Stage 1.3 - enforce non-null states required by the application workflow.
ALTER TABLE CASE_TABLE MODIFY (case_status NOT NULL, priority NOT NULL);
ALTER TABLE CASE_PERSON MODIFY (role_in_case NOT NULL);
ALTER TABLE CASE_INVESTIGATOR MODIFY (role_in_investigation NOT NULL);
ALTER TABLE INVESTIGATION MODIFY (status NOT NULL);
ALTER TABLE EVIDENCE MODIFY (evidence_type NOT NULL, description NOT NULL, collected_by NOT NULL, current_status NOT NULL);
ALTER TABLE CHAIN_OF_CUSTODY
  MODIFY (from_user_id NOT NULL, transfer_location NOT NULL, purpose NOT NULL, condition NOT NULL);
ALTER TABLE FORENSIC_REPORT
  MODIFY (forensic_officer_id NOT NULL, examination_details NOT NULL, result NOT NULL);
ALTER TABLE HEARING MODIFY (court_id NOT NULL, judge_id NOT NULL, hearing_status NOT NULL);
ALTER TABLE HEARING_PARTICIPANT MODIFY (participant_role NOT NULL);
ALTER TABLE JUDGMENT MODIFY (verdict NOT NULL);
ALTER TABLE SENTENCE MODIFY (sentence_type NOT NULL);
ALTER TABLE INMATE MODIFY (status NOT NULL);
ALTER TABLE PRISON MODIFY (capacity NOT NULL);
ALTER TABLE PRISON_TRANSFER MODIFY (from_prison_id NOT NULL, to_prison_id NOT NULL, reason NOT NULL);
ALTER TABLE EVIDENCE_AUDIT MODIFY (action_name NOT NULL, from_user_id NOT NULL);

ALTER TABLE EVIDENCE
  ADD CONSTRAINT chk_evidence_type_domain
  CHECK (evidence_type IN ('Physical','Digital','Document','Biological','Trace'));

PROMPT Stage 1.4 - add cross-row-independent validation constraints.
ALTER TABLE CASE_TABLE
  ADD CONSTRAINT chk_case_incident_registered
  CHECK (incident_date IS NULL OR registration_date >= incident_date);

ALTER TABLE INVESTIGATION
  ADD CONSTRAINT chk_investigation_date_order
  CHECK (end_date IS NULL OR end_date >= start_date);

ALTER TABLE CHAIN_OF_CUSTODY
  ADD CONSTRAINT chk_custody_distinct_users
  CHECK (from_user_id IS NULL OR to_user_id IS NULL OR from_user_id <> to_user_id);

ALTER TABLE INMATE
  ADD CONSTRAINT chk_inmate_actual_release_date
  CHECK (actual_release_date IS NULL OR actual_release_date >= admission_date);

ALTER TABLE INMATE
  ADD CONSTRAINT chk_inmate_release_state
  CHECK (
    (status = 'RELEASED' AND actual_release_date IS NOT NULL)
    OR (status IN ('INCARCERATED','PAROLED') AND actual_release_date IS NULL)
  );

PROMPT Stage 1.5 - lock audit references to their source rows and users.
ALTER TABLE EVIDENCE_AUDIT
  ADD CONSTRAINT fk_ea_custody FOREIGN KEY (custody_id)
  REFERENCES CHAIN_OF_CUSTODY(custody_id);
ALTER TABLE EVIDENCE_AUDIT
  ADD CONSTRAINT uq_ea_custody_id UNIQUE (custody_id);
ALTER TABLE EVIDENCE_AUDIT
  ADD CONSTRAINT fk_ea_evidence FOREIGN KEY (evidence_id)
  REFERENCES EVIDENCE(evidence_id);
ALTER TABLE EVIDENCE_AUDIT
  ADD CONSTRAINT fk_ea_from_user FOREIGN KEY (from_user_id)
  REFERENCES APP_USER(user_id);
ALTER TABLE EVIDENCE_AUDIT
  ADD CONSTRAINT fk_ea_to_user FOREIGN KEY (to_user_id)
  REFERENCES APP_USER(user_id);

PROMPT Stage 1.6 - protect custody and audit logs as append-only histories.
CREATE OR REPLACE TRIGGER trg_custody_immutable
BEFORE UPDATE OR DELETE ON CHAIN_OF_CUSTODY
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20031,
    'Chain-of-custody rows are append-only. Record a corrective transfer instead.');
END;
/

CREATE OR REPLACE TRIGGER trg_evidence_audit_immutable
BEFORE UPDATE OR DELETE ON EVIDENCE_AUDIT
FOR EACH ROW
BEGIN
  RAISE_APPLICATION_ERROR(-20032,
    'Evidence audit rows are immutable. Do not update or delete audit history.');
END;
/

PROMPT Stage 1.7 - enforce cross-table role and lifecycle semantics for future writes.
-- Foreign keys prove that an account exists; these triggers also prove its application role.
CREATE OR REPLACE TRIGGER trg_forensic_report_role
BEFORE INSERT OR UPDATE OF forensic_officer_id ON FORENSIC_REPORT
FOR EACH ROW
DECLARE
  v_role_name ROLE.role_name%TYPE;
  v_status    APP_USER.status%TYPE;
BEGIN
  SELECT r.role_name, u.status INTO v_role_name, v_status
  FROM APP_USER u JOIN ROLE r ON r.role_id=u.role_id
  WHERE u.user_id=:NEW.forensic_officer_id;
  IF v_role_name <> 'Forensic Officer' OR NVL(v_status, '?') <> 'ACTIVE' THEN
    RAISE_APPLICATION_ERROR(-20090, 'A forensic report must be assigned to an active Forensic Officer');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20091, 'Forensic report officer account was not found');
END;
/

CREATE OR REPLACE TRIGGER trg_hearing_judge_role
BEFORE INSERT OR UPDATE OF judge_id ON HEARING
FOR EACH ROW
DECLARE
  v_role_name ROLE.role_name%TYPE;
  v_status    APP_USER.status%TYPE;
BEGIN
  SELECT r.role_name, u.status INTO v_role_name, v_status
  FROM APP_USER u JOIN ROLE r ON r.role_id=u.role_id
  WHERE u.user_id=:NEW.judge_id;
  IF v_role_name <> 'Judge' OR NVL(v_status, '?') <> 'ACTIVE' THEN
    RAISE_APPLICATION_ERROR(-20092, 'A hearing must be assigned to an active Judge account');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20093, 'Hearing judge account was not found');
END;
/

CREATE OR REPLACE TRIGGER trg_case_investigator_role
BEFORE INSERT OR UPDATE OF investigator_user_id ON CASE_INVESTIGATOR
FOR EACH ROW
DECLARE
  v_role_name ROLE.role_name%TYPE;
  v_status    APP_USER.status%TYPE;
BEGIN
  SELECT r.role_name, u.status INTO v_role_name, v_status
  FROM APP_USER u JOIN ROLE r ON r.role_id=u.role_id
  WHERE u.user_id=:NEW.investigator_user_id;
  IF v_role_name NOT IN ('Investigator','Cyber Crime Analyst') OR NVL(v_status, '?') <> 'ACTIVE' THEN
    RAISE_APPLICATION_ERROR(-20094, 'Case investigator must be an active Investigator or Cyber Crime Analyst');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20095, 'Case investigator account was not found');
END;
/

CREATE OR REPLACE TRIGGER trg_hearing_participant_guard
BEFORE INSERT OR UPDATE OF hearing_id, person_id, participant_role ON HEARING_PARTICIPANT
FOR EACH ROW
DECLARE
  v_case_id CASE_TABLE.case_id%TYPE;
  v_count   NUMBER;
BEGIN
  SELECT case_id INTO v_case_id FROM HEARING WHERE hearing_id=:NEW.hearing_id;
  IF :NEW.participant_role IN ('ACCUSED','VICTIM','WITNESS','COMPLAINANT','OFFICIAL') THEN
    SELECT COUNT(*) INTO v_count FROM CASE_PERSON
    WHERE case_id=v_case_id AND person_id=:NEW.person_id AND role_in_case=:NEW.participant_role;
  ELSE
    -- LAWYER and PROSECUTOR must still be registered as a participant in this case.
    SELECT COUNT(*) INTO v_count FROM CASE_PERSON
    WHERE case_id=v_case_id AND person_id=:NEW.person_id;
  END IF;
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20096, 'Hearing participant must belong to the hearing case with a compatible role');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20097, 'Hearing does not exist for participant');
END;
/

CREATE OR REPLACE TRIGGER trg_sentence_accused_guard
BEFORE INSERT OR UPDATE OF judgment_id, person_id ON SENTENCE
FOR EACH ROW
DECLARE
  v_case_id CASE_TABLE.case_id%TYPE;
  v_count   NUMBER;
BEGIN
  SELECT case_id INTO v_case_id FROM JUDGMENT WHERE judgment_id=:NEW.judgment_id;
  SELECT COUNT(*) INTO v_count FROM CASE_PERSON
  WHERE case_id=v_case_id AND person_id=:NEW.person_id AND role_in_case='ACCUSED';
  IF v_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20098, 'A sentence can only be assigned to an accused person in the judgment case');
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20099, 'Sentence judgment was not found');
END;
/

CREATE OR REPLACE TRIGGER trg_hearing_judgment_guard
BEFORE UPDATE OF case_id, hearing_date, hearing_status ON HEARING
FOR EACH ROW
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM JUDGMENT WHERE hearing_id=:OLD.hearing_id;
  IF v_count > 0 THEN
    IF :NEW.case_id <> :OLD.case_id THEN
      RAISE_APPLICATION_ERROR(-20084, 'A hearing linked to a judgment cannot be moved to another case');
    END IF;
    IF NVL(:NEW.hearing_status, '?') <> 'COMPLETED' THEN
      RAISE_APPLICATION_ERROR(-20085, 'A hearing linked to a judgment must remain completed');
    END IF;
    IF TRUNC(:NEW.hearing_date) <> TRUNC(:OLD.hearing_date) THEN
      RAISE_APPLICATION_ERROR(-20086, 'A hearing linked to a judgment cannot be moved to another date');
    END IF;
  END IF;
END;
/

PROMPT Stage 1.8 - indexes for common joins, filters and child foreign keys.
CREATE INDEX ix_user_role_id ON APP_USER(role_id);
CREATE INDEX ix_user_department_id ON APP_USER(department_id);
CREATE INDEX ix_fir_case_id ON FIR(case_id);
CREATE INDEX ix_fir_filed_by ON FIR(filed_by_user_id);
CREATE INDEX ix_fir_complainant ON FIR(complainant_id);
CREATE INDEX ix_cp_case_role ON CASE_PERSON(case_id, role_in_case);
CREATE INDEX ix_cp_person ON CASE_PERSON(person_id);
CREATE INDEX ix_inv_case ON INVESTIGATION(case_id);
CREATE INDEX ix_ci_case_role ON CASE_INVESTIGATOR(case_id, role_in_investigation);
CREATE INDEX ix_ci_user ON CASE_INVESTIGATOR(investigator_user_id);
CREATE INDEX ix_evidence_case_status ON EVIDENCE(case_id, current_status);
CREATE INDEX ix_evidence_collector ON EVIDENCE(collected_by);
CREATE INDEX ix_custody_evidence_time ON CHAIN_OF_CUSTODY(evidence_id, transfer_date_time);
CREATE INDEX ix_custody_from_user ON CHAIN_OF_CUSTODY(from_user_id);
CREATE INDEX ix_custody_to_user ON CHAIN_OF_CUSTODY(to_user_id);
CREATE INDEX ix_report_evidence_date ON FORENSIC_REPORT(evidence_id, examination_date);
CREATE INDEX ix_report_officer ON FORENSIC_REPORT(forensic_officer_id);
CREATE INDEX ix_audit_evidence_time ON EVIDENCE_AUDIT(evidence_id, action_time);
CREATE INDEX ix_audit_from_user ON EVIDENCE_AUDIT(from_user_id);
CREATE INDEX ix_audit_to_user ON EVIDENCE_AUDIT(to_user_id);
CREATE INDEX ix_hearing_case_date ON HEARING(case_id, hearing_date);
CREATE INDEX ix_hearing_court_date ON HEARING(court_id, hearing_date);
CREATE INDEX ix_hearing_judge_date ON HEARING(judge_id, hearing_date);
CREATE INDEX ix_hp_person ON HEARING_PARTICIPANT(person_id);
CREATE INDEX ix_judgment_hearing_case ON JUDGMENT(hearing_id, case_id);
CREATE INDEX ix_judgment_case_date ON JUDGMENT(case_id, judgment_date);
CREATE INDEX ix_case_provision_provision ON CASE_PROVISION(provision_id);
CREATE INDEX ix_sentence_judgment ON SENTENCE(judgment_id);
CREATE INDEX ix_sentence_person ON SENTENCE(person_id);
CREATE INDEX ix_inmate_person ON INMATE(person_id);
CREATE INDEX ix_inmate_prison_status ON INMATE(prison_id, status);
CREATE INDEX ix_inmate_sentence ON INMATE(sentence_id);
CREATE INDEX ix_transfer_inmate_date ON PRISON_TRANSFER(inmate_id, transfer_date);
CREATE INDEX ix_transfer_from_prison ON PRISON_TRANSFER(from_prison_id);
CREATE INDEX ix_transfer_to_prison ON PRISON_TRANSFER(to_prison_id);

PROMPT Stage 1 hardening complete. Inspect USER_OBJECTS and USER_ERRORS before continuing.
