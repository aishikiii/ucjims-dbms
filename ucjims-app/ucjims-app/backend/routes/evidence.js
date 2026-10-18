// Evidence/forensics endpoints (Person B module).
// Forensic Officers and Investigators can view; only Forensic Officers/Admin
// can log a custody transfer (the DB trigger then auto-writes the audit row).
const express = require('express');
const { getConnection } = require('../config/db');
const { requireAuth, requireRole } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

// GET /api/evidence?case_id=1
router.get('/', requireRole('Forensic Officer', 'Investigator', 'Admin', 'Judge', 'Prosecutor'), async (req, res) => {
  const { case_id } = req.query;
  let conn;
  try {
    conn = await getConnection();
    const sql = case_id
      ? `SELECT evidence_id, case_id, evidence_type, description, collection_date,
                storage_location, current_status
         FROM EVIDENCE WHERE case_id = :case_id ORDER BY evidence_id`
      : `SELECT evidence_id, case_id, evidence_type, description, collection_date,
                storage_location, current_status
         FROM EVIDENCE ORDER BY evidence_id`;
    const result = await conn.execute(sql, case_id ? { case_id } : {});
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Failed to fetch evidence' });
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/evidence/:id/custody - full chain of custody for one evidence item
router.get('/:id/custody', requireRole('Forensic Officer', 'Investigator', 'Admin', 'Judge', 'Prosecutor'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT custody_id, from_user_id, to_user_id, transfer_date_time,
              transfer_location, purpose, condition, remarks
       FROM CHAIN_OF_CUSTODY WHERE evidence_id = :id ORDER BY transfer_date_time`,
      { id: req.params.id }
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Failed to fetch custody history' });
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/evidence/:id/transfer - record a custody transfer
// (the EVIDENCE_AUDIT trigger from Person B fires automatically on this insert)
router.post('/:id/transfer', requireRole('Forensic Officer', 'Admin'), async (req, res) => {
  const { from_user_id, to_user_id, transfer_location, purpose, condition, remarks } = req.body;
  if (!to_user_id || !transfer_location) {
    return res.status(400).json({ error: 'to_user_id and transfer_location are required' });
  }

  let conn;
  try {
    conn = await getConnection();
    const idResult = await conn.execute(`SELECT NVL(MAX(custody_id), 0) + 1 AS next_id FROM CHAIN_OF_CUSTODY`);
    const newId = idResult.rows[0].NEXT_ID;

    await conn.execute(
      `INSERT INTO CHAIN_OF_CUSTODY (custody_id, evidence_id, from_user_id, to_user_id,
          transfer_date_time, transfer_location, purpose, condition, remarks)
       VALUES (:id, :evidence_id, :from_user_id, :to_user_id, SYSDATE, :transfer_location,
          :purpose, :condition, :remarks)`,
      { id: newId, evidence_id: req.params.id, from_user_id, to_user_id, transfer_location, purpose, condition, remarks }
    );
    await conn.commit();
    res.status(201).json({ custody_id: newId });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(err.message);
    res.status(500).json({ error: 'Failed to record transfer', detail: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
