// Case and FIR registration endpoints (Person A module).
// Investigators, Admins, Judges, Prosecutors and Cyber Crime Analysts can read cases.
// Only Investigators and Admins can register new cases and FIRs.
const express = require('express');
const { getConnection } = require('../config/db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { sendDbError } = require('../utils/dbError');

const router = express.Router();
router.use(requireAuth);

// Helper for sequence-backed primary key generation with fallback
async function getNextId(conn, sequenceName, tableName, pkColumn) {
  try {
    const seqResult = await conn.execute(`SELECT ${sequenceName}.NEXTVAL AS next_id FROM dual`);
    return seqResult.rows[0].NEXT_ID;
  } catch (err) {
    if (err.errorNum === 2289) {
      const maxResult = await conn.execute(`SELECT NVL(MAX(${pkColumn}), 0) + 1 AS next_id FROM ${tableName}`);
      return maxResult.rows[0].NEXT_ID;
    }
    throw err;
  }
}

// GET /api/cases - list cases with optional ?status= filter
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
    sendDbError(res, err, 'Failed to fetch cases');
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/cases/:id - full case summary view
router.get('/:id', requireRole('Investigator', 'Admin', 'Judge', 'Prosecutor', 'Cyber Crime Analyst'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT * FROM CASE_SUMMARY_VIEW WHERE case_id = :id`,
      { id: req.params.id }
    );
    if (!result.rows || result.rows.length === 0) {
      return res.status(404).json({ error: 'Case not found' });
    }
    res.json(result.rows);
  } catch (err) {
    sendDbError(res, err, 'Failed to fetch case detail');
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/cases - register a new case + FIR atomically in a single transaction
router.post('/', requireRole('Investigator', 'Admin'), async (req, res) => {
  const {
    case_number,
    case_type,
    incident_date,
    incident_location,
    description,
    priority,
    fir_number,
    filed_by_user_id,
    complainant_id,
    station_name,
    fir_details,
  } = req.body;

  if (!case_number || !case_type || !fir_number) {
    return res.status(400).json({ error: 'case_number, case_type and fir_number are required' });
  }

  let conn;
  try {
    conn = await getConnection();

    const newCaseId = await getNextId(conn, 'SEQ_CASE_TABLE', 'CASE_TABLE', 'case_id');

    await conn.execute(
      `INSERT INTO CASE_TABLE (case_id, case_number, case_type, registration_date,
          incident_date, incident_location, description, case_status, priority)
       VALUES (:id, :case_number, :case_type, SYSDATE,
          ${incident_date ? "TO_DATE(:incident_date, 'YYYY-MM-DD')" : 'NULL'},
          :incident_location, :description, 'OPEN', :priority)`,
      {
        id: newCaseId,
        case_number,
        case_type,
        ...(incident_date ? { incident_date } : {}),
        incident_location: incident_location || null,
        description: description || null,
        priority: priority || 'MEDIUM',
      }
    );

    const newFirId = await getNextId(conn, 'SEQ_FIR', 'FIR', 'fir_id');

    await conn.execute(
      `INSERT INTO FIR (fir_id, case_id, filed_by_user_id, complainant_id, fir_number,
          filing_date, station_name, fir_details)
       VALUES (:fir_id, :case_id, :filed_by_user_id, :complainant_id, :fir_number,
          SYSDATE, :station_name, :fir_details)`,
      {
        fir_id: newFirId,
        case_id: newCaseId,
        filed_by_user_id: filed_by_user_id || req.user.userId,
        complainant_id: complainant_id || null,
        fir_number,
        station_name: station_name || null,
        fir_details: fir_details || null,
      }
    );

    await conn.commit();
    res.status(201).json({
      case_id: newCaseId,
      fir_id: newFirId,
      case_number,
      fir_number,
    });
  } catch (err) {
    if (conn) await conn.rollback();
    sendDbError(res, err, 'Failed to register case');
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
