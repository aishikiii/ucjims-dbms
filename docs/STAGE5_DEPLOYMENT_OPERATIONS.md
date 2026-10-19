# UCJIMS — Stage 5 Deployment and Operations Runbook

This document details the production architecture, multi-environment configuration, least-privilege database provisioning, containerization, reverse proxy hardening, backup/restore procedures, and rollback runbooks for Stage 5 of the Unified Criminal Justice Information Management System (UCJIMS).

---

## 1. System Architecture

```
                                [ Public Internet / HTTPS ]
                                             │
                                             ▼
                             ┌───────────────────────────────┐
                             │       Nginx Reverse Proxy     │
                             │  - TLS Termination            │
                             │  - Rate Limiting (Login/API)  │
                             │  - Security Headers (CSP/HSTS)│
                             └───────┬───────────────┬───────┘
                                     │               │
                     /api requests   │               │ static SPA bundle
                                     ▼               ▼
                      ┌─────────────────────┐ ┌─────────────────────┐
                      │    Backend API      │ │   Frontend Server   │
                      │  (Express / Node)   │ │    (Static HTML)    │
                      │  - JWT Verification │ └─────────────────────┘
                      │  - RBAC Policy      │
                      │  - Parameter Valid. │
                      └──────────┬──────────┘
                                 │
                 Private Subnet  │ (Oracle Thin Driver / Port 1521)
                 Least-Privilege │ No Direct Browser Connection
                                 ▼
                      ┌─────────────────────────────────────┐
                      │       Oracle Database Engine        │
                      │  - UCJIMS_OWNER (Schema / Tables)   │
                      │  - UCJIMS_APP   (Restricted Grants) │
                      │  - Triggers & Workflows             │
                      │  - Append-Only Audit Trail          │
                      └─────────────────────────────────────┘
```

---

## 2. Environment Configuration

Three isolated environments must be maintained with separate database credentials:

| Parameter | Development | Staging | Production |
|---|---|---|---|
| Host Configuration | Local workstation | Staging VM / Cloud Cluster | Production Cluster |
| Config File | `.env` (from `.env.example`) | `.env.staging` (from `.env.staging.example`) | Secret Manager / `.env.production` |
| Database User | `UCJIMS_OWNER` or `UCJIMS_APP` | `UCJIMS_APP_STAGING` | `UCJIMS_APP_PROD` |
| DB Connect String | `localhost:1521/XEPDB1` | `staging-db.internal:1521/STGPDB1` | `prod-db-cluster.internal:1521/PRODPDB1` |
| Pool Size (Min/Max) | 2 / 10 | 4 / 20 | 10 / 50 |
| JWT Expiry | 8h | 4h | 2h |
| CORS Origin | `http://localhost:5173` | `https://staging.ucjims.internal` | `https://ucjims.gov.in` |

> [!CAUTION]
> Never commit real `.env` files, passwords, or JWT secrets to version control. Production deployments must inject secrets using an external Secret Manager (e.g., AWS Secrets Manager, HashiCorp Vault, Azure Key Vault).

---

## 3. Least-Privilege Database Account Setup

The API server must **never** connect as the schema owner (`UCJIMS_OWNER`). The schema owner can drop tables and delete audit logs. Instead, the API connects as `UCJIMS_APP`, configured via `database/16_stage5_app_user.sql`.

### Setup Sequence in Oracle SQL Developer:

#### Step 1: Connect as Administrator (SYSTEM / ADMIN)
```sql
CREATE USER UCJIMS_APP IDENTIFIED BY "REPLACE_WITH_SECURE_PASSWORD";
GRANT CREATE SESSION TO UCJIMS_APP;
```
*(No CREATE TABLE, no RESOURCE role, no tablespace quota. The user owns zero objects).*

