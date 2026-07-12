// Idempotent provisioner for the PikaCircle Appwrite backend (Appwrite 1.8.x).
//
// This server exposes the classic Databases API (collections + attributes),
// not the newer TablesDB (tables + columns) column routes. So we provision with
// Databases.* attribute methods. Collections were already created via the
// TablesDB.createTable alias; ensureCollection() is idempotent either way.
//
// Order: database -> buckets -> collections -> scalar attributes -> (wait) ->
//   relationship attributes -> (wait) -> indexes -> seed documents.
// Safe to re-run: HTTP 409 conflicts are treated as "already exists".
//
// Usage:
//   NODE_PATH=appwrite/functions/profile-upsert/node_modules \
//     node appwrite/scripts/provision.js
const sdk = require('node-appwrite');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const SCHEMA = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'schema', 'mvp-schema.json'), 'utf8'),
);

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
const AVATAR_BUCKET = env.APPWRITE_AVATAR_BUCKET_ID || 'avatars';
const ANNOUNCEMENT_BUCKET = env.APPWRITE_ANNOUNCEMENT_BUCKET_ID || 'announcements';

const client = new sdk.Client()
  .setEndpoint(env.APPWRITE_ENDPOINT)
  .setProject(env.APPWRITE_PROJECT_ID)
  .setKey(env.APPWRITE_API_KEY);

const databases = new sdk.Databases(client);
const storage = new sdk.Storage(client);
const { Permission, Role, ID } = sdk;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const isConflict = (e) => e && (e.code === 409 || e.type === 'attribute_already_exists' || e.type === 'index_already_exists' || e.type === 'document_already_exists');

function parsePermission(str) {
  const m = str.match(/^(\w+)\("([^"]+)"\)$/);
  if (!m) return null;
  const [, action, target] = m;
  const role = target === 'any' ? Role.any() : target === 'users' ? Role.users() : Role.label(target);
  const fn = Permission[action];
  return fn ? fn(role) : null;
}
const tablePermissions = (t) => (t.permissions || []).map(parsePermission).filter(Boolean);

async function ensureDatabase() {
  try {
    await databases.get({ databaseId: DATABASE_ID });
    console.log(`  db "${DATABASE_ID}" exists`);
  } catch (e) {
    if (e.code !== 404) throw e;
    await databases.create({ databaseId: DATABASE_ID, name: SCHEMA.database.name });
    console.log(`  db "${DATABASE_ID}" created`);
  }
}

async function ensureBucket(id, name) {
  try {
    await storage.getBucket({ bucketId: id });
    console.log(`  bucket "${id}" exists`);
  } catch (e) {
    if (e.code !== 404) throw e;
    await storage.createBucket({
      bucketId: id,
      name,
      permissions: [Permission.read(Role.users())],
      fileSecurity: true,
      enabled: true,
    });
    console.log(`  bucket "${id}" created`);
  }
}

async function ensureCollection(t) {
  try {
    await databases.getCollection({ databaseId: DATABASE_ID, collectionId: t.id });
    console.log(`  collection ${t.id} exists`);
  } catch (e) {
    if (e.code !== 404) throw e;
    await databases.createCollection({
      databaseId: DATABASE_ID,
      collectionId: t.id,
      name: t.name,
      permissions: tablePermissions(t),
      documentSecurity: !!t.rowSecurity,
    });
    console.log(`  collection ${t.id} created`);
  }
}

async function ensureScalarAttribute(collectionId, col) {
  const base = { databaseId: DATABASE_ID, collectionId, key: col.key };
  const required = !!col.required;
  const array = !!col.array;
  const def = required || array ? undefined : col.default; // no default on required/array
  try {
    switch (col.type) {
      case 'varchar':
      case 'string':
        await databases.createStringAttribute({ ...base, size: col.size || 255, required, xdefault: def, array });
        break;
      case 'text':
      case 'longtext':
        await databases.createStringAttribute({ ...base, size: col.size || 65535, required, xdefault: def, array });
        break;
      case 'email':
        await databases.createEmailAttribute({ ...base, required, xdefault: def, array });
        break;
      case 'url':
        await databases.createUrlAttribute({ ...base, required, xdefault: def, array });
        break;
      case 'enum':
        await databases.createEnumAttribute({ ...base, elements: col.elements, required, xdefault: def, array });
        break;
      case 'boolean':
        await databases.createBooleanAttribute({ ...base, required, xdefault: def, array });
        break;
      case 'integer':
        await databases.createIntegerAttribute({ ...base, required, xdefault: def, array });
        break;
      case 'float':
        await databases.createFloatAttribute({ ...base, required, xdefault: def, array });
        break;
      case 'datetime':
        await databases.createDatetimeAttribute({ ...base, required, xdefault: def, array });
        break;
      default:
        throw new Error(`Unknown attribute type "${col.type}" for ${collectionId}.${col.key}`);
    }
    console.log(`    + ${collectionId}.${col.key} (${col.type})`);
  } catch (e) {
    if (isConflict(e)) return;
    throw new Error(`attribute ${collectionId}.${col.key}: ${e.message ?? e}`);
  }
}

