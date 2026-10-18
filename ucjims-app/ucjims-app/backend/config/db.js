// Oracle connection pool - the ONLY place in the app that touches raw DB credentials.
// Routes/services borrow a connection from this pool and release it when done.
require('dotenv').config();
const oracledb = require('oracledb');

oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT; // rows come back as {column: value} objects
oracledb.autoCommit = false; // we commit explicitly inside each write operation

let pool;

async function initPool() {
  if (pool) return pool;
  pool = await oracledb.createPool({
    user: process.env.ORACLE_USER,
    password: process.env.ORACLE_PASSWORD,
    connectString: process.env.ORACLE_CONNECT_STRING,
    poolMin: 2,
    poolMax: 10,
    poolIncrement: 1,
  });
  console.log('Oracle connection pool created');
  return pool;
}

async function getConnection() {
  if (!pool) await initPool();
  return pool.getConnection();
}

async function closePool() {
  if (pool) {
    await pool.close(10);
    pool = null;
  }
}

module.exports = { initPool, getConnection, closePool, oracledb };
