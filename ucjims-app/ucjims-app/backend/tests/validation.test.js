// Stage 4 Test Suite: API Input Validation and Contract Tests
// Tests required parameter checking, format validation, and negative input tests.

const test = require('node:test');
const assert = require('node:assert/strict');

function createMockReqRes(body = {}, params = {}, query = {}, user = { roleName: 'Admin', userId: 1 }) {
  const req = {
    body,
    params,
    query,
    user,
    headers: {},
  };
  let capturedStatus = null;
  let capturedBody = null;

  const res = {
    status(code) {
      capturedStatus = code;
      return this;
    },
    json(data) {
      capturedBody = data;
      return this;
    },
  };

  return { req, res, getResult: () => ({ status: capturedStatus, body: capturedBody }) };
}

// Extract route handler directly from express router stack
function getHandler(router, method, path) {
  for (const layer of router.stack) {
    if (layer.route && layer.route.path === path && layer.route.methods[method.toLowerCase()]) {
      const handlers = layer.route.stack;
      // return the last handler in the chain (skipping requireRole/requireAuth for isolated validation test)
      return handlers[handlers.length - 1].handle;
    }
  }
  throw new Error(`Handler not found for ${method} ${path}`);
}

const authRouter = require('../routes/auth');
const casesRouter = require('../routes/cases');
const courtRouter = require('../routes/court');
const evidenceRouter = require('../routes/evidence');

test('Validation: POST /api/auth/login - rejects missing username or password (400)', async () => {
  const handler = getHandler(authRouter, 'POST', '/login');

  const t1 = createMockReqRes({ username: '' });
  await handler(t1.req, t1.res);
  assert.equal(t1.getResult().status, 400);
  assert.equal(t1.getResult().body.error, 'username and password are required');

  const t2 = createMockReqRes({ password: '123' });
  await handler(t2.req, t2.res);
  assert.equal(t2.getResult().status, 400);
});

test('Validation: POST /api/cases - rejects missing case_number, case_type, or fir_number (400)', async () => {
  const handler = getHandler(casesRouter, 'POST', '/');

  const t1 = createMockReqRes({ case_type: 'THEFT', fir_number: 'FIR-001' });
  await handler(t1.req, t1.res);
  assert.equal(t1.getResult().status, 400);
  assert.equal(t1.getResult().body.error, 'case_number, case_type and fir_number are required');

  const t2 = createMockReqRes({ case_number: 'CASE-001', fir_number: 'FIR-001' });
  await handler(t2.req, t2.res);
  assert.equal(t2.getResult().status, 400);

  const t3 = createMockReqRes({ case_number: 'CASE-001', case_type: 'THEFT' });
  await handler(t3.req, t3.res);
  assert.equal(t3.getResult().status, 400);
});

test('Validation: POST /api/court/hearings - rejects missing case_id, hearing_date, or hearing_type (400)', async () => {
  const handler = getHandler(courtRouter, 'POST', '/hearings');

  const t1 = createMockReqRes({ hearing_date: '2026-11-01', hearing_type: 'BAIL' });
  await handler(t1.req, t1.res);
  assert.equal(t1.getResult().status, 400);
  assert.equal(t1.getResult().body.error, 'case_id, hearing_date and hearing_type are required');
});

test('Validation: POST /api/court/judgments - rejects missing case_id, hearing_id, or verdict (400)', async () => {
  const handler = getHandler(courtRouter, 'POST', '/judgments');

  const t1 = createMockReqRes({ case_id: 1, verdict: 'GUILTY' });
  await handler(t1.req, t1.res);
  assert.equal(t1.getResult().status, 400);
  assert.equal(t1.getResult().body.error, 'case_id, hearing_id and verdict are required');
});

test('Validation: POST /api/court/inmates - rejects missing person_id or prison_id (400)', async () => {
  const handler = getHandler(courtRouter, 'POST', '/inmates');

  const t1 = createMockReqRes({ person_id: 10 });
  await handler(t1.req, t1.res);
  assert.equal(t1.getResult().status, 400);
  assert.equal(t1.getResult().body.error, 'person_id and prison_id are required');
});

test('Validation: POST /api/court/inmates/:id/transfer - rejects missing to_prison_id or reason (400)', async () => {
  const handler = getHandler(courtRouter, 'POST', '/inmates/:id/transfer');

  const t1 = createMockReqRes({ to_prison_id: 2 }, { id: '5' });
  await handler(t1.req, t1.res);
  assert.equal(t1.getResult().status, 400);
  assert.equal(t1.getResult().body.error, 'to_prison_id and reason are required');
});

test('Validation: POST /api/evidence/:id/transfer - rejects missing transfer_location or purpose (400)', async () => {
  const handler = getHandler(evidenceRouter, 'POST', '/:id/transfer');

  const t1 = createMockReqRes({ transfer_location: 'Forensic Lab' }, { id: '3' });
  await handler(t1.req, t1.res);
  assert.equal(t1.getResult().status, 400);
  assert.equal(t1.getResult().body.error, 'transfer_location and purpose are required');
});
