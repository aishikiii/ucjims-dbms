-- Evidence custody workflow: derive the current sender from the recorded chain, never from client input.
-- The procedure writes the custody row, fires the immutable audit trigger, and synchronizes current_status.
CREATE OR REPLACE PROCEDURE TRANSFER_EVIDENCE (
  p_evidence_id        IN  NUMBER,
  p_to_user_id         IN  NUMBER,
  p_transfer_date_time IN  DATE,
  p_transfer_location  IN  VARCHAR2,
  p_storage_location   IN  VARCHAR2,
  p_purpose            IN  VARCHAR2,
  p_condition          IN  VARCHAR2,
  p_remarks            IN  VARCHAR2,
  p_custody_id         OUT NUMBER
)
IS
  v_collected_by       EVIDENCE.collected_by%TYPE;
  v_collection_date    EVIDENCE.collection_date%TYPE;
  v_current_status     EVIDENCE.current_status%TYPE;
  v_event_count        NUMBER;
  v_from_user_id       APP_USER.user_id%TYPE;
  v_previous_to_user   APP_USER.user_id%TYPE;
  v_previous_time      CHAIN_OF_CUSTODY.transfer_date_time%TYPE;
  v_target_role        ROLE.role_name%TYPE;
  v_source_role        ROLE.role_name%TYPE;
  v_new_status         EVIDENCE.current_status%TYPE;
BEGIN
  SAVEPOINT transfer_evidence_sp;

  IF p_evidence_id IS NULL OR p_transfer_date_time IS NULL THEN
    RAISE_APPLICATION_ERROR(-20060, 'Evidence ID and transfer timestamp are required');
  END IF;
  IF p_transfer_location IS NULL OR TRIM(p_transfer_location) IS NULL
     OR p_purpose IS NULL OR TRIM(p_purpose) IS NULL
     OR p_condition IS NULL OR TRIM(p_condition) IS NULL THEN
    RAISE_APPLICATION_ERROR(-20061, 'Transfer location, purpose and condition are required');
  END IF;
  IF p_transfer_date_time > SYSDATE THEN
    RAISE_APPLICATION_ERROR(-20062, 'Evidence transfer timestamp cannot be in the future');
  END IF;

  BEGIN
    SELECT collected_by, collection_date, current_status
      INTO v_collected_by, v_collection_date, v_current_status
      FROM EVIDENCE
     WHERE evidence_id = p_evidence_id
       FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20063, 'Evidence ' || p_evidence_id || ' was not found');
  END;

  IF v_current_status = 'DISPOSED' THEN
    RAISE_APPLICATION_ERROR(-20064, 'Disposed evidence cannot be transferred again');
  END IF;

  SELECT COUNT(*) INTO v_event_count
  FROM CHAIN_OF_CUSTODY
  WHERE evidence_id = p_evidence_id;

  IF v_event_count = 0 THEN
    v_from_user_id := v_collected_by;
    IF p_transfer_date_time < v_collection_date THEN
      RAISE_APPLICATION_ERROR(-20065, 'Evidence transfer cannot precede collection');
    END IF;
  ELSE
    SELECT to_user_id, transfer_date_time
      INTO v_previous_to_user, v_previous_time
      FROM (
        SELECT to_user_id, transfer_date_time
          FROM CHAIN_OF_CUSTODY
         WHERE evidence_id = p_evidence_id
         ORDER BY transfer_date_time DESC, custody_id DESC
      )
     WHERE ROWNUM = 1;

    IF v_previous_to_user IS NULL THEN
      RAISE_APPLICATION_ERROR(-20064, 'Evidence has already reached terminal disposal');
    END IF;
    v_from_user_id := v_previous_to_user;
    IF p_transfer_date_time <= v_previous_time THEN
      RAISE_APPLICATION_ERROR(-20066, 'Custody events must be strictly chronological');
    END IF;
  END IF;

  BEGIN
    SELECT r.role_name INTO v_source_role
    FROM APP_USER u JOIN ROLE r ON r.role_id = u.role_id
    WHERE u.user_id = v_from_user_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20072, 'Current custodian is not linked to a valid application role');
  END;

  IF p_to_user_id IS NULL THEN
    IF UPPER(TRIM(p_condition)) <> 'DISPOSED' THEN
      RAISE_APPLICATION_ERROR(-20067, 'A null recipient is permitted only for a disposal event');
    END IF;
    IF p_storage_location IS NOT NULL THEN
      RAISE_APPLICATION_ERROR(-20073, 'Disposed evidence must not retain an active storage location');
    END IF;
    IF v_source_role NOT IN ('Forensic Officer','Admin') THEN
      RAISE_APPLICATION_ERROR(-20074, 'Only a forensic officer or administrator can dispose evidence');
    END IF;
    v_new_status := 'DISPOSED';
  ELSE
    IF UPPER(TRIM(p_condition)) = 'DISPOSED' THEN
      RAISE_APPLICATION_ERROR(-20068, 'A disposal event must not name a receiving user');
    END IF;
    IF p_storage_location IS NULL OR TRIM(p_storage_location) IS NULL THEN
      RAISE_APPLICATION_ERROR(-20075, 'A receiving user requires a current storage location');
    END IF;
    IF p_to_user_id = v_from_user_id THEN
      RAISE_APPLICATION_ERROR(-20069, 'Sender and recipient must be different users');
    END IF;
    BEGIN
      SELECT r.role_name INTO v_target_role
      FROM APP_USER u JOIN ROLE r ON r.role_id = u.role_id
      WHERE u.user_id = p_to_user_id AND u.status = 'ACTIVE';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20070, 'Receiving user does not exist or is inactive');
    END;

    IF p_to_user_id = v_collected_by THEN
      v_new_status := 'RETURNED';
    ELSIF v_target_role = 'Forensic Officer' THEN
      v_new_status := 'UNDER_EXAMINATION';
    ELSE
      v_new_status := 'COLLECTED';
    END IF;
  END IF;

  p_custody_id := SEQ_CHAIN_OF_CUSTODY.NEXTVAL;
  INSERT INTO CHAIN_OF_CUSTODY (
    custody_id, evidence_id, from_user_id, to_user_id, transfer_date_time,
    transfer_location, purpose, condition, remarks
  ) VALUES (
    p_custody_id, p_evidence_id, v_from_user_id, p_to_user_id, p_transfer_date_time,
    p_transfer_location, p_purpose, p_condition, p_remarks
  );

  UPDATE EVIDENCE
     SET current_status = v_new_status,
         storage_location = p_storage_location
   WHERE evidence_id = p_evidence_id;
  IF SQL%ROWCOUNT <> 1 THEN
    RAISE_APPLICATION_ERROR(-20071, 'Evidence status was not updated after recording custody transfer');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO transfer_evidence_sp;
    RAISE;
