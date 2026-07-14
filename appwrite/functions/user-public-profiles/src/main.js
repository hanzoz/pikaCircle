import { Client, Query, TablesDB } from 'node-appwrite';

const USERS_TABLE_ID = 'users';
const MAX_IDS_PER_REQUEST = 500;
const MAX_IDS_PER_QUERY = 100;

export default async ({ req, res, error }) => {
  if (req.method !== 'POST') {
    return res.json({ error: 'Method not allowed' }, 405);
  }

  const userId = header(req, 'x-appwrite-user-id');
  if (!userId) {
    return res.json({ error: 'Sign in to continue.' }, 401);
  }

  const body = parseBody(req);
  if (body == null) {
    return res.json({ error: 'Invalid JSON body.' }, 400);
  }

  const userIds = sanitizeUserIds(body.userIds);
  if (userIds.length == 0) {
    return res.json({ namesByUserId: {} }, 200);
  }
  if (userIds.length > MAX_IDS_PER_REQUEST) {
    return res.json(
      { error: `Too many userIds; max ${MAX_IDS_PER_REQUEST}.` },
      400,
    );
  }

  const client = new Client()
    .setEndpoint(requiredEnv('APPWRITE_FUNCTION_API_ENDPOINT'))
    .setProject(requiredEnv('APPWRITE_FUNCTION_PROJECT_ID'))
    .setKey(requiredEnv('APPWRITE_API_KEY'));

  const tables = new TablesDB(client);
  const databaseId = requiredEnv('APPWRITE_DATABASE_ID');

  try {
    const namesByUserId = {};
    const avatarByUserId = {};
    const avatarFileIdByUserId = {};

    for (let start = 0; start < userIds.length; start += MAX_IDS_PER_QUERY) {
      const end = Math.min(start + MAX_IDS_PER_QUERY, userIds.length);
      const batch = userIds.slice(start, end);

      const rows = await tables.listRows({
        databaseId,
        tableId: USERS_TABLE_ID,
        queries: [Query.equal('$id', batch), Query.limit(MAX_IDS_PER_QUERY)],
      });

      for (const row of rows.rows) {
        const id = stringValue(row.$id) ?? stringValue(row?.$id) ?? stringValue(row?.id);
        const name = stringValue(row?.name) ?? stringValue(row?.username);
        if (id && name) {
          namesByUserId[id] = name;
        }
        const avatar = stringValue(row?.profile_picture_url);
        if (id && avatar) {
          avatarByUserId[id] = avatar;
        }
        const avatarFileId = stringValue(row?.profile_picture_file_id);
        if (id && avatarFileId) {
          avatarFileIdByUserId[id] = avatarFileId;
        }
      }
    }

    return res.json({ namesByUserId, avatarByUserId, avatarFileIdByUserId }, 200);
  } catch (caught) {
    error(caught?.message ?? String(caught));
    return res.json({ error: 'Could not load user display names.' }, 500);
  }
};

function parseBody(req) {
  if (req.bodyJson && typeof req.bodyJson === 'object') return req.bodyJson;
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

function sanitizeUserIds(value) {
  if (!Array.isArray(value)) return [];
  const seen = new Set();
  const ids = [];

  for (const item of value) {
    const id = stringValue(item);
    if (!id || seen.has(id)) continue;
    seen.add(id);
    ids.push(id);
  }

  return ids;
}

function stringValue(value) {
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function header(req, name) {
  return req.headers?.[name] ?? req.headers?.[name.toLowerCase()];
}

function requiredEnv(key) {
  const value = process.env[key];
  if (!value) throw new Error(`Missing environment variable ${key}`);
  return value;
}
