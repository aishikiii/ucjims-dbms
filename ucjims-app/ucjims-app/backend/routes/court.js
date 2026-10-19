// Court, hearings, judgments, and prison/inmate endpoints (Person C module).
// Judges and Prosecutors can view court records; Judges can record hearings/judgments.
// Prison Officers can manage inmates (admission, transfer, release).
const express = require('express');
const { getConnection, oracledb } = require('../config/db');
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

// GET /api/court/hearings?case_id=1
router.get('/hearings', requireRole('Judge', 'Prosecutor', 'Admin', 'Investigator'), async (req, res) => {
  const { case_id } = req.query;
  let conn;
  try {
    conn = await getConnection();
    const sql = case_id
      ? `SELECT hearing_id, case_id, court_id, judge_id, hearing_date, hearing_type,
                courtroom, hearing_status FROM HEARING WHERE case_id = :case_id ORDER BY hearing_date`
      : `SELECT hearing_id, case_id, court_id, judge_id, hearing_date, hearing_type,
                courtroom, hearing_status FROM HEARING ORDER BY hearing_date`;
    const result = await conn.execute(sql, case_id ? { case_id } : {});
    res.json(result.rows);
  } catch (err) {
    sendDbError(res, err, 'Failed to fetch hearings');
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/court/judgments?case_id=1
router.get('/judgments', requireRole('Judge', 'Prosecutor', 'Admin'), async (req, res) => {
  const { case_id } = req.query;
  let conn;
  try {
    conn = await getConnection();
    const sql = case_id
      ? `SELECT judgment_id, case_id, hearing_id, judgment_date, verdict, judgment_summary
         FROM JUDGMENT WHERE case_id = :case_id ORDER BY judgment_date DESC`
      : `SELECT judgment_id, case_id, hearing_id, judgment_date, verdict, judgment_summary
         FROM JUDGMENT ORDER BY judgment_date DESC`;
    const result = await conn.execute(sql, case_id ? { case_id } : {});
    res.json(result.rows);
  } catch (err) {
    sendDbError(res, err, 'Failed to fetch judgments');
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/court/inmates - prison officer view
router.get('/inmates', requireRole('Prison Officer', 'Admin'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT i.inmate_id, i.person_id, p.full_name AS inmate_name, i.prison_id, pr.prison_name,
              i.admission_date, i.expected_release_date, i.actual_release_date, i.status
       FROM INMATE i
       JOIN PERSON p ON i.person_id = p.person_id
       JOIN PRISON pr ON i.prison_id = pr.prison_id
       ORDER BY i.inmate_id`
    );
    res.json(result.rows);
  } catch (err) {
    sendDbError(res, err, 'Failed to fetch inmates');
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/court/hearings - schedule a hearing
router.post('/hearings', requireRole('Judge', 'Admin'), async (req, res) => {
  const { case_id, court_id, judge_id, hearing_date, hearing_type, courtroom } = req.body;
  if (!case_id || !hearing_date || !hearing_type) {
    return res.status(400).json({ error: 'case_id, hearing_date and hearing_type are required' });
  }

  let conn;
  try {
    conn = await getConnection();
    const newId = await getNextId(conn, 'SEQ_HEARING', 'HEARING', 'hearing_id');

    await conn.execute(
      `INSERT INTO HEARING (hearing_id, case_id, court_id, judge_id, hearing_date,
          hearing_type, courtroom, hearing_status)
       VALUES (:id, :case_id, :court_id, :judge_id, TO_DATE(:hearing_date,'YYYY-MM-DD'),
          :hearing_type, :courtroom, 'SCHEDULED')`,
      {
        id: newId,
        case_id,
        court_id: court_id || 1,
        judge_id: judge_id || req.user.userId,
        hearing_date,
        hearing_type,
        courtroom: courtroom || null,
      }
    );
    await conn.commit();
    res.status(201).json({ hearing_id: newId });
  } catch (err) {
    if (conn) await conn.rollback();
    sendDbError(res, err, 'Failed to schedule hearing');
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/court/judgments - record a judgment linked to a completed hearing
router.post('/judgments', requireRole('Judge', 'Admin'), async (req, res) => {
  const { case_id, hearing_id, verdict, judgment_summary } = req.body;
  if (!case_id || !hearing_id || !verdict) {
    return res.status(400).json({ error: 'case_id, hearing_id and verdict are required' });
  }

  let conn;
  try {
    conn = await getConnection();
    const newId = await getNextId(conn, 'SEQ_JUDGMENT', 'JUDGMENT', 'judgment_id');

    await conn.execute(
      `INSERT INTO JUDGMENT (judgment_id, case_id, hearing_id, judgment_date, verdict, judgment_summary)
       VALUES (:id, :case_id, :hearing_id, SYSDATE, :verdict, :judgment_summary)`,
      {
        id: newId,
        case_id,
        hearing_id,
        verdict,
        judgment_summary: judgment_summary || null,
      }
    );
    await conn.commit();
    res.status(201).json({ judgment_id: newId });
  } catch (err) {
    if (conn) await conn.rollback();
    sendDbError(res, err, 'Failed to record judgment');
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/court/inmates - admit an inmate
router.post('/inmates', requireRole('Prison Officer', 'Admin'), async (req, res) => {
  const { person_id, prison_id, expected_release_date } = req.body;
  if (!person_id || !prison_id) {
    return res.status(400).json({ error: 'person_id and prison_id are required' });
  }

  let conn;
  try {
    conn = await getConnection();
    const newId = await getNextId(conn, 'SEQ_INMATE', 'INMATE', 'inmate_id');

    await conn.execute(
      `INSERT INTO INMATE (inmate_id, person_id, prison_id, admission_date, expected_release_date, status)
       VALUES (:id, :person_id, :prison_id, SYSDATE,
          ${expected_release_date ? "TO_DATE(:expected_release_date,'YYYY-MM-DD')" : 'NULL'},
          'INCARCERATED')`,
      {
        id: newId,
        person_id,
        prison_id,
        ...(expected_release_date ? { expected_release_date } : {}),
      }
    );
    await conn.commit();
    res.status(201).json({ inmate_id: newId });
  } catch (err) {
    if (conn) await conn.rollback();
    sendDbError(res, err, 'Failed to admit inmate');
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/court/inmates/:id/transfer - transfer an inmate between facilities
// Calls hardened TRANSFER_INMATE workflow procedure from Stage 1
router.post('/inmates/:id/transfer', requireRole('Prison Officer', 'Admin'), async (req, res) => {
  const { to_prison_id, reason } = req.body;
  if (!to_prison_id || !reason) {
    return res.status(400).json({ error: 'to_prison_id and reason are required' });
  }

  let conn;
  try {
    conn = await getConnection();

    try {
      await conn.execute(
        `BEGIN
           TRANSFER_INMATE(
             p_inmate_id     => :inmate_id,
             p_to_prison_id  => :to_prison_id,
             p_transfer_date => SYSDATE,
             p_reason        => :reason
           );
         END;`,
        {
          inmate_id: Number(req.params.id),
          to_prison_id: Number(to_prison_id),
          reason,
        }
      );
      await conn.commit();
      res.json({ inmate_id: Number(req.params.id), to_prison_id: Number(to_prison_id), status: 'TRANSFERRED' });
    } catch (procErr) {
      if (procErr.errorNum === 6550 || procErr.errorNum === 904) {
        // Fallback for legacy database
        const transferId = await getNextId(conn, 'SEQ_PRISON_TRANSFER', 'PRISON_TRANSFER', 'transfer_id');
        const currentPrisonRes = await conn.execute(
          `SELECT prison_id FROM INMATE WHERE inmate_id = :id`,
          { id: req.params.id }
        );
        const fromPrisonId = currentPrisonRes.rows[0]?.PRISON_ID;

        await conn.execute(
          `INSERT INTO PRISON_TRANSFER (transfer_id, inmate_id, from_prison_id, to_prison_id, transfer_date, reason)
           VALUES (:transfer_id, :inmate_id, :from_prison_id, :to_prison_id, SYSDATE, :reason)`,
          {
            transfer_id: transferId,
            inmate_id: req.params.id,
            from_prison_id: fromPrisonId,
            to_prison_id,
            reason,
          }
        );
        await conn.execute(
          `UPDATE INMATE SET prison_id = :to_prison_id WHERE inmate_id = :inmate_id`,
          { to_prison_id, inmate_id: req.params.id }
        );
        await conn.commit();
        res.json({ inmate_id: Number(req.params.id), to_prison_id: Number(to_prison_id), status: 'TRANSFERRED' });
      } else {
        throw procErr;
      }
    }
  } catch (err) {
    if (conn) await conn.rollback();
    sendDbError(res, err, 'Failed to transfer inmate');
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /api/court/inmates/:id/release - mark an inmate released
// Calls hardened RELEASE_INMATE workflow procedure from Stage 1 to set status AND actual_release_date
router.patch('/inmates/:id/release', requireRole('Prison Officer', 'Admin'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();

    try {
      await conn.execute(
        `BEGIN
           RELEASE_INMATE(
             p_inmate_id           => :inmate_id,
             p_actual_release_date => SYSDATE
           );
         END;`,
        { inmate_id: Number(req.params.id) }
      );
      await conn.commit();
      res.json({ inmate_id: Number(req.params.id), status: 'RELEASED' });
    } catch (procErr) {
      if (procErr.errorNum === 6550 || procErr.errorNum === 904) {
        // Fallback for legacy database: must update actual_release_date to satisfy chk_inmate_release_state
        const result = await conn.execute(
          `UPDATE INMATE
           SET status = 'RELEASED',
               actual_release_date = SYSDATE
           WHERE inmate_id = :id AND status = 'INCARCERATED'`,
          { id: req.params.id }
        );
        if (result.rowsAffected === 0) {
          await conn.rollback();
          return res.status(404).json({ error: 'Inmate not found or already released' });
        }
        await conn.commit();
        res.json({ inmate_id: Number(req.params.id), status: 'RELEASED' });
      } else {
        throw procErr;
      }
    }
  } catch (err) {
    if (conn) await conn.rollback();
    sendDbError(res, err, 'Failed to release inmate');
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
