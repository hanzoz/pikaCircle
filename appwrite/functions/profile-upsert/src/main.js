import { Client, Permission, Query, Role, TablesDB } from 'node-appwrite';

const USERS_TABLE_ID = 'users';
const WALLET_TABLE_ID = 'wallet';
const SKILLS_TABLE_ID = 'skills';
const DEFAULT_MEMBERSHIP_LEVEL_ID = 'bronze';
const MONTHLY_FREE_CREDITS = 10;
const SKILL_LEVELS = new Set(['beginner', 'intermediate', 'competitive']);
const GENDERS = new Set(['male', 'female', 'non_binary']);
const APP_ROLES = new Set(['user', 'host', 'admin']);
const EDITABLE_RELATIONSHIP_FIELDS = new Set([]);
const NON_RELATIONSHIP_ID_FIELDS = new Set(['profile_picture_file_id']);

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

const editableFields = new Set([
  'name',
  'username',
  'email',
  'date_of_birth',
  'gender',
  'bio',
  'job_title',
  'linkedin_profile_url',
  'profile_picture_file_id',
  'profile_picture_url',
  'skill_level',
]);

const protectedFields = new Set([
  'roles',
  'membership_level_id',
  'job_title_verified',
  'job_title_verified_at',
  'job_title_verified_by',
  'job_title_credit_awarded_at',
]);

export default async ({ req, res, log, error }) => {
  if (req.method !== 'POST') {
    return res.json({ error: 'Method not allowed' }, 405);
  }

  const userId = header(req, 'x-appwrite-user-id');
  if (!userId) {
    return res.json({ error: 'Sign in to update your profile.' }, 401);
  }

  const body = parseBody(req);
  if (body == null) {
    return res.json({ error: 'Invalid JSON body.' }, 400);
  }

  const client = new Client()
    .setEndpoint(requiredEnv('APPWRITE_FUNCTION_API_ENDPOINT'))
    .setProject(requiredEnv('APPWRITE_FUNCTION_PROJECT_ID'))
    .setKey(requiredEnv('APPWRITE_API_KEY'));

  const tables = new TablesDB(client);
  const databaseId = requiredEnv('APPWRITE_DATABASE_ID');

  // Availability-check mode: short-circuit before the editable-field flow.
  const checkUsername = parseCheckUsername(body);
  if (checkUsername != null) {
    try {
      const result = await evaluateUsernameAvailability(
        tables,
        databaseId,
        userId,
        checkUsername,
      );
      return res.json(result, 200);
    } catch (caught) {
      error(caught?.message ?? String(caught));
      return res.json({ error: 'Could not check username.' }, 500);
    }
  }

  const attemptedProtectedField = Object.keys(body).find((key) =>
    protectedFields.has(key),
  );
  if (attemptedProtectedField) {
    return res.json(
      { error: `Protected profile field: ${attemptedProtectedField}` },
      400,
    );
  }

  const { skillLevel, data } = editableData(body);
  if (Object.keys(data).length === 0 && !skillLevel) {
    return res.json({ error: 'No editable profile fields provided.' }, 400);
  }

  try {
    if (typeof data.username === 'string') {
      const normalized = normalizeUsername(data.username);
      if (!isValidUsername(normalized)) {
        return res.json(
          { error: 'Usernames must be 3-30 characters using letters, numbers, or underscores and start with a letter.' },
          400,
        );
      }
      if (RESERVED_USERNAMES.has(normalized)) {
        return res.json({ error: 'That username is reserved.' }, 400);
      }
      const takenBy = await usernameOwner(tables, databaseId, normalized);
      if (takenBy && takenBy !== userId) {
        return res.json({ error: 'That username is taken.' }, 409);
      }
      data.username = normalized;
    }

    const existing = await getUserRowOrNull(tables, databaseId, userId);
    if (!existing && (!data.name || !data.email)) {
      return res.json({ error: 'Name and email are required.' }, 400);
    }
    const rowData = existing
      ? normalizeExistingUpdateData(existing, data)
      : initialUserRowData(data);

    const row = existing
      ? await tables.updateRow({
          databaseId,
          tableId: USERS_TABLE_ID,
          rowId: userId,
          data: rowData,
        })
      : await tables.createRow({
          databaseId,
          tableId: USERS_TABLE_ID,
          rowId: userId,
          data: rowData,
          permissions: [Permission.read(Role.user(userId))],
        });

    const skill = skillLevel
      ? await ensureSkillRow(tables, databaseId, userId, skillLevel)
      : await getSkillRowOrNull(tables, databaseId, userId);
    const wallet = await ensureWalletRow(tables, databaseId, userId);

    log(`Profile, skill, and wallet provisioned for ${userId}`);
    return res.json({
      id: row.$id,
      skillId: skill?.$id ?? null,
      walletId: wallet.$id,
      updated: true,
    });
  } catch (caught) {
    error(caught?.message ?? String(caught));
    return res.json({ error: 'Could not update profile.' }, 500);
  }
};

function parseBody(req) {
  if (req.bodyJson && typeof req.bodyJson === 'object') {
    return req.bodyJson;
  }
  if (!req.body) return {};
  try {
    const parsed = JSON.parse(req.body);
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
      ? parsed
      : null;
  } catch {
    return null;
  }
}

