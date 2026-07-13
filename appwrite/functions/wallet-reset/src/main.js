import { Client, ID, Permission, Query, Role, TablesDB } from 'node-appwrite';

import {
  MONTHLY_FREE_CREDITS,
  computeResetMath,
  endOfCurrentMonthUtc,
  normalizeCredits,
  periodKeyFromExpiry,
} from './reset-math.js';

const WALLET_TABLE_ID = 'wallet';
const TRANSACTIONS_TABLE_ID = 'transactions';
const PAGE_SIZE = 100;

export default async ({ req, res, log, error }) => {
  const client = new Client()
    .setEndpoint(requiredEnv('APPWRITE_FUNCTION_API_ENDPOINT'))
    .setProject(requiredEnv('APPWRITE_FUNCTION_PROJECT_ID'))
    .setKey(requiredEnv('APPWRITE_API_KEY'));

  const tables = new TablesDB(client);
  const databaseId = requiredEnv('APPWRITE_DATABASE_ID');

  const now = new Date();
  const nowIso = now.toISOString();

  let processed = 0;
  let reset = 0;
  let failed = 0;

  try {
    let cursor = null;

    // Paginate over every wallet whose free-credit expiry has passed.
    for (;;) {
      const queries = [
        Query.lessThanEqual('free_credits_expiry_date', nowIso),
        Query.limit(PAGE_SIZE),
      ];
      if (cursor) queries.push(Query.cursorAfter(cursor));

      const page = await tables.listRows({
        databaseId,
        tableId: WALLET_TABLE_ID,
        queries,
      });

      const rows = page.rows;
      if (rows.length === 0) break;

      for (const wallet of rows) {
        processed += 1;
        try {
          const didReset = await resetWallet(tables, databaseId, wallet);
          if (didReset) reset += 1;
        } catch (caught) {
          failed += 1;
          error(
            `wallet-reset failed for ${wallet.user_id ?? wallet.$id}: ` +
              (caught?.message ?? String(caught)),
          );
        }
      }

      if (rows.length < PAGE_SIZE) break;
      cursor = rows[rows.length - 1].$id;
    }

    log(`wallet-reset complete: processed=${processed} reset=${reset} failed=${failed}`);
    return res.json({ processed, reset, failed });
  } catch (caught) {
    error(caught?.message ?? String(caught));
    return res.json({ error: 'Could not run wallet reset.', processed, reset, failed }, 500);
  }
};

async function resetWallet(tables, databaseId, wallet) {
  const userId = wallet.user_id ?? wallet.$id;
  const { expiryDelta, grantDelta, periodKey } = computeResetMath(wallet);

  // 1. Write the expiry-debit row first (if the user had unused free credits),
  //    then the grant-credit row, and only THEN update the wallet balance — so
  //    the ledger is never missing rows for a completed reset.
  if (expiryDelta < 0) {
    await createResetTransaction(tables, databaseId, {
      rowId: `${userId}_reset_expiry_${periodKey}`,
      userId,
      creditsDelta: expiryDelta,
      remarks: 'monthly_reset_expiry',
    });
  }

  await createResetTransaction(tables, databaseId, {
    rowId: `${userId}_reset_grant_${periodKey}`,
    userId,
    creditsDelta: grantDelta,
    remarks: 'monthly_reset_grant',
  });

  // 2. Update the wallet balance / expiry last.
  const expiry = endOfCurrentMonthUtc().toISOString();
  await tables.updateRow({
    databaseId,
    tableId: WALLET_TABLE_ID,
    rowId: wallet.$id,
    data: {
      free_credits: MONTHLY_FREE_CREDITS,
      free_credits_expiry_date: expiry,
      freeCredits: MONTHLY_FREE_CREDITS,
      freeCreditsExpiring: MONTHLY_FREE_CREDITS,
    },
  });

  return true;
}

async function createResetTransaction(tables, databaseId, { rowId, userId, creditsDelta, remarks }) {
  // Deterministic rowId keyed to the user + pre-reset period so a re-run within
  // the same reset cycle can't duplicate ledger rows. A 409 means the row was
  // already written on a prior attempt, which we treat as done.
  try {
    await tables.createRow({
      databaseId,
      tableId: TRANSACTIONS_TABLE_ID,
      rowId,
      data: {
        user_id: userId,
        type: 'free_credit_reset',
        amount: 0,
        currency: 'CREDITS',
        credits_delta: creditsDelta,
        credits_delta_decimal: creditsDelta,
        transaction_date: new Date().toISOString(),
        remarks,
        created_by: 'system',
      },
      permissions: [Permission.read(Role.user(userId))],
    });
  } catch (caught) {
    if (caught?.code === 409) return; // Already recorded on a prior attempt.
    throw caught;
  }
}

// Pure reset-math helpers live in ./reset-math.js so tests can import them
// without pulling in node-appwrite (installed server-side only).

export const testOnly = {
  endOfCurrentMonthUtc,
  computeResetMath,
  normalizeCredits,
  periodKeyFromExpiry,
  MONTHLY_FREE_CREDITS,
};

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}
