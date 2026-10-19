// Stage 4 Test Suite: Authentication and Token Security Tests
// Verifies JWT token creation, signature verification, expiry checks, and tamper prevention.

const test = require('node:test');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const { requireAuth } = require('../middleware/auth');

const TEST_SECRET = 'test_jwt_secret_key_1234567890';
process.env.JWT_SECRET = TEST_SECRET;

function createMockReqRes(authHeader) {
  const req = {
    headers: {
      ...(authHeader ? { authorization: authHeader } : {}),
    },
  };
  let capturedStatus = null;
  let capturedBody = null;
  let nextCalled = false;

  const res = {
    status(code) {
      capturedStatus = code;
      return this;
    },
    json(body) {
      capturedBody = body;
      return this;
    },
  };

  const next = () => {
    nextCalled = true;
  };

  return { req, res, next, getResult: () => ({ capturedStatus, capturedBody, nextCalled }) };
}

test('requireAuth - rejects request with missing Authorization header (401)', () => {
  const { req, res, next, getResult } = createMockReqRes(null);
  requireAuth(req, res, next);
  const result = getResult();

  assert.equal(result.capturedStatus, 401);
  assert.equal(result.capturedBody.error, 'Missing or invalid Authorization header');
  assert.equal(result.nextCalled, false);
});

test('requireAuth - rejects request with non-Bearer Authorization header (401)', () => {
  const { req, res, next, getResult } = createMockReqRes('Basic dXNlcjpwYXNz');
  requireAuth(req, res, next);
  const result = getResult();

  assert.equal(result.capturedStatus, 401);
  assert.equal(result.capturedBody.error, 'Missing or invalid Authorization header');
  assert.equal(result.nextCalled, false);
});

test('requireAuth - rejects tampered/invalid token (401)', () => {
  const token = jwt.sign({ userId: 1, roleName: 'Admin' }, 'WRONG_SECRET_KEY');
  const { req, res, next, getResult } = createMockReqRes(`Bearer ${token}`);
  requireAuth(req, res, next);
  const result = getResult();

  assert.equal(result.capturedStatus, 401);
  assert.equal(result.capturedBody.error, 'Invalid or expired token');
  assert.equal(result.nextCalled, false);
});

test('requireAuth - rejects expired token (401)', () => {
  const expiredToken = jwt.sign({ userId: 1, roleName: 'Admin' }, TEST_SECRET, { expiresIn: -10 });
  const { req, res, next, getResult } = createMockReqRes(`Bearer ${expiredToken}`);
  requireAuth(req, res, next);
  const result = getResult();

  assert.equal(result.capturedStatus, 401);
  assert.equal(result.capturedBody.error, 'Invalid or expired token');
  assert.equal(result.nextCalled, false);
});

test('requireAuth - accepts valid token and populates req.user', () => {
  const validToken = jwt.sign(
    { userId: 4, username: 'inv_sharma', roleName: 'Investigator', deptId: 1 },
    TEST_SECRET,
    { expiresIn: '1h' }
  );
  const { req, res, next, getResult } = createMockReqRes(`Bearer ${validToken}`);
  requireAuth(req, res, next);
  const result = getResult();

  assert.equal(result.nextCalled, true);
  assert.equal(result.capturedStatus, null);
  assert.equal(req.user.userId, 4);
  assert.equal(req.user.username, 'inv_sharma');
  assert.equal(req.user.roleName, 'Investigator');
  assert.equal(req.user.deptId, 1);
});
