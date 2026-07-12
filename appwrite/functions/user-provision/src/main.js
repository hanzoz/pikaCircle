import { Client, Permission, Role, TablesDB, Users } from 'node-appwrite';

const USERS_TABLE_ID = 'users';
const WALLET_TABLE_ID = 'wallet';
const DEFAULT_MEMBERSHIP_LEVEL_ID = 'bronze';
const MONTHLY_FREE_CREDITS = 10;
const DEFAULT_ROLE = 'user';

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
      await tables.createRow({
        databaseId,
        tableId: USERS_TABLE_ID,
        rowId: userId,
        data: initialUserRowData(name, email),
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

function initialUserRowData(name, email) {
  return {
    name,
    email,
    roles: [DEFAULT_ROLE],
    membership_level_id: DEFAULT_MEMBERSHIP_LEVEL_ID,
    job_title_verified: false,
  };
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

  const expiry = endOfCurrentMonthUtc().toISOString();
  return tables.createRow({
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
};

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}
