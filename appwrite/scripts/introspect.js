// Read-only introspection of the live Appwrite project.
// Creates/changes nothing. Prints current databases, tables, buckets, functions.
const sdk = require('node-appwrite');
const fs = require('fs');
const path = require('path');

function loadEnv(file) {
  const out = {};
  const raw = fs.readFileSync(file, 'utf8');
  for (const line of raw.split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?\s*$/);
    if (m) out[m[1]] = m[2];
  }
  return out;
}

(async () => {
  const root = path.resolve(__dirname, '..', '..');
  const env = loadEnv(path.join(root, '.env'));
  const clientEnv = loadEnv(path.join(root, '.env.client'));

  const endpoint = env.APPWRITE_ENDPOINT || clientEnv.APPWRITE_ENDPOINT;
  const project = env.APPWRITE_PROJECT_ID || clientEnv.APPWRITE_PROJECT_ID;
  const apiKey = env.APPWRITE_API_KEY;
  const databaseId = clientEnv.APPWRITE_DATABASE_ID;
  const avatarBucket = clientEnv.APPWRITE_AVATAR_BUCKET_ID;
  const announcementBucket = clientEnv.APPWRITE_ANNOUNCEMENT_BUCKET_ID;

  if (!apiKey) throw new Error('APPWRITE_API_KEY missing from .env');

  const client = new sdk.Client()
    .setEndpoint(endpoint)
    .setProject(project)
    .setKey(apiKey);

  const tablesDB = new sdk.TablesDB(client);
  const databases = new sdk.Databases(client);
  const storage = new sdk.Storage(client);
  const functions = new sdk.Functions(client);

  const report = { endpoint, project, databaseId, expectedBuckets: { avatarBucket, announcementBucket } };

  // Databases
  try {
    const dbs = await databases.list();
    report.databases = dbs.databases.map((d) => ({ id: d.$id, name: d.name }));
  } catch (e) {
    report.databasesError = `${e.code ?? ''} ${e.message ?? e}`;
  }

  // Collections in the target database
  try {
    const cols = await databases.listCollections({ databaseId });
    report.collectionCount = cols.total;
    report.collections = [];
    for (const c of cols.collections) {
      let attributes = 0;
      let indexes = 0;
      let rows = 0;
      try {
        const a = await databases.listAttributes({ databaseId, collectionId: c.$id });
        attributes = a.total;
      } catch (_) {}
      try {
        const i = await databases.listIndexes({ databaseId, collectionId: c.$id });
        indexes = i.total;
      } catch (_) {}
      try {
        const r = await databases.listDocuments({ databaseId, collectionId: c.$id, queries: [] });
        rows = r.total;
      } catch (_) {}
      report.collections.push({ id: c.$id, attributes, indexes, rows });
    }
  } catch (e) {
    report.collectionsError = `${e.code ?? ''} ${e.message ?? e}`;
  }

  // Buckets
  try {
    const buckets = await storage.listBuckets();
    report.buckets = buckets.buckets.map((b) => ({ id: b.$id, name: b.name }));
  } catch (e) {
    report.bucketsError = `${e.code ?? ''} ${e.message ?? e}`;
  }

  // Functions
  try {
    const fns = await functions.list();
    report.functions = fns.functions.map((f) => ({
      id: f.$id,
      name: f.name,
      runtime: f.runtime,
      deployment: f.deployment || null,
      enabled: f.enabled,
    }));
  } catch (e) {
    report.functionsError = `${e.code ?? ''} ${e.message ?? e}`;
  }

  console.log(JSON.stringify(report, null, 2));
})().catch((e) => {
  console.error('INTROSPECTION FAILED:', e.code ?? '', e.message ?? e);
  process.exit(1);
});
