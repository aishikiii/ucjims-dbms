-- 1. ROLE - no dependencies
CREATE TABLE ROLE (
    role_id      NUMBER PRIMARY KEY,
    role_name    VARCHAR2(50) NOT NULL UNIQUE,
    description  VARCHAR2(200)
);

-- 2. DEPARTMENT - no dependencies
CREATE TABLE DEPARTMENT (
    department_id    NUMBER PRIMARY KEY,
    department_name  VARCHAR2(50) NOT NULL UNIQUE,
    location         VARCHAR2(100)
);

-- 3. APP_USER - depends on ROLE, DEPARTMENT
CREATE TABLE APP_USER (
    user_id         NUMBER PRIMARY KEY,
    role_id         NUMBER NOT NULL,
    department_id   NUMBER NOT NULL,
    full_name       VARCHAR2(100) NOT NULL,
    username        VARCHAR2(50) NOT NULL UNIQUE,
    password_hash   VARCHAR2(255) NOT NULL,
    email           VARCHAR2(100) UNIQUE,
    contact_info    VARCHAR2(50),
    status          VARCHAR2(20) DEFAULT 'ACTIVE'
                        CHECK (status IN ('ACTIVE','INACTIVE')),
    CONSTRAINT fk_user_role FOREIGN KEY (role_id)
        REFERENCES ROLE(role_id),
    CONSTRAINT fk_user_dept FOREIGN KEY (department_id)
        REFERENCES DEPARTMENT(department_id)
);

-- 4. PERSON - no dependencies (RoleType removed; role is per-case, see CASE_PERSON)
CREATE TABLE PERSON (
    person_id           NUMBER PRIMARY KEY,
    full_name           VARCHAR2(100) NOT NULL,
    date_of_birth       DATE,
    gender              VARCHAR2(10),
    contact_info        VARCHAR2(50),
    address             VARCHAR2(200),
    identification_no   VARCHAR2(50) UNIQUE
);

-- 5. CASE_TABLE - no dependencies
CREATE TABLE CASE_TABLE (
    case_id             NUMBER PRIMARY KEY,
    case_number         VARCHAR2(50) NOT NULL UNIQUE,
    case_type           VARCHAR2(50),
    registration_date   DATE NOT NULL,
    incident_date       DATE,
    incident_location   VARCHAR2(200),
    description         VARCHAR2(500),
    case_status         VARCHAR2(30) DEFAULT 'OPEN'
                            CHECK (case_status IN
                                ('OPEN','UNDER_INVESTIGATION','CHARGESHEETED','UNDER_TRIAL','CLOSED')),
    priority            VARCHAR2(20)
                            CHECK (priority IN ('LOW','MEDIUM','HIGH'))
);

-- 6. FIR - depends on CASE_TABLE, APP_USER, PERSON
CREATE TABLE FIR (
    fir_id             NUMBER PRIMARY KEY,
    case_id            NUMBER NOT NULL,
    filed_by_user_id   NUMBER NOT NULL,
    complainant_id     NUMBER NOT NULL,
    fir_number         VARCHAR2(50) NOT NULL UNIQUE,
    filing_date        DATE NOT NULL,
    station_name       VARCHAR2(100),
    fir_details        VARCHAR2(500),
    CONSTRAINT fk_fir_case FOREIGN KEY (case_id)
        REFERENCES CASE_TABLE(case_id),
    CONSTRAINT fk_fir_user FOREIGN KEY (filed_by_user_id)
        REFERENCES APP_USER(user_id),
    CONSTRAINT fk_fir_person FOREIGN KEY (complainant_id)
        REFERENCES PERSON(person_id)
);

-- 7. CASE_PERSON - depends on CASE_TABLE, PERSON
CREATE TABLE CASE_PERSON (
    case_person_id   NUMBER PRIMARY KEY,
    case_id          NUMBER NOT NULL,
    person_id        NUMBER NOT NULL,
    role_in_case     VARCHAR2(30)
                        CHECK (role_in_case IN
                            ('ACCUSED','VICTIM','WITNESS','COMPLAINANT','OFFICIAL')),
    remarks          VARCHAR2(200),
    CONSTRAINT fk_cp_case FOREIGN KEY (case_id)
        REFERENCES CASE_TABLE(case_id),
    CONSTRAINT fk_cp_person FOREIGN KEY (person_id)
        REFERENCES PERSON(person_id)
);

-- 8. INVESTIGATION - depends on CASE_TABLE
CREATE TABLE INVESTIGATION (
    investigation_id   NUMBER PRIMARY KEY,
    case_id            NUMBER NOT NULL,
    start_date         DATE NOT NULL,
    end_date           DATE,
    status             VARCHAR2(30)
                            CHECK (status IN ('ONGOING','COMPLETED','SUSPENDED')),
    findings           VARCHAR2(500),
    CONSTRAINT fk_inv_case FOREIGN KEY (case_id)
        REFERENCES CASE_TABLE(case_id)
);

-- 9. CASE_INVESTIGATOR - depends on CASE_TABLE, APP_USER
CREATE TABLE CASE_INVESTIGATOR (
    case_investigator_id    NUMBER PRIMARY KEY,
    case_id                 NUMBER NOT NULL,
    investigator_user_id    NUMBER NOT NULL,
    assigned_date           DATE NOT NULL,
    role_in_investigation   VARCHAR2(20)
                                CHECK (role_in_investigation IN ('LEAD','ASSISTANT')),
    CONSTRAINT fk_ci_case FOREIGN KEY (case_id)
        REFERENCES CASE_TABLE(case_id),
    CONSTRAINT fk_ci_user FOREIGN KEY (investigator_user_id)
        REFERENCES APP_USER(user_id)
);

-- Quick check: list all tables just created
SELECT table_name FROM user_tables ORDER BY table_name;