const RELATION_TYPE = {
  oneToOne: sdk.RelationshipType.OneToOne,
  manyToOne: sdk.RelationshipType.ManyToOne,
  oneToMany: sdk.RelationshipType.OneToMany,
  manyToMany: sdk.RelationshipType.ManyToMany,
};

async function ensureRelationship(collectionId, rel) {
  try {
    await databases.createRelationshipAttribute({
      databaseId: DATABASE_ID,
      collectionId,
      relatedCollectionId: rel.relatedTableId,
      type: RELATION_TYPE[rel.type],
      twoWay: !!rel.twoWay,
      key: rel.key,
      twoWayKey: rel.twoWayKey,
      onDelete: rel.onDelete || 'setNull',
    });
    console.log(`    ~ ${collectionId}.${rel.key} -> ${rel.relatedTableId} (${rel.type})`);
  } catch (e) {
    if (isConflict(e)) return;
    throw new Error(`relationship ${collectionId}.${rel.key}: ${e.message ?? e}`);
  }
}

// Poll until every non-relationship attribute is available.
async function waitForAttributes(collectionId, timeoutMs = 180000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const { attributes } = await databases.listAttributes({ databaseId: DATABASE_ID, collectionId });
    const pending = attributes.filter(
      (a) => a.status && a.status !== 'available' && a.type !== 'relationship',
    );
    const failed = attributes.filter((a) => a.status === 'failed' && a.type !== 'relationship');
    if (failed.length) {
      throw new Error(`attributes failed on ${collectionId}: ${failed.map((a) => a.key).join(', ')}`);
    }
    if (pending.length === 0) return;
    await sleep(1000);
  }
  throw new Error(`Timed out waiting for attributes on ${collectionId}`);
}

async function ensureIndex(collectionId, idx, relationshipKeys) {
  // Appwrite 1.8.x rejects standard indexes on relationship attributes; those
  // relationships are already internally indexed for lookups. Skip them.
  const onRelationship = idx.columns.filter((c) => relationshipKeys.has(c));
  if (onRelationship.length) {
    console.log(`    # ${collectionId}.${idx.key} skipped (relationship attr: ${onRelationship.join(', ')})`);
    return;
  }
  try {
    await databases.createIndex({
      databaseId: DATABASE_ID,
      collectionId,
      key: idx.key,
      type: idx.type,
      attributes: idx.columns,
    });
    console.log(`    # ${collectionId}.${idx.key} (${idx.type})`);
  } catch (e) {
    if (isConflict(e)) return;
    throw new Error(`index ${collectionId}.${idx.key}: ${e.message ?? e}`);
  }
}

// Relationship attribute keys for a collection, taken from the schema itself
// (this server's listAttributes does not report relationship attributes).
function relationshipKeysFor(t) {
  return new Set((t.relationships || []).map((r) => r.key));
}

async function seedRows(seed) {
  for (const row of seed.rows) {
    try {
      await databases.createDocument({
        databaseId: DATABASE_ID,
        collectionId: seed.tableId,
        documentId: row.id || ID.unique(),
        data: row.data,
      });
      console.log(`    seed ${seed.tableId}/${row.id}`);
    } catch (e) {
      if (isConflict(e)) {
        console.log(`    seed ${seed.tableId}/${row.id} exists`);
        continue;
      }
      throw new Error(`seed ${seed.tableId}/${row.id}: ${e.message ?? e}`);
    }
  }
}

async function main() {
  if (!env.APPWRITE_API_KEY) throw new Error('APPWRITE_API_KEY missing from .env');
  const tables = SCHEMA.tables;

  console.log('1/7 database');
  await ensureDatabase();

  console.log('2/7 buckets');
  await ensureBucket(AVATAR_BUCKET, SCHEMA.bucket?.name || 'Profile avatars');
  await ensureBucket(ANNOUNCEMENT_BUCKET, 'Announcements');

  console.log('3/7 collections');
  for (const t of tables) await ensureCollection(t);

  console.log('4/7 scalar attributes');
  for (const t of tables) {
    for (const col of t.columns || []) await ensureScalarAttribute(t.id, col);
  }

  console.log('5/7 waiting for scalar attributes to become available');
  for (const t of tables) {
    if ((t.columns || []).length) await waitForAttributes(t.id);
  }

  console.log('6/7 relationship attributes');
  for (const t of tables) {
    for (const rel of t.relationships || []) await ensureRelationship(t.id, rel);
  }
  await sleep(4000);

  console.log('7/7 indexes');
  for (const t of tables) {
    if (!(t.indexes || []).length) continue;
    await waitForAttributes(t.id);
    const relKeys = relationshipKeysFor(t);
    for (const idx of t.indexes) await ensureIndex(t.id, idx, relKeys);
  }

  console.log('seeds');
  for (const seed of SCHEMA.seeds || []) await seedRows(seed);

  console.log('\nProvisioning complete.');
}

main().catch((e) => {
  console.error('\nPROVISION FAILED:', e.message ?? e);
  process.exit(1);
});
