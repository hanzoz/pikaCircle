import { Client, ID, Permission, Query, Role, TablesDB } from 'node-appwrite';

const USERS_TABLE_ID = 'users';
const WALLET_TABLE_ID = 'wallet';
const TRANSACTIONS_TABLE_ID = 'transactions';
const SKILLS_TABLE_ID = 'skills';
const USER_PLAY_PREFERENCES_TABLE_ID = 'user_play_preferences';
const USER_FAVOURITE_VENUES_TABLE_ID = 'user_favourite_venues';
const USER_SPORTS_BACKGROUNDS_TABLE_ID = 'user_sports_backgrounds';
const VENUES_TABLE_ID = 'venues';
const SPORTS_TABLE_ID = 'sports';
const PLAY_FORMATS_TABLE_ID = 'play_formats';
const DEFAULT_MEMBERSHIP_LEVEL_ID = 'bronze';
const MONTHLY_FREE_CREDITS = 10;
const SKILL_LEVELS = new Set(['beginner', 'intermediate', 'competitive']);
const GENDERS = new Set(['male', 'female', 'non_binary']);
const SALARY_RANGES = new Set([
  'below_3k',
  '3k_6k',
  '6k_10k',
  '10k_20k',
  '20k_plus',
  'prefer_not_to_say',
]);
const TIME_SLOTS = new Set(['morning', 'afternoon', 'evening', 'night']);
const WEEK_DAYS = new Set([
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
]);
const APP_ROLES = new Set(['user', 'host', 'admin']);
const EDITABLE_RELATIONSHIP_FIELDS = new Set([]);
const NON_RELATIONSHIP_ID_FIELDS = new Set(['profile_picture_file_id']);
const AGGREGATE_KEYS = [
  'profile',
  'play_preferences',
  'favourite_venues',
  'sports_backgrounds',
];
const MAX_IDS_PER_QUERY = 100;
const CHILD_ROWS_LIMIT = 500;

