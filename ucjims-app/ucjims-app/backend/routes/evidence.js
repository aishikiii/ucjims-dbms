// Evidence and forensics custody endpoints (Person B module).
// Forensic Officers, Investigators, Judges, Prosecutors and Admins can view evidence.
// Only Forensic Officers and Admins can record custody transfers.
const express = require('express');
const { getConnection, oracledb } = require('../config/db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { sendDbError } = require('../utils/dbError');

const router = express.Router();
router.use(requireAuth);

// GET /api/evidence - list evidence with optional ?case_id= filter
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
    sendDbError(res, err, 'Failed to fetch evidence');
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
       FROM CHAIN_OF_CUSTODY WHERE evidence_id = :id ORDER BY transfer_date_time, custody_id`,
      { id: req.params.id }
    );
    res.json(result.rows);
  } catch (err) {
    sendDbError(res, err, 'Failed to fetch custody history');
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/evidence/:id/transfer - record a custody transfer
// Calls hardened TRANSFER_EVIDENCE workflow procedure from Stage 1,
// which maintains append-only history, updates current status, and triggers audit.
router.post('/:id/transfer', requireRole('Forensic Officer', 'Admin'), async (req, res) => {
  const { to_user_id, transfer_location, storage_location, purpose, condition, remarks, from_user_id } = req.body;
  if (!transfer_location || !purpose) {
    return res.status(400).json({ error: 'transfer_location and purpose are required' });
  }

  let conn;
  try {
    conn = await getConnection();

    try {
      // Primary hardened path: Stage 1 stored procedure
      const result = await conn.execute(
        `BEGIN
           TRANSFER_EVIDENCE(
             p_evidence_id        => :evidence_id,
             p_to_user_id         => :to_user_id,
             p_transfer_date_time => SYSDATE,
             p_transfer_location  => :transfer_location,
             p_storage_location   => :storage_location,
             p_purpose            => :purpose,
             p_condition          => :condition,
             p_remarks            => :remarks,
             p_custody_id         => :custody_id
           );
         END;`,
        {
          evidence_id: Number(req.params.id),
          to_user_id: to_user_id ? Number(to_user_id) : null,
          transfer_location,
          storage_location: storage_location || transfer_location,
          purpose,
          condition: condition || 'Sealed',
          remarks: remarks || null,
          custody_id: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
        }
      );
      await conn.commit();
      res.status(201).json({ custody_id: result.outBinds.custody_id });
    } catch (procErr) {
      // Fallback only if procedure has not been compiled on the database
      if (procErr.errorNum === 6550 || procErr.errorNum === 904) {
        const idResult = await conn.execute(`SELECT NVL(MAX(custody_id), 0) + 1 AS next_id FROM CHAIN_OF_CUSTODY`);
        const newId = idResult.rows[0].NEXT_ID;

        await conn.execute(
          `INSERT INTO CHAIN_OF_CUSTODY (custody_id, evidence_id, from_user_id, to_user_id,
              transfer_date_time, transfer_location, purpose, condition, remarks)
           VALUES (:id, :evidence_id, :from_user_id, :to_user_id, SYSDATE, :transfer_location,
              :purpose, :condition, :remarks)`,
          {
            id: newId,
            evidence_id: req.params.id,
            from_user_id: from_user_id || req.user.userId,
            to_user_id: to_user_id || null,
            transfer_location,
            purpose,
            condition: condition || 'Sealed',
            remarks: remarks || null,
          }
        );
        await conn.commit();
        res.status(201).json({ custody_id: newId });
      } else {
        throw procErr;
      }
    }
  } catch (err) {
    if (conn) await conn.rollback();
    sendDbError(res, err, 'Failed to record custody transfer');
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
