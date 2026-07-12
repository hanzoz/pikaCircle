import test from 'node:test';
import assert from 'node:assert/strict';

import { testOnly } from './main.js';

test('initialUserRowData builds a bronze user row', () => {
  assert.deepEqual(testOnly.initialUserRowData('Player One', 'p@e.com', 'player_one'), {
    name: 'Player One',
    email: 'p@e.com',
    username: 'player_one',
    roles: ['user'],
    membership_level_id: 'bronze',
    job_title_verified: false,
  });
});

test('nextLabels adds the user label only when missing', () => {
  assert.deepEqual(testOnly.nextLabels([]), ['user']);
  assert.deepEqual(testOnly.nextLabels(['premium']), ['premium', 'user']);
  assert.deepEqual(testOnly.nextLabels(['user']), ['user']);
});

test('endOfCurrentMonthUtc returns the last UTC moment of the month', () => {
  const result = testOnly.endOfCurrentMonthUtc();
  assert.ok(result instanceof Date);
  assert.equal(result.getUTCHours(), 23);
  assert.equal(result.getUTCMinutes(), 59);
  assert.equal(result.getUTCSeconds(), 59);
  assert.equal(result.getUTCMilliseconds(), 999);

  const now = new Date();
  const lastDay = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 0),
  ).getUTCDate();
  assert.equal(result.getUTCDate(), lastDay);
});

test('normalizeUsername lowercases, replaces punctuation, and collapses separators', () => {
  assert.equal(testOnly.normalizeUsername('  Player One!!  '), 'player_one');
  assert.equal(testOnly.normalizeUsername('John.Doe@@Smith'), 'john_doe_smith');
  assert.equal(testOnly.normalizeUsername('__weird__handle__'), 'weird_handle');
});

test('normalizeUsername enforces a leading letter', () => {
  assert.equal(testOnly.normalizeUsername('123player'), 'u123player');
  assert.equal(testOnly.normalizeUsername('_9lives'), 'u9lives');
});

test('normalizeUsername clamps to the max length', () => {
  const long = 'a'.repeat(50);
  const result = testOnly.normalizeUsername(long);
  assert.equal(result.length, 30);
  assert.equal(result, 'a'.repeat(30));
});

test('baseUsernameFrom prefers the name then falls back to email local part', () => {
  assert.equal(testOnly.baseUsernameFrom('Player One', 'p@example.com'), 'player_one');
  assert.equal(testOnly.baseUsernameFrom('', 'jane.doe@example.com'), 'jane_doe');
});

test('baseUsernameFrom returns a normalized base even for reserved-only inputs', () => {
  // baseUsernameFrom yields a candidate; generateUniqueUsername is responsible
  // for avoiding reserved names via suffixing when the base itself is reserved.
  const result = testOnly.baseUsernameFrom('admin', 'admin@example.com');
  assert.equal(result, 'admin');
  assert.equal(testOnly.RESERVED_USERNAMES.has('admin'), true);
});

test('isValidUsername rejects reserved-style short or non-letter-led handles', () => {
  assert.equal(testOnly.isValidUsername('ab'), false);
  assert.equal(testOnly.isValidUsername('1abc'), false);
  assert.equal(testOnly.isValidUsername('valid_handle'), true);
});
