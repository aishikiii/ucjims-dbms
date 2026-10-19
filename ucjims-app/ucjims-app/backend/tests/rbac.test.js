// Stage 4 Test Suite: Role-Based Access Control (RBAC) Matrix Tests
// Validates server-side authorization enforcement across all 7 application roles:
// Admin, Investigator, Cyber Crime Analyst, Forensic Officer, Judge, Prosecutor, Prison Officer.
// Enforces deny-by-default policy: hiding buttons on UI does NOT replace API-level authorization.

const test = require('node:test');
const assert = require('node:assert/strict');
const { requireRole } = require('../middleware/auth');

const ALL_ROLES = [
  'Admin',
  'Investigator',
  'Cyber Crime Analyst',
  'Forensic Officer',
  'Judge',
  'Prosecutor',
  'Prison Officer',
];

function checkRoleAccess(allowedRoles, roleName) {
  const middleware = requireRole(...allowedRoles);
  const req = roleName ? { user: { roleName, userId: 100 } } : {};
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

  middleware(req, res, next);
  return { status: capturedStatus, body: capturedBody, allowed: nextCalled };
}

test('requireRole - rejects unauthenticated user without req.user (401)', () => {
  const result = checkRoleAccess(['Admin'], null);
  assert.equal(result.status, 401);
  assert.equal(result.allowed, false);
  assert.equal(result.body.error, 'Not authenticated');
});

test('RBAC Matrix - Case Registration (POST /api/cases)', () => {
  const allowedRoles = ['Investigator', 'Admin'];

  for (const role of ALL_ROLES) {
    const result = checkRoleAccess(allowedRoles, role);
    if (allowedRoles.includes(role)) {
      assert.equal(result.allowed, true, `${role} should be PERMITTED to register cases`);
    } else {
      assert.equal(result.status, 403, `${role} should be FORBIDDEN from registering cases`);
      assert.equal(result.allowed, false);
      assert.match(result.body.error, new RegExp(`Role '${role}' is not permitted`));
    }
  }
});

test('RBAC Matrix - Case Listing (GET /api/cases)', () => {
  const allowedRoles = ['Investigator', 'Admin', 'Judge', 'Prosecutor', 'Cyber Crime Analyst'];

  for (const role of ALL_ROLES) {
    const result = checkRoleAccess(allowedRoles, role);
    if (allowedRoles.includes(role)) {
      assert.equal(result.allowed, true, `${role} should be PERMITTED to view cases`);
    } else {
      assert.equal(result.status, 403, `${role} should be FORBIDDEN from viewing cases`);
      assert.equal(result.allowed, false);
    }
  }
});

test('RBAC Matrix - Custody Transfer (POST /api/evidence/:id/transfer)', () => {
  const allowedRoles = ['Forensic Officer', 'Admin'];

  for (const role of ALL_ROLES) {
    const result = checkRoleAccess(allowedRoles, role);
    if (allowedRoles.includes(role)) {
      assert.equal(result.allowed, true, `${role} should be PERMITTED to transfer custody`);
    } else {
      assert.equal(result.status, 403, `${role} should be FORBIDDEN from transferring custody`);
      assert.equal(result.allowed, false);
    }
  }
});

test('RBAC Matrix - Evidence List (GET /api/evidence)', () => {
  const allowedRoles = ['Forensic Officer', 'Investigator', 'Admin', 'Judge', 'Prosecutor'];

  for (const role of ALL_ROLES) {
    const result = checkRoleAccess(allowedRoles, role);
    if (allowedRoles.includes(role)) {
      assert.equal(result.allowed, true, `${role} should be PERMITTED to view evidence`);
    } else {
      assert.equal(result.status, 403, `${role} should be FORBIDDEN from viewing evidence`);
      assert.equal(result.allowed, false);
    }
  }
});

test('RBAC Matrix - Schedule Hearing (POST /api/court/hearings)', () => {
  const allowedRoles = ['Judge', 'Admin'];

  for (const role of ALL_ROLES) {
    const result = checkRoleAccess(allowedRoles, role);
    if (allowedRoles.includes(role)) {
      assert.equal(result.allowed, true, `${role} should be PERMITTED to schedule hearings`);
    } else {
      assert.equal(result.status, 403, `${role} should be FORBIDDEN from scheduling hearings`);
      assert.equal(result.allowed, false);
    }
  }
});

test('RBAC Matrix - Record Judgment (POST /api/court/judgments)', () => {
  const allowedRoles = ['Judge', 'Admin'];

  for (const role of ALL_ROLES) {
    const result = checkRoleAccess(allowedRoles, role);
    if (allowedRoles.includes(role)) {
      assert.equal(result.allowed, true, `${role} should be PERMITTED to record judgments`);
    } else {
      assert.equal(result.status, 403, `${role} should be FORBIDDEN from recording judgments`);
      assert.equal(result.allowed, false);
    }
  }
});

test('RBAC Matrix - View Judgments (GET /api/court/judgments)', () => {
  const allowedRoles = ['Judge', 'Prosecutor', 'Admin'];

  for (const role of ALL_ROLES) {
    const result = checkRoleAccess(allowedRoles, role);
    if (allowedRoles.includes(role)) {
      assert.equal(result.allowed, true, `${role} should be PERMITTED to view judgments`);
    } else {
      assert.equal(result.status, 403, `${role} should be FORBIDDEN from viewing judgments`);
      assert.equal(result.allowed, false);
    }
  }
});

test('RBAC Matrix - Inmate Management (Admit/Transfer/Release)', () => {
  const allowedRoles = ['Prison Officer', 'Admin'];

  for (const role of ALL_ROLES) {
    const result = checkRoleAccess(allowedRoles, role);
    if (allowedRoles.includes(role)) {
      assert.equal(result.allowed, true, `${role} should be PERMITTED to manage inmates`);
    } else {
      assert.equal(result.status, 403, `${role} should be FORBIDDEN from inmate management`);
      assert.equal(result.allowed, false);
    }
  }
});

test('Privilege Escalation Prevention - non-admin roles cannot perform admin functions', () => {
  const nonAdminRoles = ALL_ROLES.filter((r) => r !== 'Admin');
  for (const role of nonAdminRoles) {
    const result = checkRoleAccess(['Admin'], role);
    assert.equal(result.status, 403);
    assert.equal(result.allowed, false);
  }
});
