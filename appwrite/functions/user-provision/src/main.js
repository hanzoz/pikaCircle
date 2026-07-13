import { Client, ID, Permission, Query, Role, TablesDB, Users } from 'node-appwrite';

const USERS_TABLE_ID = 'users';
const WALLET_TABLE_ID = 'wallet';
const TRANSACTIONS_TABLE_ID = 'transactions';
const DEFAULT_MEMBERSHIP_LEVEL_ID = 'bronze';
const MONTHLY_FREE_CREDITS = 10;
const DEFAULT_ROLE = 'user';

const USERNAME_MIN_LENGTH = 3;
const USERNAME_MAX_LENGTH = 30;
const RESERVED_USERNAMES = new Set([
  'admin',
  'root',
  'support',
  'pikacircle',
  'system',
  'me',
  'null',
  'undefined',
]);

export default async ({ req, res, log, error }) => {
  const payload = parseBody(req);
  if (payload == null || typeof payload !== 'object') {
    error('Invalid event payload.');
    return res.json({ error: 'Invalid event payload.' }, 400);
  }

  const userId = payload.$id;
  if (!userId) {
    log('No user id in event payload.');
    return res.json({ error: 'No user id in event payload.' }, 400);
  }

  const name = payload.name ?? '';
  const email = payload.email ?? '';

  const client = new Client()
    .setEndpoint(requiredEnv('APPWRITE_FUNCTION_API_ENDPOINT'))
    .setProject(requiredEnv('APPWRITE_FUNCTION_PROJECT_ID'))
    .setKey(requiredEnv('APPWRITE_API_KEY'));

  const tables = new TablesDB(client);
  const users = new Users(client);
  const databaseId = requiredEnv('APPWRITE_DATABASE_ID');

  try {
    // 1. Auth label — ensure the 'user' label is present.
    const account = await users.get({ userId });
    const labels = Array.isArray(account.labels) ? account.labels : [];
    if (!labels.includes(DEFAULT_ROLE)) {
      await users.updateLabels({ userId, labels: nextLabels(labels) });
    }

    // 2. users row — create only if missing.
    const existing = await getUserRowOrNull(tables, databaseId, userId);
    if (!existing) {
      const base = baseUsernameFrom(name, email);
      const username = await generateUniqueUsername(tables, databaseId, base);
      await tables.createRow({
        databaseId,
        tableId: USERS_TABLE_ID,
        rowId: userId,
        data: initialUserRowData(name, email, username),
        permissions: [Permission.read(Role.user(userId))],
      });
    }

    // 3. wallet row — create only if missing.
    await ensureWalletRow(tables, databaseId, userId);

    log('Provisioned user, label, and wallet for ' + userId);
    return res.json({ userId, provisioned: true });
  } catch (caught) {
    error(caught?.message ?? String(caught));
    return res.json({ error: 'Could not provision user.' }, 500);
  }
};

function parseBody(req) {
  if (req.bodyJson && typeof req.bodyJson === 'object') {
    return req.bodyJson;
  }
  if (!req.body) return {};
  try {
    return JSON.parse(req.body);
  } catch {
    return null;
  }
}

function nextLabels(existingLabels) {
  const labels = Array.isArray(existingLabels) ? existingLabels : [];
  return labels.includes(DEFAULT_ROLE) ? labels : [...labels, DEFAULT_ROLE];
}

function initialUserRowData(name, email, username) {
  return {
    name,
    email,
    username,
    roles: [DEFAULT_ROLE],
    membership_level_id: DEFAULT_MEMBERSHIP_LEVEL_ID,
    job_title_verified: false,
  };
}

function normalizeUsername(value) {
  if (typeof value !== 'string') return '';
  let handle = value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '');
  if (handle && !/^[a-z]/.test(handle)) {
    handle = `u${handle}`;
  }
  if (handle.length > USERNAME_MAX_LENGTH) {
    handle = handle.slice(0, USERNAME_MAX_LENGTH).replace(/_+$/g, '');
  }
  return handle;
}

function baseUsernameFrom(name, email) {
  const fromName = normalizeUsername(name);
  if (isValidUsername(fromName) && !RESERVED_USERNAMES.has(fromName)) {
    return fromName;
  }
  const localPart = typeof email === 'string' ? email.split('@')[0] : '';
  const fromEmail = normalizeUsername(localPart);
  if (isValidUsername(fromEmail) && !RESERVED_USERNAMES.has(fromEmail)) {
    return fromEmail;
  }
  const fallback = fromName || fromEmail || 'user';
  return padUsername(fallback);
}

function isValidUsername(handle) {
  return (
    typeof handle === 'string' &&
    handle.length >= USERNAME_MIN_LENGTH &&
    handle.length <= USERNAME_MAX_LENGTH &&
    /^[a-z][a-z0-9_]*$/.test(handle)
  );
}

