// Run once after your Oracle schema is populated: hashes a unique demo password
// for one user per role, so each role has its own working login for the demo
// instead of everyone sharing the same password.
// This replaces the placeholder 'hash_pw_NNN' strings from the seed data with
// real bcrypt hashes. Prints the demo credentials AND writes them to
// demo_credentials.txt (gitignored) so you don't have to scroll back for them.
require('dotenv').config();
const bcrypt = require('bcryptjs');
const fs = require('fs');
const path = require('path');
const { getConnection, closePool } = require('../config/db');

// Generates a short, readable random password like "Kv7mQ2pL" - good enough
// for a demo, not for anything that needs to survive past the presentation.
function generatePassword() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  let pw = '';
  for (let i = 0; i < 8; i++) {
    pw += chars[Math.floor(Math.random() * chars.length)];
  }
  return pw;
}

async function main() {
  let conn;
  const credentials = [];

  try {
    conn = await getConnection();

    // One demo user per role: pick the first APP_USER row for each role_id
    const roles = await conn.execute(`SELECT role_id, role_name FROM ROLE ORDER BY role_id`);

    for (const role of roles.rows) {
      const userResult = await conn.execute(
        `SELECT user_id, username FROM APP_USER WHERE role_id = :role_id AND ROWNUM = 1`,
        { role_id: role.ROLE_ID }
      );
      const user = userResult.rows[0];
      if (!user) continue;

      const password = generatePassword();
      const hash = await bcrypt.hash(password, 10);

      await conn.execute(
        `UPDATE APP_USER SET password_hash = :hash WHERE user_id = :user_id`,
        { hash, user_id: user.USER_ID }
      );

      credentials.push({ role: role.ROLE_NAME, username: user.USERNAME, password });
    }

    await conn.commit();

    const lines = [
      'UCJIMS demo credentials - generated ' + new Date().toISOString(),
      'Each role has its own password now (not shared). Keep this file local; it is gitignored.',
      '',
      ...credentials.map((c) => `${c.role.padEnd(20)} username: ${c.username.padEnd(14)} password: ${c.password}`),
      '',
    ];
    const outPath = path.join(__dirname, 'demo_credentials.txt');
    fs.writeFileSync(outPath, lines.join('\n'));

    console.log(lines.join('\n'));
    console.log(`Saved to ${outPath}`);
    console.log('Demo users updated. Use these to log in via POST /api/auth/login.');
  } catch (err) {
    console.error('Failed to set up demo users:', err.message);
    if (conn) await conn.rollback();
  } finally {
    if (conn) await conn.close();
    await closePool();
  }
}

main();
