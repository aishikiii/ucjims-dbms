// Court/judgment/prison endpoints (Person C module).
const express = require('express');
const { getConnection } = require('../config/db');
const { requireAuth, requireRole } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth);

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
    console.error(err.message);
    res.status(500).json({ error: 'Failed to fetch hearings' });
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
      ? `SELECT judgment_id, case_id, judgment_date, verdict, judgment_summary
         FROM JUDGMENT WHERE case_id = :case_id`
      : `SELECT judgment_id, case_id, judgment_date, verdict, judgment_summary FROM JUDGMENT ORDER BY judgment_date DESC`;
    const result = await conn.execute(sql, case_id ? { case_id } : {});
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Failed to fetch judgments' });
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
      `SELECT i.inmate_id, p.full_name AS inmate_name, pr.prison_name, i.admission_date,
              i.expected_release_date, i.status
       FROM INMATE i
       JOIN PERSON p ON i.person_id = p.person_id
       JOIN PRISON pr ON i.prison_id = pr.prison_id
       ORDER BY i.inmate_id`
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Failed to fetch inmates' });
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
    const idResult = await conn.execute(`SELECT NVL(MAX(hearing_id), 0) + 1 AS next_id FROM HEARING`);
    const newId = idResult.rows[0].NEXT_ID;

    await conn.execute(
      `INSERT INTO HEARING (hearing_id, case_id, court_id, judge_id, hearing_date,
          hearing_type, courtroom, hearing_status)
       VALUES (:id, :case_id, :court_id, :judge_id, TO_DATE(:hearing_date,'YYYY-MM-DD'),
          :hearing_type, :courtroom, 'SCHEDULED')`,
      { id: newId, case_id, court_id: court_id || null, judge_id: judge_id || null, hearing_date, hearing_type, courtroom: courtroom || null }
    );
    await conn.commit();
    res.status(201).json({ hearing_id: newId });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(err.message);
    res.status(500).json({ error: 'Failed to schedule hearing', detail: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// POST /api/court/judgments - record a judgment
router.post('/judgments', requireRole('Judge', 'Admin'), async (req, res) => {
  const { case_id, verdict, judgment_summary } = req.body;
  if (!case_id || !verdict) {
    return res.status(400).json({ error: 'case_id and verdict are required' });
  }

  let conn;
  try {
    conn = await getConnection();
    const idResult = await conn.execute(`SELECT NVL(MAX(judgment_id), 0) + 1 AS next_id FROM JUDGMENT`);
    const newId = idResult.rows[0].NEXT_ID;

    await conn.execute(
      `INSERT INTO JUDGMENT (judgment_id, case_id, judgment_date, verdict, judgment_summary)
       VALUES (:id, :case_id, SYSDATE, :verdict, :judgment_summary)`,
      { id: newId, case_id, verdict, judgment_summary: judgment_summary || null }
    );
    await conn.commit();
    res.status(201).json({ judgment_id: newId });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(err.message);
    res.status(500).json({ error: 'Failed to record judgment', detail: err.message });
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
    const idResult = await conn.execute(`SELECT NVL(MAX(inmate_id), 0) + 1 AS next_id FROM INMATE`);
    const newId = idResult.rows[0].NEXT_ID;

    await conn.execute(
      `INSERT INTO INMATE (inmate_id, person_id, prison_id, admission_date, expected_release_date, status)
       VALUES (:id, :person_id, :prison_id, SYSDATE, TO_DATE(:expected_release_date,'YYYY-MM-DD'), 'INCARCERATED')`,
      { id: newId, person_id, prison_id, expected_release_date: expected_release_date || null }
    );
    await conn.commit();
    res.status(201).json({ inmate_id: newId });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(err.message);
    res.status(500).json({ error: 'Failed to admit inmate', detail: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

// PATCH /api/court/inmates/:id/release - mark an inmate released
router.patch('/inmates/:id/release', requireRole('Prison Officer', 'Admin'), async (req, res) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `UPDATE INMATE SET status = 'RELEASED' WHERE inmate_id = :id`,
      { id: req.params.id }
    );
    if (result.rowsAffected === 0) {
      await conn.rollback();
      return res.status(404).json({ error: 'Inmate not found' });
    }
    await conn.commit();
    res.json({ inmate_id: Number(req.params.id), status: 'RELEASED' });
  } catch (err) {
    if (conn) await conn.rollback();
    console.error(err.message);
    res.status(500).json({ error: 'Failed to release inmate', detail: err.message });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
