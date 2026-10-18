// Run once after your Oracle schema is populated: hashes a known demo password
// for one user per role, so you have working login credentials for the demo.
// This replaces the placeholder 'hash_pw_NNN' strings from the seed data with
// real bcrypt hashes. Prints the demo credentials - rotate/remove after use.
require('dotenv').config();
const bcrypt = require('bcryptjs');
const { getConnection, closePool } = require('../config/db');

const DEMO_PASSWORD = 'Demo@1234'; // same password for every demo account, for convenience

async function main() {
  let conn;
  try {
    conn = await getConnection();
    const hash = await bcrypt.hash(DEMO_PASSWORD, 10);

    // One demo user per role: pick the first APP_USER row for each role_id
    const roles = await conn.execute(`SELECT role_id, role_name FROM ROLE ORDER BY role_id`);

    console.log('Demo credentials (password is the same for all):\n');
    console.log(`Password: ${DEMO_PASSWORD}\n`);

    for (const role of roles.rows) {
      const userResult = await conn.execute(
        `SELECT user_id, username FROM APP_USER WHERE role_id = :role_id AND ROWNUM = 1`,
        { role_id: role.ROLE_ID }
      );
      const user = userResult.rows[0];
      if (!user) continue;

      await conn.execute(
        `UPDATE APP_USER SET password_hash = :hash WHERE user_id = :user_id`,
        { hash, user_id: user.USER_ID }
      );

      console.log(`${role.ROLE_NAME.padEnd(20)} username: ${user.USERNAME}`);
    }

    await conn.commit();
    console.log('\nDemo users updated. Use these to log in via POST /api/auth/login.');
  } catch (err) {
    console.error('Failed to set up demo users:', err.message);
    if (conn) await conn.rollback();
  } finally {
    if (conn) await conn.close();
    await closePool();
  }
}

main();
