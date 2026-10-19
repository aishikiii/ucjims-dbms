// Stage 4 Test Suite: Database Error Sanitizer Tests
// Verifies that database errors are properly mapped to HTTP status codes
// and that internal SQL, stack traces, and sensitive schema details are NEVER leaked.

const test = require('node:test');
const assert = require('node:assert/strict');
const { parseDbError, sendDbError } = require('../utils/dbError');

test('parseDbError - maps ORA-20066 custody chronological violation to 409 Conflict', () => {
  const err = {
    errorNum: 20066,
    message: 'ORA-20066: Custody events must be strictly chronological\nORA-06512: at line 4',
  };
  const result = parseDbError(err);
  assert.equal(result.status, 409);
  assert.equal(result.body.error, 'Custody events must be strictly chronological');
  assert.equal(result.body.code, 'ORA-20066');
});

test('parseDbError - maps ORA-20063 not found to 404 Not Found', () => {
  const err = {
    errorNum: 20063,
    message: 'ORA-20063: Evidence 999999 was not found\nORA-06512: at line 2',
  };
  const result = parseDbError(err);
  assert.equal(result.status, 404);
  assert.equal(result.body.error, 'Evidence 999999 was not found');
  assert.equal(result.body.code, 'ORA-20063');
});

test('parseDbError - maps ORA-00001 unique constraint to 409 Duplicate value', () => {
  const err = {
    errorNum: 1,
    message: 'ORA-00001: unique constraint (UCJIMS.UQ_CASE_NUMBER) violated',
  };
  const result = parseDbError(err);
  assert.equal(result.status, 409);
  assert.equal(result.body.error, 'Duplicate value');
  assert.equal(result.body.code, 'ORA-00001');
});

test('parseDbError - maps ORA-02291 foreign key violation to 400 Bad Request', () => {
  const err = {
    errorNum: 2291,
    message: 'ORA-02291: integrity constraint (UCJIMS.FK_HEARING_CASE) violated - parent key not found',
  };
  const result = parseDbError(err);
  assert.equal(result.status, 400);
  assert.equal(result.body.error, 'Referenced record does not exist');
  assert.equal(result.body.code, 'ORA-02291');
});

test('parseDbError - maps ORA-02290 check constraint to 400 Bad Request', () => {
  const err = {
    errorNum: 2290,
    message: 'ORA-02290: check constraint (UCJIMS.CHK_EVIDENCE_TYPE_DOMAIN) violated',
  };
  const result = parseDbError(err);
  assert.equal(result.status, 400);
  assert.equal(result.body.error, 'Invalid or missing value');
  assert.equal(result.body.code, 'ORA-02290');
});

test('parseDbError - masks unhandled error and prevents SQL/stack leak', () => {
  const err = new Error('ORA-00942: table or view does not exist\nSELECT * FROM SECRET_CREDENTIALS');
  const result = parseDbError(err, 'Failed to process request');
  assert.equal(result.status, 500);
  assert.equal(result.body.error, 'Failed to process request');
  assert.equal(result.body.stack, undefined);
  assert.equal(result.body.message, undefined);
});

test('sendDbError - sends status and json safely on mock Express response', () => {
  let capturedStatus = null;
  let capturedBody = null;
  const mockRes = {
    status(code) {
      capturedStatus = code;
      return this;
    },
    json(body) {
      capturedBody = body;
      return this;
    },
  };

  const err = { errorNum: 20023, message: 'ORA-20023: Inmate 1 is already released' };
  sendDbError(mockRes, err, 'Inmate release failed');

  assert.equal(capturedStatus, 409);
  assert.equal(capturedBody.error, 'Inmate 1 is already released');
  assert.equal(capturedBody.code, 'ORA-20023');
});
