// Deploys the PikaCircle Appwrite Functions (profile-upsert, session-join) to
// the live project, then sets their server-side environment variables.
//
// - Creates each function if missing (idempotent).
// - Packages the function source as a gzipped tarball (node_modules/.tmp
//   excluded; Appwrite runs `npm install` server-side via `commands`).
// - Creates and activates a deployment, waiting for the build to finish.
// - Upserts required env variables (including the API key) as secrets.
//
// Secrets come from the root .env and are never written to disk/committed.
//
// Usage:
//   NODE_PATH=appwrite/functions/profile-upsert/node_modules \
//     node appwrite/scripts/deploy-functions.js
const sdk = require('node-appwrite');
const { InputFile } = require('node-appwrite/file');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const os = require('os');

const ROOT = path.resolve(__dirname, '..', '..');
const APPWRITE_DIR = path.resolve(__dirname, '..');
const FUNCTIONS = JSON.parse(fs.readFileSync(path.join(APPWRITE_DIR, 'functions.json'), 'utf8'));

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

const client = new sdk.Client()
  .setEndpoint(env.APPWRITE_ENDPOINT)
  .setProject(env.APPWRITE_PROJECT_ID)
  .setKey(env.APPWRITE_API_KEY);

const functions = new sdk.Functions(client);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Env vars each function needs at runtime. The APPWRITE_FUNCTION_* values are
// auto-injected by Appwrite; we set the API key and database id explicitly.
const FUNCTION_VARIABLES = {
  APPWRITE_API_KEY: env.APPWRITE_API_KEY,
  APPWRITE_DATABASE_ID: env.APPWRITE_DATABASE_ID || 'main',
};

async function ensureFunction(def) {
  // events/scopes are NOT set by create() alone in a way that survives, and
  // must be kept in sync for existing functions too, so the manifest stays the
  // source of truth (e.g. user-provision's users.*.create trigger + user scopes).
  const config = {
    name: def.name,
    runtime: def.runtime,
    execute: def.execute || [],
    events: def.events || [],
    scopes: def.scopes || [],
    schedule: def.schedule || '',
    timeout: def.timeout || 15,
    enabled: def.enabled !== false,
    logging: def.logging !== false,
    entrypoint: def.entrypoint,
    commands: def.commands,
  };
  try {
    await functions.get({ functionId: def.$id });
    await functions.update({ functionId: def.$id, ...config });
    console.log(`  function ${def.$id} exists (events/scopes synced)`);
  } catch (e) {
    if (e.code !== 404) throw e;
    await functions.create({ functionId: def.$id, ...config });
    console.log(`  function ${def.$id} created`);
  }
}

function packageSource(def) {
  const srcDir = path.resolve(APPWRITE_DIR, def.path);
  const tarball = path.join(os.tmpdir(), `${def.$id}-${Date.now()}.tar.gz`);
  // Exclude node_modules and .tmp; Appwrite installs deps server-side.
  execFileSync(
    'tar',
    ['--exclude', './node_modules', '--exclude', './.tmp', '-czf', tarball, '-C', srcDir, '.'],
    { stdio: 'pipe' },
  );
  return tarball;
}

async function deploy(def) {
  const tarball = packageSource(def);
  try {
    const deployment = await functions.createDeployment({
      functionId: def.$id,
      code: InputFile.fromPath(tarball, `${def.$id}.tar.gz`),
      activate: true,
      entrypoint: def.entrypoint,
      commands: def.commands,
    });
    console.log(`  deployment ${deployment.$id} created for ${def.$id}, building...`);
    await waitForBuild(def.$id, deployment.$id);
  } finally {
    fs.rmSync(tarball, { force: true });
  }
}

async function waitForBuild(functionId, deploymentId, timeoutMs = 300000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const d = await functions.getDeployment({ functionId, deploymentId });
    const status = d.status;
    if (status === 'ready') {
      console.log(`  build ready for ${functionId}`);
      return;
    }
    if (status === 'failed') {
      throw new Error(`build FAILED for ${functionId}: ${d.buildLogs?.slice(-500) || '(no logs)'}`);
    }
    await sleep(3000);
  }
  throw new Error(`Timed out waiting for build of ${functionId}`);
}

async function setVariables(def) {
  // Load existing variables so we can upsert (create or update) idempotently.
  const existing = await functions.listVariables({ functionId: def.$id });
  const byKey = new Map(existing.variables.map((v) => [v.key, v]));
  for (const [key, value] of Object.entries(FUNCTION_VARIABLES)) {
    if (value == null || value === '') continue;
    try {
      if (byKey.has(key)) {
        await functions.updateVariable({ functionId: def.$id, variableId: byKey.get(key).$id, key, value, secret: true });
        console.log(`    var ${def.$id}.${key} updated`);
      } else {
        await functions.createVariable({ functionId: def.$id, key, value, secret: true });
        console.log(`    var ${def.$id}.${key} created`);
      }
    } catch (e) {
      throw new Error(`variable ${def.$id}.${key}: ${e.message ?? e}`);
    }
  }
}

async function main() {
  if (!env.APPWRITE_API_KEY) throw new Error('APPWRITE_API_KEY missing from .env');

  // Optional CLI filter: `node deploy-functions.js <id> [<id> ...]` deploys only
  // the named functions. With no args, all functions in the manifest deploy.
  const only = process.argv.slice(2);
  const targets = only.length
    ? FUNCTIONS.filter((d) => only.includes(d.$id))
    : FUNCTIONS;
  if (only.length && targets.length !== only.length) {
    const found = new Set(targets.map((d) => d.$id));
    const missing = only.filter((id) => !found.has(id));
    throw new Error(`Unknown function id(s): ${missing.join(', ')}`);
  }

  for (const def of targets) {
    console.log(`\n== ${def.$id} ==`);
    await ensureFunction(def);
    await setVariables(def);   // set vars before deploy so the build/runtime sees them
    await deploy(def);
  }

  console.log('\nFunction deployment complete.');
}

main().catch((e) => {
  console.error('\nDEPLOY FAILED:', e.message ?? e);
  process.exit(1);
});