END;
/

-- UCJIMS Stage 1: transactional inmate workflows.
-- Run AFTER 08_queries_personC.sql so these hardened procedure definitions replace the prototype.
-- Procedures deliberately do not COMMIT: the caller owns the transaction.

CREATE OR REPLACE PROCEDURE TRANSFER_INMATE (
  p_inmate_id      IN NUMBER,
  p_to_prison_id   IN NUMBER,
  p_transfer_date  IN DATE DEFAULT SYSDATE,
  p_reason         IN VARCHAR2 DEFAULT NULL
)
IS
  v_current_prison_id INMATE.prison_id%TYPE;
  v_status            INMATE.status%TYPE;
  v_admission_date    INMATE.admission_date%TYPE;
  v_last_transfer_date PRISON_TRANSFER.transfer_date%TYPE;
  v_target_capacity   PRISON.capacity%TYPE;
  v_target_occupancy  NUMBER;
BEGIN
  SAVEPOINT transfer_inmate_sp;

  IF p_inmate_id IS NULL OR p_to_prison_id IS NULL OR p_transfer_date IS NULL THEN
    RAISE_APPLICATION_ERROR(-20011, 'Inmate, destination prison and transfer date are required');
  END IF;

  IF p_reason IS NULL OR TRIM(p_reason) IS NULL THEN
    RAISE_APPLICATION_ERROR(-20020, 'A transfer reason is required');
  END IF;

  BEGIN
    SELECT prison_id, status, admission_date
      INTO v_current_prison_id, v_status, v_admission_date
      FROM INMATE
     WHERE inmate_id = p_inmate_id
       FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20012, 'Inmate ' || p_inmate_id || ' was not found');
  END;

  IF v_status <> 'INCARCERATED' THEN
    RAISE_APPLICATION_ERROR(-20013, 'Only currently incarcerated inmates can be transferred');
  END IF;

  IF p_to_prison_id = v_current_prison_id THEN
    RAISE_APPLICATION_ERROR(-20014, 'Destination prison is already the inmate current prison');
  END IF;

  IF p_transfer_date < v_admission_date THEN
    RAISE_APPLICATION_ERROR(-20015, 'Transfer date cannot precede the inmate admission date');
  END IF;

  SELECT MAX(transfer_date) INTO v_last_transfer_date
  FROM PRISON_TRANSFER WHERE inmate_id = p_inmate_id;
  IF v_last_transfer_date IS NOT NULL AND p_transfer_date <= v_last_transfer_date THEN
    RAISE_APPLICATION_ERROR(-20029, 'Transfer date must be later than the latest recorded transfer');
  END IF;

  BEGIN
    SELECT capacity INTO v_target_capacity
      FROM PRISON
     WHERE prison_id = p_to_prison_id
       FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20016, 'Destination prison ' || p_to_prison_id || ' was not found');
  END;

  IF p_transfer_date > SYSDATE THEN
    RAISE_APPLICATION_ERROR(-20018, 'Transfer date cannot be in the future');
  END IF;

  SELECT COUNT(*) INTO v_target_occupancy
  FROM INMATE
  WHERE prison_id = p_to_prison_id AND status = 'INCARCERATED';

  IF v_target_capacity IS NOT NULL AND v_target_occupancy >= v_target_capacity THEN
    RAISE_APPLICATION_ERROR(-20019, 'Destination prison has no available capacity');
  END IF;

  INSERT INTO PRISON_TRANSFER (
    transfer_id, inmate_id, from_prison_id, to_prison_id, transfer_date, reason
  ) VALUES (
    SEQ_PRISON_TRANSFER.NEXTVAL,
    p_inmate_id,
    v_current_prison_id,
    p_to_prison_id,
    p_transfer_date,
    p_reason
  );

  UPDATE INMATE
     SET prison_id = p_to_prison_id
   WHERE inmate_id = p_inmate_id;

  IF SQL%ROWCOUNT <> 1 THEN
    RAISE_APPLICATION_ERROR(-20017, 'Transfer logged but current inmate location was not updated');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO transfer_inmate_sp;
    RAISE;
