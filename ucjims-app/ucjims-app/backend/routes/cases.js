// Case/investigation endpoints (Person A module).
// Investigators, Admins, Judges and Prosecutors can read case data;
// only Investigators/Admins can register new cases.
const express = require('express');
const { getConnection, oracledb } = require('../config/db');
const { requireAuth, requireRole } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

// GET /api/cases - list cases, optional ?status= filter
router.get('/', requireRole('Investigator', 'Admin', 'Judge', 'Prosecutor', 'Cyber Crime Analyst'), async (req, res) => {
  const { status } = req.query;
  let conn;
  try {
    conn = await getConnection();
    const sql = status
      ? `SELECT case_id, case_number, case_type, case_status, priority, registration_date
         FROM CASE_TABLE WHERE case_status = :status ORDER BY case_id`
      : `SELECT case_id, case_number, case_type, case_status, priority, registration_date
         FROM CASE_TABLE ORDER BY case_id`;
    const binds = status ? { status } : {};
    const result = await conn.execute(sql, binds);
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Failed to fetch cases' });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/cases/:id - full case summary (uses CASE_SUMMARY_VIEW from Person A)
router.get('/:id', requireRole('Investigator', 'Admin', 'Judge', 'Prosecutor', 'Cyber Crime Analyst'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT * FROM CASE_SUMMARY_VIEW WHERE case_id = :id`,
      { id: req.params.id }
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Case not found' });
    }
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Failed to fetch case detail' });
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/cases - register a new case + FIR in one transaction
router.post('/', requireRole('Investigator', 'Admin'), async (req, res) => {
  const { case_number, case_type, incident_date, incident_location, description, priority,
          fir_number, filed_by_user_id, complainant_id, station_name, fir_details } = req.body;

  if (!case_number || !case_type || !fir_number) {
    return res.status(400).json({ error: 'case_number, case_type and fir_number are required' });
  }

  let conn;
  try {
    conn = await getConnection();

    const caseIdResult = await conn.execute(
      `SELECT NVL(MAX(case_id), 0) + 1 AS next_id FROM CASE_TABLE`
    );
    const newCaseId = caseIdResult.rows[0].NEXT_ID;

    await conn.execute(
      `INSERT INTO CASE_TABLE (case_id, case_number, case_type, registration_date,
          incident_date, incident_location, description, case_status, priority)
       VALUES (:id, :case_number, :case_type, SYSDATE, TO_DATE(:incident_date,'YYYY-MM-DD'),
          :incident_location, :description, 'OPEN', :priority)`,
      { id: newCaseId, case_number, case_type, incident_date, incident_location, description, priority }
    );

    const firIdResult = await conn.execute(`SELECT NVL(MAX(fir_id), 0) + 1 AS next_id FROM FIR`);
    const newFirId = firIdResult.rows[0].NEXT_ID;

    await conn.execute(
      `INSERT INTO FIR (fir_id, case_id, filed_by_user_id, complainant_id, fir_number,
          filing_date, station_name, fir_details)
       VALUES (:fir_id, :case_id, :filed_by_user_id, :complainant_id, :fir_number,
          SYSDATE, :station_name, :fir_details)`,
      { fir_id: newFirId, case_id: newCaseId, filed_by_user_id, complainant_id, fir_number, station_name, fir_details }
    );

    await conn.commit();
    res.status(201).json({ case_id: newCaseId, fir_id: newFirId, case_number, fir_number });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(err.message);
    res.status(500).json({ error: 'Failed to register case', detail: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