function editableData(body) {
  let skillLevel = '';
  const data = Object.fromEntries(
    Object.entries(body)
      .filter(([key]) => editableFields.has(key))
      .map(([key, value]) => [key, normalizedEditableValue(key, value)])
      .filter(([key, value]) => {
        if (key !== 'skill_level') return value !== '' || acceptsBlankString(key);
        skillLevel = normalizedSkillLevel(value);
        return false;
      }),
  );
  return { skillLevel, data };
}

function normalizedEditableValue(key, value) {
  if (typeof value !== 'string') return value;
  const trimmed = value.trim();
  if (key === 'gender') return normalizedGender(trimmed);
  return trimmed;
}

function normalizeExistingUpdateData(existing, data) {
  const rowData = { ...data };
  const normalizedRoles = normalizedRolesForWrite(existing.roles);
  if (normalizedRoles.length > 0) {
    rowData.roles = normalizedRoles;
  }

  for (const key of Object.keys(existing)) {
    if (isRelationshipField(key) && !EDITABLE_RELATIONSHIP_FIELDS.has(key)) {
      delete rowData[key];
    }
  }
  return rowData;
}

function initialUserRowData(data) {
  return {
    ...data,
    roles: ['user'],
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

function isValidUsername(handle) {
  return (
    typeof handle === 'string' &&
    handle.length >= USERNAME_MIN_LENGTH &&
    handle.length <= USERNAME_MAX_LENGTH &&
    /^[a-z][a-z0-9_]*$/.test(handle)
  );
}

function parseCheckUsername(body) {
  if (!body || body.action !== 'check_username') return null;
  return typeof body.username === 'string' ? body.username : '';
}

async function usernameOwner(tables, databaseId, username) {
  const rows = await tables.listRows({
    databaseId,
    tableId: USERS_TABLE_ID,
    queries: [Query.equal('username', username), Query.limit(1)],
  });
  return rows.rows.at(0)?.$id ?? null;
}

async function evaluateUsernameAvailability(tables, databaseId, userId, rawUsername) {
  const normalized = normalizeUsername(rawUsername);
  if (!isValidUsername(normalized)) {
    return { available: false, normalized, reason: 'invalid' };
  }
  if (RESERVED_USERNAMES.has(normalized)) {
    return { available: false, normalized, reason: 'reserved' };
  }
  const ownerId = await usernameOwner(tables, databaseId, normalized);
  if (ownerId && ownerId !== userId) {
    return { available: false, normalized, reason: 'taken' };
  }
  return { available: true, normalized };
}

function isRelationshipField(key) {
  if (NON_RELATIONSHIP_ID_FIELDS.has(key)) return false;
  return key.endsWith('_id') || key.endsWith('_by');
}

function acceptsBlankString(key) {  return key === 'date_of_birth' ||
    key === 'bio' ||
    key === 'job_title' ||
    key === 'profile_picture_file_id' ||
    key === 'profile_picture_url';
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

async function ensureSkillRow(tables, databaseId, userId, skillLevel) {
  const existing = await getSkillRowOrNull(tables, databaseId, userId);
  if (existing) return existing;

  return tables.createRow({
    databaseId,
    tableId: SKILLS_TABLE_ID,
    rowId: userId,
    data: {
      user_id: userId,
      level: skillLevel,
    },
    permissions: [Permission.read(Role.user(userId))],
  });
}

async function getSkillRowOrNull(tables, databaseId, userId) {
  try {
    return await tables.getRow({
      databaseId,
      tableId: SKILLS_TABLE_ID,
      rowId: userId,
    });
  } catch (caught) {
    if (caught?.code !== 404) throw caught;
  }

  try {
    const rows = await tables.listRows({
      databaseId,
      tableId: SKILLS_TABLE_ID,
      queries: [Query.equal('user_id', userId), Query.limit(1)],
    });
    return rows.rows.at(0) ?? null;
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

function normalizedSkillLevel(value) {
  if (typeof value !== 'string') return '';
  const normalized = value.trim().toLowerCase();
  return SKILL_LEVELS.has(normalized) ? normalized : '';
}

function normalizedGender(value) {
  if (typeof value !== 'string') return '';
  const normalized = value.trim().toLowerCase().replaceAll('-', '_');
  return GENDERS.has(normalized) ? normalized : '';
}

function normalizedRolesForWrite(value) {
  const roles = new Set();
  if (Array.isArray(value)) {
    for (const role of value) {
      if (typeof role !== 'string') continue;
      const normalized = role.trim().toLowerCase();
      if (normalized === 'normal_user') {
        roles.add('user');
      } else if (APP_ROLES.has(normalized)) {
        roles.add(normalized);
      }
    }
  }
  if (roles.size === 0) roles.add('user');
  return [...roles];
}

export const testOnly = {
  DEFAULT_MEMBERSHIP_LEVEL_ID,
  editableData,
  initialUserRowData,
  normalizeExistingUpdateData,
  normalizedGender,
  normalizedRolesForWrite,
  normalizedSkillLevel,
  normalizeUsername,
  isValidUsername,
  parseCheckUsername,
  RESERVED_USERNAMES,
};

function header(req, name) {
  const lowerName = name.toLowerCase();
  const match = Object.entries(req.headers ?? {}).find(
    ([key]) => key.toLowerCase() === lowerName,
  );
  return match?.[1] ?? '';
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}