END;
/

CREATE OR REPLACE PROCEDURE RELEASE_INMATE (
  p_inmate_id          IN NUMBER,
  p_actual_release_date IN DATE DEFAULT SYSDATE
)
IS
  v_status              INMATE.status%TYPE;
  v_admission_date      INMATE.admission_date%TYPE;
  v_expected_release    INMATE.expected_release_date%TYPE;
  v_last_transfer_date PRISON_TRANSFER.transfer_date%TYPE;
BEGIN
  SAVEPOINT release_inmate_sp;

  IF p_inmate_id IS NULL OR p_actual_release_date IS NULL THEN
    RAISE_APPLICATION_ERROR(-20021, 'Inmate ID and actual release date are required');
  END IF;

  BEGIN
    SELECT status, admission_date, expected_release_date
      INTO v_status, v_admission_date, v_expected_release
      FROM INMATE
     WHERE inmate_id = p_inmate_id
       FOR UPDATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20022, 'Inmate ' || p_inmate_id || ' was not found');
  END;

  IF v_status = 'RELEASED' THEN
    RAISE_APPLICATION_ERROR(-20023, 'Inmate ' || p_inmate_id || ' is already released');
  END IF;

  IF v_status <> 'INCARCERATED' THEN
    RAISE_APPLICATION_ERROR(-20024, 'Only currently incarcerated inmates can be released through this procedure');
  END IF;

  IF p_actual_release_date < v_admission_date THEN
    RAISE_APPLICATION_ERROR(-20025, 'Actual release date cannot precede admission date');
  END IF;

  SELECT MAX(transfer_date) INTO v_last_transfer_date
  FROM PRISON_TRANSFER WHERE inmate_id = p_inmate_id;
  IF v_last_transfer_date IS NOT NULL AND p_actual_release_date < v_last_transfer_date THEN
    RAISE_APPLICATION_ERROR(-20030, 'Actual release date cannot precede the latest recorded prison transfer');
  END IF;

  IF p_actual_release_date > SYSDATE THEN
    RAISE_APPLICATION_ERROR(-20026, 'Actual release date cannot be in the future');
  END IF;

  IF v_expected_release IS NOT NULL AND p_actual_release_date < v_expected_release THEN
    RAISE_APPLICATION_ERROR(-20027, 'Release before the expected date requires a separate authorized workflow');
  END IF;

  UPDATE INMATE
     SET actual_release_date = p_actual_release_date,
         status = 'RELEASED'
   WHERE inmate_id = p_inmate_id;

  IF SQL%ROWCOUNT <> 1 THEN
    RAISE_APPLICATION_ERROR(-20028, 'Inmate release update did not affect exactly one row');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO release_inmate_sp;
    RAISE;
END;
/

-- Compilation check; all three workflows should show VALID in USER_OBJECTS.
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN ('TRANSFER_EVIDENCE','TRANSFER_INMATE','RELEASE_INMATE')
ORDER BY object_name;
SELECT name, type, line, position, text
FROM user_errors
WHERE name IN ('TRANSFER_EVIDENCE','TRANSFER_INMATE','RELEASE_INMATE')
ORDER BY name, sequence;
