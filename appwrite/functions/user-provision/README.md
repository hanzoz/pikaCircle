# user-provision

Event-triggered Appwrite Function that auto-provisions a new user at registration time. It listens to the
`users.*.create` event, so it fires for **both** email/password and Google OAuth signups.

The function derives the new user from the event payload (the created user object delivered as JSON), then performs
three idempotent steps:

1. **Auth label** — ensures the `user` label is present on the auth account (preserving any existing labels).
2. **`users` row** — creates `users/{userId}` when missing, with `roles=['user']`, `membership_level_id=bronze`,
   `job_title_verified=false`, and a unique auto-generated `username`. Existing rows are left unchanged.
3. **`wallet` row** — provisions `wallet/{userId}` when missing with `10` free credits, `0` paid credits, and an
   expiry at the end of the current UTC month. Existing wallets are left unchanged.

Because it is fully idempotent, re-delivery of the event will not duplicate or overwrite anything.

## Username

Every user gets a `username` auto-generated at signup (derived from their name, falling back to the email local part).
Usernames are **unique**, enforced by both a unique DB index (`username_unique`) and a server-side existence check with
retry. The user can change their handle later via the `profile-upsert` function.

Format rules (shared with `profile-upsert`):

- lowercase, allowed characters `[a-z0-9_]`, length 3–30, must start with a letter.
- Normalization: lowercase, trim, replace any run of invalid characters with `_`, collapse repeated `_`, strip
  leading/trailing `_`, prefix `u` if it does not start with a letter, and clamp to 30 characters.
- Reserved names (`admin`, `root`, `support`, `pikacircle`, `system`, `me`, `null`, `undefined`) are avoided.

Required function variables:

- `APPWRITE_API_KEY` with TablesDB row read/create permissions for the `main` database, plus Users read/write scope
  (needed for `updateLabels`).
- `APPWRITE_DATABASE_ID=main`

Appwrite provides `APPWRITE_FUNCTION_API_ENDPOINT` and `APPWRITE_FUNCTION_PROJECT_ID` at runtime.
