// Login and session endpoints:
// Verifies user credentials using bcrypt, checks active account status,
// and issues JWT tokens containing the canonical role name for server-side RBAC.
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getConnection, oracledb } = require('../config/db');
const { requireAuth } = require('../middleware/auth');
const { sendDbError } = require('../utils/dbError');

const router = express.Router();

router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: 'username and password are required' });
  }

  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      `SELECT u.user_id, u.full_name, u.username, u.password_hash, u.status,
              r.role_name, u.department_id
       FROM APP_USER u
       JOIN ROLE r ON u.role_id = r.role_id
       WHERE u.username = :username`,
      { username },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    const user = result.rows && result.rows[0];
    if (!user) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }
    if (user.STATUS !== 'ACTIVE') {
      return res.status(403).json({ error: 'Account is inactive' });
    }

    const passwordOk = await bcrypt.compare(password, user.PASSWORD_HASH);
    if (!passwordOk) {
      return res.status(401).json({ error: 'Invalid username or password' });
    }

    const token = jwt.sign(
      {
        userId: user.USER_ID,
        username: user.USERNAME,
        fullName: user.FULL_NAME,
        roleName: user.ROLE_NAME,
        deptId: user.DEPARTMENT_ID,
      },
      process.env.JWT_SECRET || 'ucjims_default_secret_key_change_in_production',
      { expiresIn: process.env.JWT_EXPIRES_IN || '8h' }
    );

    res.json({
      token,
      user: {
        userId: user.USER_ID,
        fullName: user.FULL_NAME,
        username: user.USERNAME,
        roleName: user.ROLE_NAME,
      },
    });
  } catch (err) {
    sendDbError(res, err, 'Login failed');
  } finally {
    if (conn) await conn.close();
  }
});

// GET /api/auth/me - inspect current authenticated session
router.get('/me', requireAuth, (req, res) => {
  res.json({ user: req.user });
});

module.exports = router;
