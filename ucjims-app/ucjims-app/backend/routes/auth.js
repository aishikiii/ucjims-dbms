// Login endpoint: looks up the user by username, verifies password with bcrypt,
// and issues a JWT carrying their role name (so the frontend can route them
// to the right dashboard and the backend can authorize every later request).
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getConnection, oracledb } = require('../config/db');

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

    const user = result.rows[0];
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
      process.env.JWT_SECRET,
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
    console.error('Login error:', err.message);
    res.status(500).json({ error: 'Internal server error' });
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
