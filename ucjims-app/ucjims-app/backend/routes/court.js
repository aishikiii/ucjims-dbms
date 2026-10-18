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

module.exports = router;