#### Step 2: Connect as Schema Owner (UCJIMS_OWNER)
```sql
-- Read grants on tables, views, and sequences
BEGIN
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON ' || t.table_name || ' TO UCJIMS_APP';
  END LOOP;
  FOR v IN (SELECT view_name FROM user_views) LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON ' || v.view_name || ' TO UCJIMS_APP';
  END LOOP;
  FOR s IN (SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE 'SEQ\_%' ESCAPE '\') LOOP
    EXECUTE IMMEDIATE 'GRANT SELECT ON ' || s.sequence_name || ' TO UCJIMS_APP';
  END LOOP;
END;
/

-- Restricted direct inserts
GRANT INSERT ON CASE_TABLE TO UCJIMS_APP;
GRANT INSERT ON FIR        TO UCJIMS_APP;
GRANT INSERT ON HEARING    TO UCJIMS_APP;
GRANT INSERT ON JUDGMENT   TO UCJIMS_APP;
GRANT INSERT ON INMATE     TO UCJIMS_APP;

-- Definer-rights workflow execution (auditing and integrity enforced in PL/SQL)
GRANT EXECUTE ON TRANSFER_EVIDENCE   TO UCJIMS_APP;
GRANT EXECUTE ON TRANSFER_INMATE     TO UCJIMS_APP;
GRANT EXECUTE ON RELEASE_INMATE      TO UCJIMS_APP;
GRANT EXECUTE ON GET_PRISON_OCCUPANCY TO UCJIMS_APP;
```

#### Step 3: Enforcing Least Privilege Limits
When connected as `UCJIMS_APP`, the following actions will fail with `ORA-01031 (insufficient privileges)`:
- `DROP TABLE CASE_TABLE;` (Blocked)
- `DELETE FROM CHAIN_OF_CUSTODY;` (Blocked)
- `UPDATE EVIDENCE_AUDIT SET evidence_id = 999;` (Blocked)
- `UPDATE APP_USER SET role_id = 1;` (Blocked: prevents privilege self-escalation)

In the backend `.env`, define:
```ini
ORACLE_USER=UCJIMS_APP
ORACLE_PASSWORD=REPLACE_WITH_SECURE_PASSWORD
ORACLE_SCHEMA=UCJIMS_OWNER
```
`backend/config/db.js` automatically runs `ALTER SESSION SET CURRENT_SCHEMA = UCJIMS_OWNER` upon acquiring a connection so all unqualified table references resolve directly.

---

## 4. Containerized Deployment (Docker Compose)

### Manifest Structure:
- `backend/Dockerfile`: Multi-stage build running Node 20 as an unprivileged user (`USER node`), with automated healthcheck.
- `frontend/Dockerfile`: Multi-stage Vite build serving static production assets.
- `nginx/nginx.conf`: Nginx reverse proxy with TLS termination, rate limiting, and security headers.
- `docker-compose.yml`: Multi-container orchestration connected via isolated bridge network `ucjims_private_net`.

### Launching the Stack:

1. Copy and configure the environment variables:
   ```bash
   cd ucjims-app/ucjims-app
   cp backend/.env.example backend/.env
   # Edit backend/.env with your Oracle credentials
   ```

2. Build and start containers:
   ```bash
   docker compose up -d --build
   ```

3. Verify service health:
   ```bash
   docker compose ps
   ```

---

## 5. Reverse Proxy and Security Hardening

The Nginx reverse proxy configuration (`nginx/nginx.conf`) enforces the following defenses:

1. **Brute-Force Rate Limiting**:
   - `/api/auth/login` is governed by zone `login_brute_force:10m` at a strict **5 requests/second** with a burst allowance of 10.
2. **API Traffic Throttling**:
   - `/api/` is governed by zone `api_rate_limit:10m` at **30 requests/second** to mitigate volumetric DoS attempts.
