// Ref-resolving data seeder for the PikaCircle Appwrite backend (Appwrite 1.8.x).
//
// Seeds two files, in order:
//   1) appwrite/seeds/venues.json      -> flat { tableId, rows:[{ id, data }] }
//   2) appwrite/seeds/dummy-data.json  -> [ { tableId, rows:[{ ref, <*Ref fields>, data }] } ]
//
// dummy-data.json rows reference other rows (and seeded lookup rows) via "*Ref"
// fields. This seeder resolves each ref to a real Appwrite document ID and writes
// it into the correct column/relationship key before creating the document.
//
// Ref resolution order:
//   - A row's own "ref" registers its created document ID under that ref name.
//   - Lookup rows seeded from mvp-schema.json (sports, social_platforms,
//     play_formats, gamification_reward_rules, penalty_rules, sponsors...) and
//     venues use their seed "id" as the ref value, so those refs resolve directly.
//
// Idempotent: HTTP 409 (already exists) is treated as success. Existing rows'
// refs are still registered so later rows can resolve against them.
//
// Usage:
//   NODE_PATH=appwrite/functions/profile-upsert/node_modules \
//     node appwrite/scripts/seed.js
const sdk = require('node-appwrite');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOT = path.resolve(__dirname, '..', '..');
const SEEDS_DIR = path.join(__dirname, '..', 'seeds');
const VENUES = JSON.parse(fs.readFileSync(path.join(SEEDS_DIR, 'venues.json'), 'utf8'));
const DUMMY = JSON.parse(fs.readFileSync(path.join(SEEDS_DIR, 'dummy-data.json'), 'utf8'));

function loadEnv(file) {
  const out = {};
  if (!fs.existsSync(file)) return out;
  for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?\s*$/);
    if (m) out[m[1]] = m[2];
  }
  return out;
}

const env = { ...loadEnv(path.join(ROOT, '.env.client')), ...loadEnv(path.join(ROOT, '.env')) };
const DATABASE_ID = env.APPWRITE_DATABASE_ID || 'main';

const client = new sdk.Client()
  .setEndpoint(env.APPWRITE_ENDPOINT)
  .setProject(env.APPWRITE_PROJECT_ID)
  .setKey(env.APPWRITE_API_KEY);

const databases = new sdk.Databases(client);
const { ID, Permission, Role } = sdk;

const isConflict = (e) =>
  e && (e.code === 409 || e.type === 'document_already_exists');

// Schema drives per-document permissions so seeded rows are visible to clients
// exactly like rows the app creates at runtime. Without this, row-secured
// documents seeded via the API key get empty ($permissions = []) permissions and
// become invisible to end-user queries even though the data exists.
const SCHEMA = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'schema', 'mvp-schema.json'), 'utf8'),
);
const TABLE_META = new Map(
  SCHEMA.tables.map((t) => [
    t.id,
    { rowSecurity: !!t.rowSecurity, permissions: t.permissions || [] },
  ]),
);

// Builds the document-level permissions for a seed row.
//   - Non-row-secured tables (venues, sports, ...) inherit collection perms; no
//     per-document permissions are needed.
//   - Row-secured tables whose collection grants read("users") get a broad
//     read(Role.users()) so any logged-in user can read them (sessions, skills,
//     participants, ...). This matches how the app surfaces shared data.
//   - Row-secured tables with no collection read (wallet, transactions,
//     session_access_codes, ...) are owner-scoped: read(Role.user(ownerId))
//     when an owner id is known, otherwise left private.
function documentPermissions(tableId, ownerUserId) {
  const meta = TABLE_META.get(tableId);
  if (!meta || !meta.rowSecurity) return undefined;

  const grantsUsersRead = meta.permissions.includes('read("users")');
  if (grantsUsersRead) return [Permission.read(Role.users())];

  if (ownerUserId) return [Permission.read(Role.user(ownerUserId))];
  return undefined; // private, no client read (e.g. access codes)
}

// Maps a dummy-data "*Ref" field name to the target column/relationship key on
// the row's collection. Keyed by "<tableId>.<refField>"; falls back to a global
// default map when no table-specific override exists.
const DEFAULT_REF_KEYS = {
  userRef: 'user_id',
  sportRef: 'sport_id',
  platformRef: 'platform_id',
  venueRef: 'venue_id',
  sponsorRef: 'sponsor_id',
  scoreFormatRef: 'score_format_id',
  hostRef: 'host_id',
  sessionRef: 'session_id',
  formatRef: 'format_id',
  gameRef: 'game_id',
  gameTeamRef: 'game_team_id',
  participantRef: 'participant_id',
  reviewedByRef: 'reviewed_by_user_id',
  enteredByRef: 'entered_by_user_id',
  ruleRef: 'rule_id',
  eventRef: 'event_id',
  lastEventRef: 'last_event_id',
  transactionRef: 'transaction_id',
  penaltyRuleRef: 'rule_id',
  reportedByRef: 'reported_by_user_id',
  actorUserRef: 'actor_user_id',
  targetUserRef: 'target_user_id',
  created_by_ref: 'created_by_user_id',
  created_by_user_ref: 'created_by_user_id',
  referralCodeRef: 'referral_code_id',
  referrerUserRef: 'referrer_user_id',
  inviteeUserRef: 'invitee_user_id',
  referrerTransactionRef: 'referrer_transaction_id',
  inviteeTransactionRef: 'invitee_transaction_id',
  referrerRewardGrantRef: 'referrer_reward_grant_id',
  inviteeRewardGrantRef: 'invitee_reward_grant_id',
};

