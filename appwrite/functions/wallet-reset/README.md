# wallet-reset

Scheduled (cron) Appwrite function that performs the monthly free-credit reset
for PikaCircle wallets and writes an auditable ledger.

Runs daily at 03:00 UTC (`0 3 * * *`). The function itself filters wallets whose
`free_credits_expiry_date` has passed, so running daily is safe and idempotent.

## Behaviour

For each wallet whose `free_credits_expiry_date` is at or before "now":

1. If the wallet has unused free credits (`free_credits` > 0), a **debit**
   transaction row is written for exactly that unused amount (negative
   `credits_delta`, remarks `monthly_reset_expiry`).
2. A **credit** transaction row of `+10` is written (the new monthly grant,
   remarks `monthly_reset_grant`).
3. The wallet is updated: `free_credits`/`freeCredits`/`freeCreditsExpiring` are
   set to `10`, and `free_credits_expiry_date` is set to the end of the current
   UTC month.

Ledger rows are always written **before** the wallet balance is updated, so a
completed reset can never be missing its transaction rows.

## Idempotency

Transaction rows use deterministic `rowId`s derived from the wallet's pre-reset
expiry period (`YYYYMM`):

- grant: `${userId}_reset_grant_${periodKey}`
- expiry: `${userId}_reset_expiry_${periodKey}`

A `409` on create means the row already exists (a prior run in the same cycle),
which is treated as done. A single failing wallet is logged and skipped without
aborting the batch.

Returns a JSON summary: `{ processed, reset, failed }`.

## Tests

```
node --test src/*.test.js
```
