// Pure, dependency-free reset-math helpers for wallet-reset. Kept separate from
// main.js so unit tests can import them without pulling in node-appwrite (which
// is only installed server-side by Appwrite).

export const MONTHLY_FREE_CREDITS = 10;

// Given a (pre-reset) wallet row, compute the expiry debit, the monthly grant,
// and the idempotency period key derived from the wallet's PRE-reset expiry.
export function computeResetMath(wallet) {
  const unused = normalizeCredits(wallet?.free_credits);
  const expiryDelta = unused > 0 ? -unused : 0;
  const grantDelta = MONTHLY_FREE_CREDITS;
  const periodKey = periodKeyFromExpiry(wallet?.free_credits_expiry_date);
  return { expiryDelta, grantDelta, periodKey };
}

export function normalizeCredits(value) {
  const n = Number(value);
  if (!Number.isFinite(n) || n <= 0) return 0;
  return Math.trunc(n);
}

// Derive a `YYYYMM` period key from the wallet's pre-reset expiry date (UTC).
export function periodKeyFromExpiry(expiry) {
  const date = expiry ? new Date(expiry) : new Date();
  const safe = Number.isNaN(date.getTime()) ? new Date() : date;
  const year = safe.getUTCFullYear();
  const month = String(safe.getUTCMonth() + 1).padStart(2, '0');
  return `${year}${month}`;
}

export function endOfCurrentMonthUtc() {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 0, 23, 59, 59, 999));
}

export const testOnly = {
  MONTHLY_FREE_CREDITS,
  computeResetMath,
  normalizeCredits,
  periodKeyFromExpiry,
  endOfCurrentMonthUtc,
};
