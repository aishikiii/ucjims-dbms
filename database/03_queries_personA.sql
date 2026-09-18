-- ============================================================
-- Query 1: Cases by status
-- ============================================================
SELECT case_id, case_number, case_type, case_status, priority
FROM CASE_TABLE
WHERE case_status = 'UNDER_TRIAL'
ORDER BY case_id;

-- ============================================================
-- Query 2: Cases by priority
-- ============================================================
SELECT case_id, case_number, case_type, priority, registration_date
FROM CASE_TABLE
WHERE priority = 'HIGH'
ORDER BY registration_date;

-- ============================================================
-- Query 3: Cases assigned to a specific investigator (by user_id)
-- ============================================================
SELECT ct.case_id, ct.case_number, ct.case_type, u.full_name AS investigator,
       ci.role_in_investigation, ci.assigned_date
FROM CASE_TABLE ct
JOIN CASE_INVESTIGATOR ci ON ct.case_id = ci.case_id
JOIN APP_USER u ON ci.investigator_user_id = u.user_id
WHERE u.user_id = 1
ORDER BY ct.case_id;

-- ============================================================
-- Query 4: Cases involving a specific person (by person_id)
-- ============================================================
SELECT ct.case_id, ct.case_number, ct.case_type, cp.role_in_case, p.full_name
FROM CASE_TABLE ct
JOIN CASE_PERSON cp ON ct.case_id = cp.case_id
JOIN PERSON p ON cp.person_id = p.person_id
WHERE p.person_id = 1
ORDER BY ct.case_id;

-- ============================================================
-- Query 5: FIR lookup by FIR number
-- ============================================================
SELECT f.fir_id, f.fir_number, f.filing_date, f.station_name,
       ct.case_number, ct.case_type, p.full_name AS complainant
FROM FIR f
JOIN CASE_TABLE ct ON f.case_id = ct.case_id
JOIN PERSON p ON f.complainant_id = p.person_id
WHERE f.fir_number = 'FIR2024/001';

-- ============================================================
-- Query 6: Investigation history for a case
-- ============================================================
SELECT i.investigation_id, ct.case_number, i.start_date, i.end_date,
       i.status, i.findings
FROM INVESTIGATION i
JOIN CASE_TABLE ct ON i.case_id = ct.case_id
WHERE ct.case_id = 1
ORDER BY i.start_date;

-- ============================================================
-- Query 7: Case count grouped by status (summary/reporting query)
-- ============================================================
SELECT case_status, COUNT(*) AS total_cases
FROM CASE_TABLE
GROUP BY case_status
ORDER BY total_cases DESC;

-- ============================================================
-- VIEW: Full case summary (Phase 6 advanced feature)
-- Joins case, people involved, investigation status, and investigator
-- ============================================================
CREATE OR REPLACE VIEW CASE_SUMMARY_VIEW AS
SELECT
    ct.case_id,
    ct.case_number,
    ct.case_type,
    ct.case_status,
    ct.priority,
    p.person_id,
    p.full_name        AS person_name,
    cp.role_in_case,
    i.status            AS investigation_status,
    u.full_name          AS investigator_name,
    ci.role_in_investigation
FROM CASE_TABLE ct
LEFT JOIN CASE_PERSON cp        ON ct.case_id = cp.case_id
LEFT JOIN PERSON p              ON cp.person_id = p.person_id
LEFT JOIN INVESTIGATION i       ON ct.case_id = i.case_id
LEFT JOIN CASE_INVESTIGATOR ci  ON ct.case_id = ci.case_id
LEFT JOIN APP_USER u            ON ci.investigator_user_id = u.user_id;

-- Example: view usage
SELECT * FROM CASE_SUMMARY_VIEW WHERE case_id = 1;

-- ============================================================
-- Complex JOIN query: full detail of everyone involved in one case,
-- plus their investigator (5-table join)
-- ============================================================
SELECT
    ct.case_number,
    ct.case_type,
    ct.case_status,
    p.full_name          AS person_involved,
    cp.role_in_case,
    u.full_name           AS investigator,
    ci.role_in_investigation
FROM CASE_TABLE ct
JOIN CASE_PERSON cp        ON ct.case_id = cp.case_id
JOIN PERSON p              ON cp.person_id = p.person_id
JOIN CASE_INVESTIGATOR ci  ON ct.case_id = ci.case_id
JOIN APP_USER u            ON ci.investigator_user_id = u.user_id
WHERE ct.case_id = 5
ORDER BY cp.role_in_case;