// Table-specific overrides where a ref field maps to a differently named column.
const TABLE_REF_KEYS = {};

function refKeyFor(tableId, field) {
  const perTable = TABLE_REF_KEYS[tableId] && TABLE_REF_KEYS[tableId][field];
  return perTable || DEFAULT_REF_KEYS[field];
}

async function createDoc(collectionId, documentId, data, label, permissions) {
  try {
    await databases.createDocument({
      databaseId: DATABASE_ID,
      collectionId,
      documentId: documentId || ID.unique(),
      data,
      ...(permissions ? { permissions } : {}),
    });
    console.log(`    seed ${collectionId}/${label}`);
    return true;
  } catch (e) {
    if (isConflict(e)) {
      // The document already exists. Ensure its permissions match the intended
      // model (older seeds created rows with empty permissions, making them
      // invisible to client queries under document security). Patch if needed.
      if (permissions) {
        try {
          await databases.updateDocument({
            databaseId: DATABASE_ID,
            collectionId,
            documentId,
            permissions,
          });
          console.log(`    seed ${collectionId}/${label} exists (permissions synced)`);
        } catch (pe) {
          console.warn(`    ! ${collectionId}/${label}: permission sync failed: ${pe.message ?? pe}`);
        }
      } else {
        console.log(`    seed ${collectionId}/${label} exists`);
      }
      return true;
    }
    // Appwrite 1.8.x can report a relationship attribute as "already exists"
    // while still rejecting writes to it as an unknown attribute. Drop the
    // offending key and retry so seeding is not blocked by a single link.
    const m = /Unknown attribute: "([^"]+)"/.exec(e.message || '');
    if (m && m[1] in data) {
      console.warn(`    ! ${collectionId}/${label}: dropping unwritable attribute "${m[1]}"`);
      const { [m[1]]: _drop, ...rest } = data;
      return createDoc(collectionId, documentId, rest, label, permissions);
    }
    throw new Error(`seed ${collectionId}/${label}: ${e.message ?? e}`);
  }
}

// Appwrite document ids are capped at 36 chars. Venue seed ids can exceed that,
// so long ids are deterministically shortened to a prefix + short hash. The
// original id is registered as a ref alias so any venueRef still resolves.
function safeDocId(id) {
  if (id.length <= 36) return id;
  const hash = crypto.createHash('sha1').update(id).digest('hex').slice(0, 8);
  return `${id.slice(0, 27)}_${hash}`; // 27 + 1 + 8 = 36
}

async function seedVenues(refs) {
  console.log(`venues (${VENUES.rows.length})`);
  for (const row of VENUES.rows) {
    const docId = safeDocId(row.id);
    await createDoc(VENUES.tableId, docId, row.data, row.id);
    // Venue ids double as refs so dummy-data venueRefs resolve directly, even
    // when the stored document id was shortened.
    refs.set(row.id, docId);
  }
}

async function seedDummy(refs) {
  for (const table of DUMMY) {
    console.log(`${table.tableId} (${table.rows.length})`);
    for (const row of table.rows) {
      const data = { ...row.data };
      let ownerUserId;

      // Resolve every "*Ref" / "*_ref" field into its target column.
      for (const [field, value] of Object.entries(row)) {
        if (field === 'ref' || field === 'data') continue;
        if (!(field.endsWith('Ref') || field.endsWith('_ref'))) continue;
        if (value == null) continue;

        const targetKey = refKeyFor(table.tableId, field);
        if (!targetKey) {
          throw new Error(`No column mapping for ref field "${field}" on ${table.tableId}`);
        }
        const resolved = refs.has(value) ? refs.get(value) : value;
        data[targetKey] = resolved;
        // The row's owner (for owner-scoped read permissions) is its userRef.
        if (field === 'userRef') ownerUserId = resolved;
      }

      // Use the row's "ref" as its document id for deterministic, idempotent
      // seeds (all dummy-data refs are valid Appwrite ids). Register it so later
      // rows resolve their "*Ref" fields to this document.
      const documentId = row.id || row.ref || ID.unique();
      const permissions = documentPermissions(table.tableId, ownerUserId);
      await createDoc(table.tableId, documentId, data, row.ref || documentId, permissions);
      if (row.ref) refs.set(row.ref, documentId);
    }
  }
}

async function main() {
  if (!env.APPWRITE_API_KEY) throw new Error('APPWRITE_API_KEY missing from .env');

  // ref name -> real Appwrite document id
  const refs = new Map();

  console.log('1/2 venues');
  await seedVenues(refs);

  console.log('2/2 dummy data');
  await seedDummy(refs);

  console.log('\nSeeding complete.');
}

main().catch((e) => {
  console.error('\nSEED FAILED:', e.message ?? e);
  process.exit(1);
});
