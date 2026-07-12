import { Client, ID, Permission, Query, Role, TablesDB } from 'node-appwrite';

const SESSIONS_TABLE_ID = 'sessions';
const PARTICIPANTS_TABLE_ID = 'session_participants';
const ACCESS_CODES_TABLE_ID = 'session_access_codes';
const WALLET_TABLE_ID = 'wallet';
const TRANSACTIONS_TABLE_ID = 'transactions';
const SKILLS_TABLE_ID = 'skills';

export default async ({ req, res, log, error }) => {
  if (req.method !== 'POST') {
    return res.json({ error: 'Method not allowed' }, 405);
  }

  const userId = header(req, 'x-appwrite-user-id');
  if (!userId) {
    return res.json({ error: 'Sign in to join a session.' }, 401);
  }

  const body = parseBody(req);
  if (body == null) {
    return res.json({ error: 'Invalid JSON body.' }, 400);
  }

  const sessionId = stringField(body, 'sessionId');
  if (!sessionId) {
    return res.json({ error: 'Session ID is required.' }, 400);
  }

  const accessCodeValue = stringField(body, 'accessCode');
    const client = new Client()
    .setEndpoint(requiredEnv('APPWRITE_FUNCTION_API_ENDPOINT'))
    .setProject(requiredEnv('APPWRITE_FUNCTION_PROJECT_ID'))
    .setKey(requiredEnv('APPWRITE_API_KEY'));

  const tables = new TablesDB(client);
  const databaseId = requiredEnv('APPWRITE_DATABASE_ID');

  try {
    const existing = await getExistingParticipant(tables, databaseId, sessionId, userId);
    if (existing) {
      return res.json(joinResponse(existing.status, true));
    }

    const session = await tables.getRow({
      databaseId,
      tableId: SESSIONS_TABLE_ID,
      rowId: sessionId,
    });

    const accessCode = accessCodeValue
      ? await validateAccessCode({
          tables,
          databaseId,
          code: accessCodeValue,
          sessionId,
        })
      : null;

    validateSessionAccess(session, accessCode);
    await validateSkill({ tables, databaseId, session, userId });

    const confirmedCount = await countParticipants(
      tables,
      databaseId,
      sessionId,
      ['confirmed', 'checked_in'],
    );
    const maxParticipants = numberField(session, 'max_participants');
    const isFull = maxParticipants > 0 && confirmedCount >= maxParticipants;

    const status = isFull
      ? 'waitlisted'
      : 'confirmed';
    const waitlistPosition = status === 'waitlisted'
      ? (await countParticipants(tables, databaseId, sessionId, ['waitlisted'])) + 1
      : null;
    const creditCost = status === 'confirmed'
      ? numberField(session, 'credit_cost')
      : 0;

    if (creditCost > 0) {
      await chargeWallet({ tables, databaseId, userId, sessionId, creditCost });
    }

    const now = new Date().toISOString();
    const participant = await tables.createRow({
      databaseId,
      tableId: PARTICIPANTS_TABLE_ID,
      rowId: ID.unique(),
      data: {
        session_id: sessionId,
        user_id: userId,
        role: 'player',
        status,
        waitlist_position: waitlistPosition,
        credits_charged: creditCost,
        participant_key: `${sessionId}:${userId}`,
        joined_at: now,
        confirmed_at: status === 'confirmed' ? now : null,
        waitlisted_at: status === 'waitlisted' ? now : null,
        status_updated_by: userId,
        status_updated_at: now,
      },
      permissions: [Permission.read(Role.user(userId))],
    });

    if (accessCode) {
      await markAccessCodeUsed(tables, databaseId, accessCode);
    }

    log(`Session ${sessionId} joined by ${userId}: ${status}`);
    return res.json({
      ...joinResponse(status, false),
      participantId: participant.$id,
    });
  } catch (caught) {
    if (caught instanceof JoinError) {
      return res.json({ error: caught.message }, caught.statusCode);
    }
    if (caught?.code === 409) {
      const existing = await getExistingParticipant(
        tables,
        databaseId,
        sessionId,
        userId,
      );
      if (existing) return res.json(joinResponse(existing.status, true));
    }
    error(caught?.message ?? String(caught));
    return res.json({ error: 'Could not join this session.' }, 500);
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

function validateSessionAccess(session, accessCode) {
  if (session.status !== 'published') {
    throw new JoinError('This session is not open for joining.', 400);
  }
  if (session.privacy === true && !accessCode) {
    throw new JoinError('This private session requires an invite link or QR code.', 403);
  }
  if (accessCode?.purpose === 'private_invite' && session.privacy !== true) {
    throw new JoinError('This invite is not valid for a public session.', 400);
  }
}

async function validateAccessCode({ tables, databaseId, code, sessionId }) {
  const rows = await tables.listRows({
    databaseId,
    tableId: ACCESS_CODES_TABLE_ID,
    queries: [Query.equal('code', code), Query.limit(1)],
  });
  const accessCode = rows.rows.at(0);
  if (!accessCode) throw new JoinError('Invalid join code.', 404);
  const codeSessionId = relatedId(accessCode.session_id);
  if (codeSessionId !== sessionId) {
    throw new JoinError('This join code is for a different session.', 400);
  }
  if (!['qr_join', 'private_invite'].includes(accessCode.purpose)) {
    throw new JoinError('This join code cannot be used to join a session.', 400);
  }
  if (accessCode.status !== 'active') {
    throw new JoinError('This join code is no longer active.', 400);
  }
  if (accessCode.expires_at && new Date(accessCode.expires_at) < new Date()) {
    throw new JoinError('This join code has expired.', 400);
  }
  const maxUses = numberField(accessCode, 'max_uses');
  const usesCount = numberField(accessCode, 'uses_count');
  if (maxUses > 0 && usesCount >= maxUses) {
    throw new JoinError('This join code has reached its usage limit.', 400);
  }
  return accessCode;
}

async function validateSkill({ tables, databaseId, session, userId }) {
  if (!session.skill_level) return;
  const rows = await tables.listRows({
    databaseId,
    tableId: SKILLS_TABLE_ID,
    queries: [Query.equal('user_id', userId), Query.limit(1)],
  });
  const skill = rows.rows.at(0);
  if (!skill || normalizedSkillLevel(skill.level) !== normalizedSkillLevel(session.skill_level)) {
    throw new JoinError('Your skill level does not match this session.', 403);
  }
}

async function chargeWallet({ tables, databaseId, userId, sessionId, creditCost }) {
  const wallet = await getWalletForUser(tables, databaseId, userId);
  const freeCredits = numberField(wallet, 'free_credits');
  const paidCredits = numberField(wallet, 'paid_credits');
  const totalCredits = freeCredits + paidCredits;
  if (totalCredits < creditCost) {
    throw new JoinError('You do not have enough credits for this session.', 400);
  }

  const freeToUse = Math.min(freeCredits, creditCost);
  const paidToUse = creditCost - freeToUse;
  const updatedFreeCredits = freeCredits - freeToUse;
  const updatedPaidCredits = paidCredits - paidToUse;
  const now = new Date().toISOString();

  await tables.updateRow({
    databaseId,
    tableId: WALLET_TABLE_ID,
    rowId: wallet.$id,
    data: {
      free_credits: updatedFreeCredits,
      paid_credits: updatedPaidCredits,
      freeCredits: updatedFreeCredits,
      paidCredits: updatedPaidCredits,
    },
  });

  await tables.createRow({
    databaseId,
    tableId: TRANSACTIONS_TABLE_ID,
    rowId: ID.unique(),
    data: {
      user_id: userId,
      session_id: sessionId,
      type: 'session_charge',
      amount: 0,
      currency: 'CREDITS',
      credits_delta: -creditCost,
      transaction_date: now,
      remarks: `Session join charge: ${creditCost} credits`,
    },
    permissions: [Permission.read(Role.user(userId))],
  });
}

async function getWalletForUser(tables, databaseId, userId) {
  try {
    return await tables.getRow({
      databaseId,
      tableId: WALLET_TABLE_ID,
      rowId: userId,
    });
  } catch (caught) {
    if (caught?.code !== 404) throw caught;
  }
  const rows = await tables.listRows({
    databaseId,
    tableId: WALLET_TABLE_ID,
    queries: [Query.equal('user_id', userId), Query.limit(1)],
  });
  const wallet = rows.rows.at(0);
  if (!wallet) throw new JoinError('Wallet is not ready yet.', 400);
  return wallet;
}

async function getExistingParticipant(tables, databaseId, sessionId, userId) {
  const rows = await tables.listRows({
    databaseId,
    tableId: PARTICIPANTS_TABLE_ID,
    queries: [
      Query.equal('participant_key', `${sessionId}:${userId}`),
      Query.limit(1),
    ],
  });
  return rows.rows.at(0) ?? null;
}

async function countParticipants(tables, databaseId, sessionId, statuses) {
  const rows = await tables.listRows({
    databaseId,
    tableId: PARTICIPANTS_TABLE_ID,
    queries: [
      Query.equal('session_id', sessionId),
      Query.equal('status', statuses),
      Query.limit(1),
    ],
  });
  return rows.total;
}

async function markAccessCodeUsed(tables, databaseId, accessCode) {
  await tables.updateRow({
    databaseId,
    tableId: ACCESS_CODES_TABLE_ID,
    rowId: accessCode.$id,
    data: {
      uses_count: numberField(accessCode, 'uses_count') + 1,
      last_used_at: new Date().toISOString(),
    },
  });
}

function joinResponse(status, existing) {
  const message = existing
    ? existingJoinMessage(status)
    : newJoinMessage(status);
  return { status, message, existing };
}

function newJoinMessage(status) {
  switch (status) {
    case 'confirmed':
      return 'You are confirmed for this session.';
    case 'waitlisted':
      return 'This session is full. You are on the waitlist.';
    default:
      return 'Session join request completed.';
  }
}

function existingJoinMessage(status) {
  switch (status) {
    case 'confirmed':
      return 'You are already confirmed for this session.';
    case 'waitlisted':
      return 'You are already on the waitlist for this session.';
    default:
      return 'You have already joined this session.';
  }
}

function stringField(data, key) {
  const value = data[key];
  return typeof value === 'string' ? value.trim() : '';
}

function numberField(data, key) {
  const value = data[key];
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  return 0;
}

function relatedId(value) {
  if (typeof value === 'string') return value;
  if (value && typeof value === 'object' && typeof value.$id === 'string') {
    return value.$id;
  }
  return '';
}

function normalizedSkillLevel(value) {
  if (typeof value !== 'string') return '';
  switch (value.trim().toLowerCase()) {
    case 'beginner':
    case 'newbie':
      return 'beginner';
    case 'intermediate':
      return 'intermediate';
    case 'competitive':
    case 'advanced':
    case 'pro':
      return 'competitive';
    default:
      return '';
  }
}

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

class JoinError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
  }
}
