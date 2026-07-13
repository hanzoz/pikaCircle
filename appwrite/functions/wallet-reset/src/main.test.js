import { test } from 'node:test';
import assert from 'node:assert/strict';

import { testOnly } from './reset-math.js';

const { computeResetMath, periodKeyFromExpiry, endOfCurrentMonthUtc, MONTHLY_FREE_CREDITS } =
  testOnly;

test('unused=3 -> expiryDelta -3, grant +10', () => {
  const { expiryDelta, grantDelta } = computeResetMath({
    free_credits: 3,
    free_credits_expiry_date: '2026-06-30T23:59:59.999Z',
  });
  assert.equal(expiryDelta, -3);
  assert.equal(grantDelta, 10);
  assert.equal(grantDelta, MONTHLY_FREE_CREDITS);
});

test('unused=0 -> no expiry row (expiryDelta 0), grant +10', () => {
  const { expiryDelta, grantDelta } = computeResetMath({
    free_credits: 0,
    free_credits_expiry_date: '2026-06-30T23:59:59.999Z',
  });
  assert.equal(expiryDelta, 0);
  assert.equal(grantDelta, 10);
});

test('negative / missing free_credits are treated as 0 unused', () => {
  assert.equal(computeResetMath({ free_credits: -5 }).expiryDelta, 0);
  assert.equal(computeResetMath({}).expiryDelta, 0);
});

test('fractional free_credits are truncated toward zero', () => {
  assert.equal(computeResetMath({ free_credits: 3.9 }).expiryDelta, -3);
});

test('periodKey derived from pre-reset expiry (YYYYMM, UTC)', () => {
  assert.equal(periodKeyFromExpiry('2026-06-30T23:59:59.999Z'), '202606');
  assert.equal(periodKeyFromExpiry('2026-01-31T23:59:59.999Z'), '202601');
  assert.equal(computeResetMath({ free_credits: 3, free_credits_expiry_date: '2025-12-31T23:59:59.999Z' }).periodKey, '202512');
});

test('endOfCurrentMonthUtc returns last ms of current UTC month', () => {
  const end = endOfCurrentMonthUtc();
  const now = new Date();
  assert.equal(end.getUTCFullYear(), now.getUTCFullYear());
  assert.equal(end.getUTCMonth(), now.getUTCMonth());
  // Adding 1ms rolls into the next month.
  const next = new Date(end.getTime() + 1);
  assert.equal(next.getUTCDate(), 1);
  assert.equal(end.getUTCHours(), 23);
  assert.equal(end.getUTCMinutes(), 59);
});
