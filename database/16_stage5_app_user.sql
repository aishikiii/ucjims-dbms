-- ============================================================================
-- UCJIMS Stage 5: least-privilege database account for the API
-- File: database/16_stage5_app_user.sql
--
-- WHY: the API must not connect as the schema owner. The owner can DROP tables and
-- DELETE custody/audit rows; the API account below can only do what the endpoints need.
--
-- NAMES USED (find/replace if yours differ):
--   UCJIMS_OWNER  the schema that owns the tables (the one run_fresh_setup.sql built)
--   UCJIMS_APP    the new account the API connects as
--
-- Run each PART in Oracle SQL Developer with F5 (Run Script), connected as the user
-- named in the heading. Repeat for staging and production with DIFFERENT passwords.
-- Written against the stage-0-1 scripts; not executed in Oracle by its author.
-- ============================================================================
SET DEFINE OFF;
SET SERVEROUTPUT ON;

-- ---------------------------------------------------------------------------
-- PART 1 - connect as an administrator (SYSTEM / ADMIN / a user with CREATE USER)
-- ---------------------------------------------------------------------------
-- Choose a long random password; store it in your secret manager / .env, never in git.
CREATE USER UCJIMS_APP IDENTIFIED BY "CHANGE_ME_long_random_password";
GRANT CREATE SESSION TO UCJIMS_APP;
-- No CREATE TABLE, no RESOURCE/CONNECT roles, no quota. It owns nothing.

-- ---------------------------------------------------------------------------
-- PART 2 - connect as UCJIMS_OWNER (the account that owns the tables)
-- ---------------------------------------------------------------------------
BEGIN
  -- Read access to every table (the API reads everything through the owner's objects).
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON ' || t.table_name || ' TO UCJIMS_APP';
  END LOOP;

  -- Views used by the API.
  FOR v IN (SELECT view_name FROM user_views) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON ' || v.view_name || ' TO UCJIMS_APP';
  END LOOP;

  -- Sequences: SELECT is what NEXTVAL needs.
  FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE 'SEQ\_%' ESCAPE '\') LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON ' || s.sequence_name || ' TO UCJIMS_APP';
  END LOOP;
END;
/

-- Direct inserts the API performs today (add a table here only when a new endpoint needs it).
GRANT INSERT ON CASE_TABLE TO UCJIMS_APP;
GRANT INSERT ON FIR        TO UCJIMS_APP;
GRANT INSERT ON HEARING    TO UCJIMS_APP;
GRANT INSERT ON JUDGMENT   TO UCJIMS_APP;
GRANT INSERT ON INMATE     TO UCJIMS_APP;

-- Workflows run with the OWNER's rights (definer rights), so the API needs EXECUTE only.
-- It therefore never gets INSERT on CHAIN_OF_CUSTODY / EVIDENCE_AUDIT / PRISON_TRANSFER,
-- and has no UPDATE or DELETE on anything.
GRANT EXECUTE ON TRANSFER_EVIDENCE   TO UCJIMS_APP;
GRANT EXECUTE ON TRANSFER_INMATE     TO UCJIMS_APP;
GRANT EXECUTE ON RELEASE_INMATE      TO UCJIMS_APP;
GRANT EXECUTE ON GET_PRISON_OCCUPANCY TO UCJIMS_APP;

-- ---------------------------------------------------------------------------
-- PART 3 - connect as UCJIMS_APP and prove the limits (SQL Developer: new connection)
-- ---------------------------------------------------------------------------
-- Expected: works.
-- SELECT COUNT(*) FROM UCJIMS_OWNER.CASE_TABLE;
-- SELECT UCJIMS_OWNER.SEQ_CASE_TABLE.NEXTVAL FROM dual;
-- Expected: each of these FAILS with ORA-01031 (insufficient privileges) or ORA-00942.
-- DELETE FROM UCJIMS_OWNER.CHAIN_OF_CUSTODY;
-- UPDATE UCJIMS_OWNER.EVIDENCE_AUDIT SET evidence_id = evidence_id;
-- INSERT INTO UCJIMS_OWNER.CHAIN_OF_CUSTODY (custody_id) VALUES (1);
-- DROP TABLE UCJIMS_OWNER.CASE_TABLE;
-- UPDATE UCJIMS_OWNER.APP_USER SET role_id = 6;        -- no self-escalation through the app account
--
-- The API's SQL uses unqualified names (CASE_TABLE, SEQ_CASE_TABLE...). Make them resolve to the
-- owner's objects by adding this to backend/config/db.js (see the guide), with
-- ORACLE_SCHEMA=UCJIMS_OWNER in .env:
--   sessionCallback: (conn, tag, cb) =>
--     conn.execute(`ALTER SESSION SET CURRENT_SCHEMA = ${process.env.ORACLE_SCHEMA}`)
--         .then(() => cb()).catch(cb)
--
-- NOTE: backend/scripts/setup_demo_users.js UPDATEs APP_USER, so run THAT script with the OWNER
-- credentials (a one-off command), never with UCJIMS_APP.