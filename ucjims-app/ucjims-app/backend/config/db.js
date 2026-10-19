// Oracle connection pool - the ONLY place in the app that touches raw DB credentials.
// Routes/services borrow a connection from this pool and release it when done.
require('dotenv').config();
const oracledb = require('oracledb');

oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT; // rows come back as {column: value} objects
oracledb.autoCommit = false; // we commit explicitly inside each write operation

let pool;

async function initPool() {
  if (pool) return pool;

  const poolConfig = {
    user: process.env.ORACLE_USER,
    password: process.env.ORACLE_PASSWORD,
    connectString: process.env.ORACLE_CONNECT_STRING,
    poolMin: Number(process.env.ORACLE_POOL_MIN || 2),
    poolMax: Number(process.env.ORACLE_POOL_MAX || 10),
    poolIncrement: 1,
  };

  // Stage 5 least-privilege connection: if ORACLE_SCHEMA is set (e.g. UCJIMS_OWNER),
  // switch the session's current schema so unqualified table/procedure names resolve.
  if (process.env.ORACLE_SCHEMA) {
    poolConfig.sessionCallback = (conn, tag, cb) => {
      conn
        .execute(`ALTER SESSION SET CURRENT_SCHEMA = ${process.env.ORACLE_SCHEMA}`)
        .then(() => cb())
        .catch(cb);
    };
  }

  pool = await oracledb.createPool(poolConfig);
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

async function checkConnection() {
  let conn;
  try {
    conn = await getConnection();
    await conn.execute('SELECT 1 FROM dual');
    return {
      status: 'connected',
      pool: pool
        ? {
            open: pool.connectionsOpen,
            inUse: pool.connectionsInUse,
          }
        : null,
    };
  } catch (err) {
    return { status: 'disconnected', error: err.message };
  } finally {
    if (conn) await conn.close();
  }
}

module.exports = { initPool, getConnection, closePool, checkConnection, oracledb };
