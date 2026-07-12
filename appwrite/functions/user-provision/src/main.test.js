import test from 'node:test';
import assert from 'node:assert/strict';

import { testOnly } from './main.js';

test('initialUserRowData builds a bronze user row', () => {
  assert.deepEqual(testOnly.initialUserRowData('Player One', 'p@e.com'), {
    name: 'Player One',
    email: 'p@e.com',
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
