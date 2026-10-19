// Centralized Oracle DB Error Sanitizer
// Ensures NO SQL queries, stack traces, schema details, or passwords ever leak to the HTTP client.

function parseDbError(err, fallback = 'Internal server error') {
  const n = err && err.errorNum;
  if (n >= 20000 && n <= 20999) {
    const msg = String(err.message || '').split('\n')[0].replace(/^ORA-\d+:\s*/, '');
    return {
      status: /not found/i.test(msg) ? 404 : 409,
      body: { error: msg, code: `ORA-${n}` },
    };
  }
  if (n === 1) {
    return { status: 409, body: { error: 'Duplicate value', code: 'ORA-00001' } };
  }
  if (n === 2291) {
    return { status: 400, body: { error: 'Referenced record does not exist', code: 'ORA-02291' } };
  }
  if (n === 2290 || n === 1400) {
    return { status: 400, body: { error: 'Invalid or missing value', code: `ORA-${String(n).padStart(5, '0')}` } };
  }
  return { status: 500, body: { error: fallback } };
}

function sendDbError(res, err, fallback) {
  const parsed = parseDbError(err, fallback);
  if (parsed.status === 500) {
    console.error(err);
  }
  return res.status(parsed.status).json(parsed.body);
}

module.exports = { sendDbError, parseDbError };