function padUsername(handle) {
  let padded = /^[a-z]/.test(handle) ? handle : `u${handle}`;
  while (padded.length < USERNAME_MIN_LENGTH) {
    padded = `${padded}${randomDigits(2)}`;
  }
  return padded.slice(0, USERNAME_MAX_LENGTH);
}

function randomDigits(count) {
  let out = '';
  for (let i = 0; i < count; i += 1) {
    out += Math.floor(Math.random() * 10).toString();
  }
  return out;
}

function withSuffix(base, suffix) {
  const room = USERNAME_MAX_LENGTH - suffix.length;
  const trimmedBase = base.slice(0, Math.max(1, room)).replace(/_+$/g, '');
  return `${trimmedBase}${suffix}`;
}

async function usernameExists(tables, databaseId, candidate) {
  const rows = await tables.listRows({
    databaseId,
    tableId: USERS_TABLE_ID,
    queries: [Query.equal('username', candidate), Query.limit(1)],
  });
  return rows.rows.length > 0;
}

async function generateUniqueUsername(tables, databaseId, base) {
  let candidate = padUsername(base);
  if (!RESERVED_USERNAMES.has(candidate) && !(await usernameExists(tables, databaseId, candidate))) {
    return candidate;
  }

  for (let attempt = 0; attempt < 10; attempt += 1) {
    candidate = withSuffix(base, randomDigits(attempt < 5 ? 2 : 4));
    if (
      !RESERVED_USERNAMES.has(candidate) &&
      !(await usernameExists(tables, databaseId, candidate))
    ) {
      return candidate;
    }
  }

  // Final fallback: append a short random token so it always resolves.
  candidate = withSuffix(base, `${randomDigits(2)}${Math.random().toString(36).slice(2, 6)}`);
  return normalizeUsername(candidate) || padUsername(base);
}

async function getUserRowOrNull(tables, databaseId, userId) {
  try {
    return await tables.getRow({
      databaseId,
      tableId: USERS_TABLE_ID,
      rowId: userId,
    });
  } catch (caught) {
    if (caught?.code === 404) return null;
    throw caught;
  }
}

async function ensureWalletRow(tables, databaseId, userId) {
  const existing = await getWalletRowOrNull(tables, databaseId, userId);
  if (existing) return existing;

  // Record the provisioning transaction first so a wallet is never created
  // without its matching `transactions` row. If this throws, provisioning
  // fails and Appwrite retries; the insert is idempotent (see below).
  await ensureProvisionTransactionRow(tables, databaseId, userId);

  const expiry = endOfCurrentMonthUtc().toISOString();
  const wallet = await tables.createRow({
    databaseId,
    tableId: WALLET_TABLE_ID,
    rowId: userId,
    data: {
      user_id: userId,
      free_credits: MONTHLY_FREE_CREDITS,
      paid_credits: 0,
      free_credits_expiry_date: expiry,
      remarks: 'Wallet auto-provisioned after account registration.',
      freeCredits: MONTHLY_FREE_CREDITS,
      paidCredits: 0,
      note: 'Free credits refresh monthly. Paid credits never expire.',
      freeCreditsExpiring: MONTHLY_FREE_CREDITS,
    },
    permissions: [Permission.read(Role.user(userId))],
  });

  return wallet;
}

async function ensureProvisionTransactionRow(tables, databaseId, userId) {
  // Idempotency without a deterministic rowId: Appwrite rowIds are capped at 36
  // chars, and `${userId}_wallet_provision` overflows that, so we instead check
  // whether a provisioning transaction already exists for this user before
  // inserting one with an auto-generated id.
  const existing = await tables.listRows({
    databaseId,
    tableId: TRANSACTIONS_TABLE_ID,
    queries: [
      Query.equal('user_id', userId),
      Query.equal('remarks', 'wallet_provision'),
      Query.limit(1),
    ],
  });
  if (existing.rows.length > 0) return; // Already recorded on a prior attempt.

  await tables.createRow({
    databaseId,
    tableId: TRANSACTIONS_TABLE_ID,
    rowId: ID.unique(),
    data: {
      user_id: userId,
      type: 'adjustment',
      amount: 0,
      currency: 'CREDITS',
      credits_delta: MONTHLY_FREE_CREDITS,
      credits_delta_decimal: MONTHLY_FREE_CREDITS,
      transaction_date: new Date().toISOString(),
      remarks: 'wallet_provision',
      created_by: 'system',
    },
    permissions: [Permission.read(Role.user(userId))],
  });
}

async function getWalletRowOrNull(tables, databaseId, userId) {
  try {
    return await tables.getRow({
      databaseId,
      tableId: WALLET_TABLE_ID,
      rowId: userId,
    });
  } catch (caught) {
    if (caught?.code === 404) return null;
    throw caught;
  }
}

function endOfCurrentMonthUtc() {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 0, 23, 59, 59, 999));
}

export const testOnly = {
  initialUserRowData,
  endOfCurrentMonthUtc,
  nextLabels,
  normalizeUsername,
  baseUsernameFrom,
  isValidUsername,
  RESERVED_USERNAMES,
};

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}