3. **HTTP Strict Transport Security (HSTS)**:
   - `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
4. **Anti-Clickjacking**:
   - `X-Frame-Options: DENY`
5. **Content Security Policy (CSP)**:
   - `Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; connect-src 'self'; img-src 'self' data:; font-src 'self'; frame-ancestors 'none';`
6. **MIME Sniffing Prevention**:
   - `X-Content-Type-Options: nosniff`
7. **Buffer & Payload Limits**:
   - `client_max_body_size 2M;` prevents resource exhaustion from oversized payloads.

---

## 6. Health Checks and Monitoring

### Health Endpoint
`GET /api/health` probes both the Node.js API process and the Oracle database connection pool by issuing `SELECT 1 FROM dual`:

- **Healthy (HTTP 200)**:
  ```json
  {
    "status": "healthy",
    "service": "ucjims-backend",
    "timestamp": "2026-10-19T20:00:00.000Z",
    "database": {
      "status": "connected",
      "pool": { "open": 2, "inUse": 0 }
    }
  }
  ```
- **Degraded / DB Down (HTTP 503)**:
  ```json
  {
    "status": "degraded",
    "service": "ucjims-backend",
    "timestamp": "2026-10-19T20:00:00.000Z",
    "database": {
      "status": "disconnected",
      "error": "ORA-12541: Cannot connect to database"
    }
  }
  ```

### Structured Logging
All logs written by the application mask personal identifiers, passwords, and tokens. Web server logs format timestamps, HTTP verb, endpoint, status code, and response latency without recording query strings or sensitive JSON request payloads.

---

## 7. Database Backup and Restore Runbook

### Backup Schedule and Policies
- **Recovery Point Objective (RPO)**: <= 1 hour (maximum permissible data loss window).
- **Recovery Time Objective (RTO)**: <= 2 hours (maximum permissible recovery downtime).
- **Physical Backups (Oracle RMAN)**:
  - Daily incremental backup (Level 1) at 02:00 UTC.
  - Weekly full backup (Level 0) every Sunday at 01:00 UTC.
  - Continuous archive redo log backups every 15 minutes.
- **Logical Exports (Oracle Data Pump `expdp`)**:
  - Daily schema snapshot of `UCJIMS_OWNER` kept with 30-day retention.

### Daily Logical Backup Command:
```bash
expdp system/password@PRODPDB1 \
  schemas=UCJIMS_OWNER \
  directory=BACKUP_DIR \
  dumpfile=ucjims_backup_%U.dmp \
  logfile=ucjims_backup.log \
  compression=ALL
```

### Restoration Drill Procedure (Rehearsal):
1. Create a clean disposable rehearsal schema: `UCJIMS_RESTORE_TEST`.
2. Import the latest Data Pump snapshot:
   ```bash
   impdp system/password@PRODPDB1 \
     remap_schema=UCJIMS_OWNER:UCJIMS_RESTORE_TEST \
     directory=BACKUP_DIR \
     dumpfile=ucjims_backup_01.dmp \
     logfile=ucjims_restore.log
   ```
3. Run `database/14_stage1_validation.sql` against `UCJIMS_RESTORE_TEST`.
4. Run `database/15_stage4_db_tests.sql` to verify that all constraints, triggers, and workflows remain intact post-restoration.
5. Drop the temporary schema `UCJIMS_RESTORE_TEST`.

---

## 8. Rollback and Incident Runbook

### Application Rollback:
If an API or UI deployment introduces an unexpected regression:
1. Revert container image tags in `docker-compose.yml` to the previously approved SHA/tag.
2. Trigger deployment reload:
   ```bash
   docker compose up -d --no-deps backend frontend
   ```
3. Probe `/api/health` to confirm nominal status.

### Database Migration Rollback:
- Schema updates must use **expand/contract** design: new columns are nullable initially so older backend containers continue to operate without breaking.
- Destructive operations (dropping columns or modifying types) require a verified Data Pump export prior to execution.

### Emergency Incident Contacts:
- **Database Administrator (DBA)**: dba-oncall@ucjims.internal
- **Security Incident Response Team (SIRT)**: security@ucjims.internal
- **Application Lead**: lead@ucjims.internal
