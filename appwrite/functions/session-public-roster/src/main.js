import { Client, Query, TablesDB } from 'node-appwrite';

const SESSIONS_TABLE_ID = 'sessions';
const PARTICIPANTS_TABLE_ID = 'session_participants';
const USERS_TABLE_ID = 'users';
const MAX_IDS_PER_REQUEST = 200;
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

  const sessionIds = sanitizeIds(body.sessionIds);
  if (sessionIds.length == 0) {
    return res.json({ rosterBySession: {} }, 200);
  }
  if (sessionIds.length > MAX_IDS_PER_REQUEST) {
    return res.json({ error: 'Too many sessionIds; max 200.' }, 400);
  }

  const client = new Client()
    .setEndpoint(requiredEnv('APPWRITE_FUNCTION_API_ENDPOINT'))
    .setProject(requiredEnv('APPWRITE_FUNCTION_PROJECT_ID'))
    .setKey(requiredEnv('APPWRITE_API_KEY'));

  const tables = new TablesDB(client);
  const databaseId = requiredEnv('APPWRITE_DATABASE_ID');

  try {
    // Step 1: Verify published sessions.
    const publishedSessionIds = [];
    const publishedSet = new Set();

    for (let start = 0; start < sessionIds.length; start += MAX_IDS_PER_QUERY) {
      const end = Math.min(start + MAX_IDS_PER_QUERY, sessionIds.length);
      const batch = sessionIds.slice(start, end);

      const rows = await tables.listRows({
        databaseId,
        tableId: SESSIONS_TABLE_ID,
        queries: [Query.equal('$id', batch), Query.limit(MAX_IDS_PER_QUERY)],
      });

      for (const row of rows.rows) {
        const id = stringValue(row?.$id);
        if (id && row?.status === 'published' && !publishedSet.has(id)) {
          publishedSet.add(id);
          publishedSessionIds.push(id);
        }
      }
    }

    if (publishedSessionIds.length == 0) {
      return res.json({ rosterBySession: {} }, 200);
    }

    // Step 2: Fetch participant rows for published sessions.
    const participantRows = [];

    for (
      let start = 0;
      start < publishedSessionIds.length;
      start += MAX_IDS_PER_QUERY
    ) {
      const end = Math.min(start + MAX_IDS_PER_QUERY, publishedSessionIds.length);
      const batch = publishedSessionIds.slice(start, end);

      const rows = await tables.listRows({
        databaseId,
        tableId: PARTICIPANTS_TABLE_ID,
        queries: [
          Query.equal('session_id', batch),
          Query.equal('status', ['confirmed', 'checked_in', 'waitlisted']),
          Query.limit(500),
        ],
      });

      for (const row of rows.rows) {
        participantRows.push(row);
      }
    }

    // Step 3: Resolve names/avatars for participant userIds.
    const userIdSet = new Set();
    const userIds = [];
    for (const row of participantRows) {
      const uid = relationId(row?.user_id);
      if (uid && !userIdSet.has(uid)) {
        userIdSet.add(uid);
        userIds.push(uid);
      }
    }

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
        const id = stringValue(row?.$id);
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

    // Step 4: Build rosterBySession.
    const rosterBySession = {};
    for (const id of publishedSessionIds) {
      rosterBySession[id] = {
        confirmed: [],
        waitlisted: [],
        confirmedCount: 0,
        waitlistCount: 0,
      };
    }

    for (const row of participantRows) {
      const sessionId = relationId(row?.session_id);
      const uid = relationId(row?.user_id);
      if (!sessionId || !uid) continue;

      const entry = rosterBySession[sessionId];
      if (!entry) continue;

      const isWaitlisted = row?.status === 'waitlisted';
      const participant = {
        userId: uid,
        name: namesByUserId[uid] ?? null,
        avatarUrl: avatarByUserId[uid] ?? null,
        avatarFileId: avatarFileIdByUserId[uid] ?? null,
      };

      if (isWaitlisted) {
        entry.waitlisted.push(participant);
      } else {
        entry.confirmed.push(participant);
      }
    }

    // Step 5: Set counts to match array lengths.
    for (const id of publishedSessionIds) {
      const entry = rosterBySession[id];
      entry.confirmedCount = entry.confirmed.length;
      entry.waitlistCount = entry.waitlisted.length;
    }

    return res.json({ rosterBySession }, 200);
  } catch (caught) {
    error(caught?.message ?? String(caught));
    return res.json({ error: 'Could not load session roster.' }, 500);
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

function sanitizeIds(value) {
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

function relationId(value) {
  if (value && typeof value === 'object') {
    return stringValue(value.$id);
  }
  return stringValue(value);
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
