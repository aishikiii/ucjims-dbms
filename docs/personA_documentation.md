# UCJIMS — Person A Module Documentation
### Users, Person Management, Case Registration, FIR & Investigation

## 1. Overview

Person A's module covers the front half of the case lifecycle in UCJIMS — everything that happens
before evidence collection and court proceedings begin. It answers three questions: **who** is
using the system, **who** is involved in a case, and **what** the case itself is.

This module consists of 9 tables: `ROLE`, `DEPARTMENT`, `APP_USER`, `PERSON`, `CASE_TABLE`, `FIR`,
`CASE_PERSON`, `INVESTIGATION`, and `CASE_INVESTIGATOR`.

*(Note: `CASE` and `USER` are reserved keywords in Oracle SQL, so these tables are named
`CASE_TABLE` and `APP_USER` instead.)*

## 2. Entities and Their Purpose

**ROLE** — Defines the functional roles that exist in the system (Investigator, Judge,
Prosecutor, Forensic Officer, Prison Officer, Admin, Cyber Crime Analyst). This keeps role names
centralized rather than hardcoded into the user table.

**DEPARTMENT** — Represents the organizational units in the criminal justice system (Police,
Court, Forensics, Prison, Cyber Crime Cell). Every user belongs to exactly one department.

**APP_USER** — Represents any authorized system user: investigators, judges, prosecutors,
forensic officers, prison officers, and admins. Each user is linked to a `ROLE` and a
`DEPARTMENT`, which determines what part of the system they interact with.

**PERSON** — A centralized table for anyone connected to a case in a non-system-user capacity:
accused individuals, victims, witnesses, and complainants. Keeping `PERSON` separate from
`CASE_TABLE` means the same person's basic details (name, DOB, contact info) are stored once,
even if they appear across multiple cases.

**CASE_TABLE** — The core case record: case number, type, registration/incident dates, location,
status, and priority. This is the anchor table that almost every other module (evidence, court,
prison) eventually references via `case_id`.

**FIR** — The formal First Information Report that initiates a case. Each FIR is linked to the
case it opened, the officer who filed it, and the complainant who reported it.

**CASE_PERSON** — A linking table between `CASE_TABLE` and `PERSON` that records what role a
specific person plays *in a specific case* (Accused, Victim, Witness, Complainant, Official).
This design choice — keeping role as a property of the case-person relationship rather than the
person themselves — is what allows the same person to be a witness in one case and an accused in
another, without contradiction or duplicate person records.

**INVESTIGATION** — Tracks the investigation activity for a case: start/end dates, current
status (Ongoing/Completed/Suspended), and findings.

**CASE_INVESTIGATOR** — A linking table assigning one or more `APP_USER`s (investigators) to a
case, with a role of Lead or Assistant. This allows multiple investigators to be attached to a
single case.

## 3. Relationships

- One `ROLE` can be held by many `APP_USER`s (1:N)
- One `DEPARTMENT` can contain many `APP_USER`s (1:N)
- One `CASE_TABLE` can involve many `PERSON`s, via `CASE_PERSON` (1:N)
- One `PERSON` can be involved in many `CASE_TABLE`s, via `CASE_PERSON` (N:M overall)
- One `CASE_TABLE` has exactly one `FIR` in this design (1:1)
- One `CASE_TABLE` has one `INVESTIGATION` record (1:1)
- One `CASE_TABLE` can have multiple `APP_USER`s assigned as investigators, via
  `CASE_INVESTIGATOR` (1:N)

## 4. Case Lifecycle (Person A's Scope)

```
FIR filed
   ↓
CASE registered
   ↓
People linked to case (accused, victim, witness, complainant) via CASE_PERSON
   ↓
Investigator(s) assigned via CASE_INVESTIGATOR
   ↓
INVESTIGATION opened, findings recorded
   ↓
Case handed off to Person B (Evidence) and eventually Person C (Court)
```

## 5. Queries

The module includes 7 queries covering the project's search and reporting requirement (FR11):

1. **Cases by status** — filters `CASE_TABLE` by `case_status` (e.g. all cases currently
   Under Trial)
2. **Cases by priority** — filters by `priority` (e.g. all High priority cases)
3. **Cases assigned to a specific investigator** — joins `CASE_TABLE`, `CASE_INVESTIGATOR`, and
   `APP_USER` to find every case a given investigator is working on
4. **Cases involving a specific person** — joins `CASE_TABLE`, `CASE_PERSON`, and `PERSON` to
   find every case a given individual appears in, and in what role
5. **FIR lookup by number** — retrieves the FIR, its parent case, and the complainant given an
   FIR number
6. **Investigation history for a case** — retrieves all investigation records tied to a case ID
7. **Case count by status** — a grouped summary query showing how many cases fall into each
   status, useful for reporting/dashboards

## 6. View: CASE_SUMMARY_VIEW

Rather than repeating the same multi-table JOIN every time a full case picture is needed,
`CASE_SUMMARY_VIEW` combines `CASE_TABLE`, `CASE_PERSON`, `PERSON`, `INVESTIGATION`, and
`CASE_INVESTIGATOR`/`APP_USER` into a single queryable view. It surfaces, for any case: the case
details, everyone involved and their role, the investigation status, and the assigned
investigator's name and role.

This is Person A's advanced DBMS feature (Phase 6), matching the view/complex-join requirement
given to this module, in parallel with Person B's trigger/audit work and Person C's stored
procedures/functions.

## 7. Sample Data Summary

| Table | Rows |
|---|---|
| ROLE | 7 |
| DEPARTMENT | 5 |
| APP_USER | 15 |
| PERSON | 40 |
| CASE_TABLE | 15 |
| FIR | 15 |
| CASE_PERSON | 47 |
| INVESTIGATION | 15 |
| CASE_INVESTIGATOR | 17 |

15 distinct case types are represented (theft, assault, fraud, burglary, cybercrime, homicide,
kidnapping, robbery, extortion, domestic violence, smuggling, forgery, arson, drug trafficking,
vandalism), giving Person B and Person C a varied set of cases to build evidence and court
records against.