class ValidationError extends Error {}

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
  'phone_number',
  'company',
  'industry',
  'salary_range',
  'location_label',
  'location_city',
  'location_state',
  'location_country',
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

  const isAggregate = isAggregatePayload(body);
  const profileSource = isAggregate ? aggregateProfileSource(body) : body;

  const attemptedProtectedField = Object.keys(profileSource).find((key) =>
    protectedFields.has(key),
  );
  if (attemptedProtectedField) {
    return res.json(
      { error: `Protected profile field: ${attemptedProtectedField}` },
      400,
    );
  }

  if (hasInvalidSalaryRange(profileSource)) {
    return res.json({ error: 'Invalid salary_range value.' }, 400);
  }

  const { skillLevel, data } = editableData(profileSource);
  if (!isAggregate && Object.keys(data).length === 0 && !skillLevel) {
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

    // Validate everything (enums + referenced ids) BEFORE any write so the
    // whole aggregate save is fail-closed and idempotent on retry.
    const playPreferences = isAggregate
      ? normalizePlayPreferences(body.play_preferences)
      : null;
    const favouriteVenues = isAggregate
      ? normalizeFavouriteVenues(body.favourite_venues)
      : null;
    const sportsBackgrounds = isAggregate
      ? normalizeSportsBackgrounds(body.sports_backgrounds)
      : null;

    if (playPreferences) {
      await assertIdsExist(
        tables,
        databaseId,
        PLAY_FORMATS_TABLE_ID,
        playPreferences.preferred_format_ids,
        'preferred_format_ids',
      );
    }
    if (favouriteVenues) {
      await assertIdsExist(
        tables,
        databaseId,
        VENUES_TABLE_ID,
        favouriteVenues.map((v) => v.venue_id),
        'venue_id',
      );
    }
    if (sportsBackgrounds) {
      await assertIdsExist(
        tables,
        databaseId,
        SPORTS_TABLE_ID,
        sportsBackgrounds.map((s) => s.sport_id),
        'sport_id',
      );
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

    // Related tables: play_preferences -> favourite_venues -> sports_backgrounds.
    let playPreferencesId = null;
    let favouriteVenuesResult = null;
    let sportsBackgroundsResult = null;

    if (playPreferences) {
      playPreferencesId = await upsertPlayPreferences(
        tables,
        databaseId,
        userId,
        playPreferences,
      );
    }
    if (favouriteVenues) {
      favouriteVenuesResult = await reconcileFavouriteVenues(
        tables,
        databaseId,
        userId,
        favouriteVenues,
      );
    }
    if (sportsBackgrounds) {
      sportsBackgroundsResult = await reconcileSportsBackgrounds(
        tables,
        databaseId,
        userId,
        sportsBackgrounds,
      );
    }

    log(`Profile, skill, and wallet provisioned for ${userId}`);
    const response = {
      id: row.$id,
      skillId: skill?.$id ?? null,
      walletId: wallet.$id,
      updated: true,
    };
    if (isAggregate) {
      response.playPreferencesId = playPreferencesId;
      response.favouriteVenues = favouriteVenuesResult;
      response.sportsBackgrounds = sportsBackgroundsResult;
    }
    return res.json(response);
  } catch (caught) {
    if (caught instanceof ValidationError) {
      return res.json({ error: caught.message }, 400);
    }
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
  if (key === 'salary_range') return normalizedSalaryRange(trimmed);
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
    key === 'profile_picture_url' ||
    key === 'phone_number' ||
    key === 'company' ||
    key === 'industry' ||
    key === 'location_label' ||
    key === 'location_city' ||
    key === 'location_state' ||
    key === 'location_country';
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

function normalizedSalaryRange(value) {
  if (typeof value !== 'string') return '';
  const normalized = value.trim().toLowerCase();
  return SALARY_RANGES.has(normalized) ? normalized : '';
}

function hasInvalidSalaryRange(source) {
  const raw = source?.salary_range;
  if (typeof raw !== 'string') return false;
  const trimmed = raw.trim();
  if (trimmed === '') return false; // Empty is omitted (not blankable), not invalid.
  return normalizedSalaryRange(trimmed) === '';
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

// --- Aggregate Edit-Profile payload helpers -------------------------------

function isAggregatePayload(body) {
  if (!body || typeof body !== 'object') return false;
  return AGGREGATE_KEYS.some((key) =>
    Object.prototype.hasOwnProperty.call(body, key),
  );
}

function aggregateProfileSource(body) {
  const profile = body?.profile;
  return profile && typeof profile === 'object' && !Array.isArray(profile)
    ? profile
    : {};
}

// Relationship columns can read back as either a string id or an expanded
// object with a `$id`. Normalize both to a trimmed id (or null).
function relationId(value) {
  if (value && typeof value === 'object') {
    return relationId(value.$id);
  }
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeInteger(value) {
  if (typeof value === 'number' && Number.isInteger(value)) return value;
  if (typeof value === 'string' && value.trim() !== '') {
    const parsed = Number(value.trim());
    if (Number.isInteger(parsed)) return parsed;
  }
  return null;
}

function normalizeEnumArray(values, allowed, label) {
  if (values == null) return [];
  if (!Array.isArray(values)) {
    throw new ValidationError(`${label} must be an array.`);
  }
  const seen = new Set();
  const out = [];
  for (const value of values) {
    if (typeof value !== 'string') {
      throw new ValidationError(`Invalid ${label} value.`);
    }
    const normalized = value.trim().toLowerCase();
    if (!allowed.has(normalized)) {
      throw new ValidationError(`Invalid ${label} value: ${value}`);
    }
    if (!seen.has(normalized)) {
      seen.add(normalized);
      out.push(normalized);
    }
  }
  return out;
}

function normalizeIdList(values, label) {
  if (values == null) return [];
  if (!Array.isArray(values)) {
    throw new ValidationError(`${label} must be an array.`);
  }
  const seen = new Set();
  const out = [];
  for (const value of values) {
    const id = relationId(value);
    if (!id) {
      throw new ValidationError(`Invalid ${label} value.`);
    }
    if (!seen.has(id)) {
      seen.add(id);
      out.push(id);
    }
  }
  return out;
}

function normalizePlayPreferences(input) {
  if (input == null) return null;
  if (typeof input !== 'object' || Array.isArray(input)) {
    throw new ValidationError('play_preferences must be an object.');
  }
  return {
    preferred_time_slots: normalizeEnumArray(
      input.preferred_time_slots,
      TIME_SLOTS,
      'preferred_time_slots',
    ),
    preferred_days: normalizeEnumArray(
      input.preferred_days,
      WEEK_DAYS,
      'preferred_days',
    ),
    preferred_format_ids: normalizeIdList(
      input.preferred_format_ids,
      'preferred_format_ids',
    ),
    notes: typeof input.notes === 'string' ? input.notes.trim() : '',
  };
}

function normalizeFavouriteVenues(input) {
  if (input == null) return null;
  if (!Array.isArray(input)) {
    throw new ValidationError('favourite_venues must be an array.');
  }
  const byVenue = new Map();
  for (const item of input) {
    if (typeof item !== 'object' || item == null || Array.isArray(item)) {
      throw new ValidationError('Invalid favourite_venues entry.');
    }
    const venueId = relationId(item.venue_id);
    if (!venueId) {
      throw new ValidationError('favourite_venues entry missing venue_id.');
    }
    byVenue.set(venueId, {
      venue_id: venueId,
      sort_order: normalizeInteger(item.sort_order) ?? 0,
    });
  }
  return [...byVenue.values()];
}

function normalizeSportsBackgrounds(input) {
  if (input == null) return null;
  if (!Array.isArray(input)) {
    throw new ValidationError('sports_backgrounds must be an array.');
  }
  const bySport = new Map();
  for (const item of input) {
    if (typeof item !== 'object' || item == null || Array.isArray(item)) {
      throw new ValidationError('Invalid sports_backgrounds entry.');
    }
    const sportId = relationId(item.sport_id);
    if (!sportId) {
      throw new ValidationError('sports_backgrounds entry missing sport_id.');
    }
    const level =
      typeof item.level === 'string' ? item.level.trim().toLowerCase() : '';
    if (!SKILL_LEVELS.has(level)) {
      throw new ValidationError(
        `Invalid sports_backgrounds level: ${item.level}`,
      );
    }
    bySport.set(sportId, {
      sport_id: sportId,
      level,
      is_primary: item.is_primary === true,
      years_played: normalizeInteger(item.years_played),
      notes: typeof item.notes === 'string' ? item.notes.trim() : '',
    });
  }
  return [...bySport.values()];
}

function userVenueKey(userId, venueId) {
  return `${userId}:${venueId}`;
}

function userSportKey(userId, sportId) {
  return `${userId}:${sportId}`;
}

function isConflictError(caught) {
  return caught?.code === 409;
}

function chunk(items, size) {
  const chunks = [];
  for (let start = 0; start < items.length; start += size) {
    chunks.push(items.slice(start, start + size));
  }
  return chunks;
}

// Verify every referenced id exists before any write, so unknown ids fail
// closed with a 400 rather than producing dangling relationships.
async function assertIdsExist(tables, databaseId, tableId, ids, label) {
  if (!ids || ids.length === 0) return;
  const found = new Set();
  for (const batch of chunk(ids, MAX_IDS_PER_QUERY)) {
    const rows = await tables.listRows({
      databaseId,
      tableId,
      queries: [Query.equal('$id', batch), Query.limit(MAX_IDS_PER_QUERY)],
    });
    for (const row of rows.rows) {
      found.add(row.$id);
    }
  }
  const unknown = ids.filter((id) => !found.has(id));
  if (unknown.length > 0) {
    throw new ValidationError(`Unknown ${label}: ${unknown.join(', ')}`);
  }
}

async function getPlayPreferencesRowOrNull(tables, databaseId, userId) {
  try {
    return await tables.getRow({
      databaseId,
      tableId: USER_PLAY_PREFERENCES_TABLE_ID,
      rowId: userId,
    });
  } catch (caught) {
    if (caught?.code !== 404) throw caught;
  }
  try {
    const rows = await tables.listRows({
      databaseId,
      tableId: USER_PLAY_PREFERENCES_TABLE_ID,
      queries: [Query.equal('user_id', userId), Query.limit(1)],
    });
    return rows.rows.at(0) ?? null;
  } catch (caught) {
    if (caught?.code === 404) return null;
    throw caught;
  }
}

// One row per user (unique index on user_id). Prefer rowId = userId, fall back
// to a user_id lookup, and recover from a create conflict by updating.
async function upsertPlayPreferences(tables, databaseId, userId, pref) {
  const data = {
    preferred_time_slots: pref.preferred_time_slots,
    preferred_days: pref.preferred_days,
    preferred_format_ids: pref.preferred_format_ids,
    notes: pref.notes,
    updated_at: new Date().toISOString(),
  };

  const existing = await getPlayPreferencesRowOrNull(tables, databaseId, userId);
  if (existing) {
    const row = await tables.updateRow({
      databaseId,
      tableId: USER_PLAY_PREFERENCES_TABLE_ID,
      rowId: existing.$id,
      data,
    });
    return row.$id;
  }

  try {
    const row = await tables.createRow({
      databaseId,
      tableId: USER_PLAY_PREFERENCES_TABLE_ID,
      rowId: userId,
      data: { ...data, user_id: userId },
      permissions: [Permission.read(Role.user(userId))],
    });
    return row.$id;
  } catch (caught) {
    if (!isConflictError(caught)) throw caught;
    const again = await getPlayPreferencesRowOrNull(tables, databaseId, userId);
    if (!again) throw caught;
    const row = await tables.updateRow({
      databaseId,
      tableId: USER_PLAY_PREFERENCES_TABLE_ID,
      rowId: again.$id,
      data,
    });
    return row.$id;
  }
}

async function listChildRowsForUser(tables, databaseId, tableId, userId) {
  const rows = await tables.listRows({
    databaseId,
    tableId,
    queries: [Query.equal('user_id', userId), Query.limit(CHILD_ROWS_LIMIT)],
  });
  return rows.rows;
}

async function findChildRowByKey(tables, databaseId, tableId, keyField, key) {
  const rows = await tables.listRows({
    databaseId,
    tableId,
    queries: [Query.equal(keyField, key), Query.limit(1)],
  });
  return rows.rows.at(0) ?? null;
}

// Diff-by-deterministic-key reconciliation: update matches, create missing,
// delete stale rows LAST. Idempotent across retries.
async function reconcileChildSet(tables, databaseId, config) {
  const {
    tableId,
    userId,
    desired,
    keyField,
    idField,
    keyFor,
    createData,
    mutableData,
  } = config;

  const existingRows = await listChildRowsForUser(
    tables,
    databaseId,
    tableId,
    userId,
  );
  const existingByKey = new Map();
  for (const row of existingRows) {
    const key =
      (typeof row[keyField] === 'string' && row[keyField]) ||
      keyFor(userId, relationId(row[idField]));
    if (key) existingByKey.set(key, row);
  }

  let created = 0;
  let updated = 0;
  let deleted = 0;
  const desiredKeys = new Set();

  for (const item of desired) {
    const key = keyFor(userId, item[idField]);
    desiredKeys.add(key);
    const existing = existingByKey.get(key);
    if (existing) {
      await tables.updateRow({
        databaseId,
        tableId,
        rowId: existing.$id,
        data: mutableData(item),
      });
      updated += 1;
      continue;
    }
    try {
      await tables.createRow({
        databaseId,
        tableId,
        rowId: ID.unique(),
        data: createData(item, key),
        permissions: [Permission.read(Role.user(userId))],
      });
      created += 1;
    } catch (caught) {
      if (!isConflictError(caught)) throw caught;
      const found = await findChildRowByKey(
        tables,
        databaseId,
        tableId,
        keyField,
        key,
      );
      if (!found) throw caught;
      await tables.updateRow({
        databaseId,
        tableId,
        rowId: found.$id,
        data: mutableData(item),
      });
      updated += 1;
    }
  }

  for (const [key, row] of existingByKey) {
    if (desiredKeys.has(key)) continue;
    try {
      await tables.deleteRow({ databaseId, tableId, rowId: row.$id });
      deleted += 1;
    } catch (caught) {
      if (caught?.code !== 404) throw caught;
    }
  }

  return { created, updated, deleted };
}

async function reconcileFavouriteVenues(tables, databaseId, userId, desired) {
  return reconcileChildSet(tables, databaseId, {
    tableId: USER_FAVOURITE_VENUES_TABLE_ID,
    userId,
    desired,
    keyField: 'user_venue_key',
    idField: 'venue_id',
    keyFor: userVenueKey,
    createData: (item, key) => ({
      user_id: userId,
      venue_id: item.venue_id,
      sort_order: item.sort_order,
      created_at: new Date().toISOString(),
      user_venue_key: key,
    }),
    mutableData: (item) => ({ sort_order: item.sort_order }),
  });
}

async function reconcileSportsBackgrounds(tables, databaseId, userId, desired) {
  return reconcileChildSet(tables, databaseId, {
    tableId: USER_SPORTS_BACKGROUNDS_TABLE_ID,
    userId,
    desired,
    keyField: 'user_sport_key',
    idField: 'sport_id',
    keyFor: userSportKey,
    createData: (item, key) => ({
      user_id: userId,
      sport_id: item.sport_id,
      level: item.level,
      is_primary: item.is_primary,
      years_played: item.years_played,
      notes: item.notes,
      updated_at: new Date().toISOString(),
      user_sport_key: key,
    }),
    mutableData: (item) => ({
      level: item.level,
      is_primary: item.is_primary,
      years_played: item.years_played,
      notes: item.notes,
      updated_at: new Date().toISOString(),
    }),
  });
}

export const testOnly = {
  DEFAULT_MEMBERSHIP_LEVEL_ID,
  editableData,
  initialUserRowData,
  normalizeExistingUpdateData,
  normalizedGender,
  normalizedSalaryRange,
  hasInvalidSalaryRange,
  acceptsBlankString,
  normalizedRolesForWrite,
  normalizedSkillLevel,
  normalizeUsername,
  isValidUsername,
  parseCheckUsername,
  isAggregatePayload,
  aggregateProfileSource,
  relationId,
  normalizeInteger,
  normalizeEnumArray,
  normalizeIdList,
  normalizePlayPreferences,
  normalizeFavouriteVenues,
  normalizeSportsBackgrounds,
  userVenueKey,
  userSportKey,
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
