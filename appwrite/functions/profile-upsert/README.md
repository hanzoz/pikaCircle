# profile-upsert

Trusted Appwrite Function for creating/updating the signed-in user's `users` row, seeding their onboarding skill row,
and auto-provisioning their wallet.

The Flutter app must not update `users` directly because the row also stores protected fields such as `roles`,
`membership_level_id`, and `job_title_verified`. The app also must not create or update wallet balances directly. This
function uses an API key, derives the caller from Appwrite's authenticated execution headers, allowlists only editable
profile fields, and idempotently creates `skills/{userId}` and `wallet/{userId}` when missing.

The optional `skill_level` request field may be `beginner`, `intermediate`, or `competitive`. It seeds the initial
`skills.level` only when the user has no skills row yet, so later trusted host/admin skill updates are preserved. New
wallets start with `10` free credits, `0` paid credits, and an expiry at the end of the current UTC month. Existing
wallets are left unchanged.

## Username

Users may change their `username` through this function. A `username` is auto-generated at signup by the
`user-provision` function; here it is editable. Usernames are **unique**, enforced by both a unique DB index
(`username_unique`) and server-side validation:

- Format: lowercase, allowed characters `[a-z0-9_]`, length 3–30, must start with a letter.
- Normalization: lowercase, trim, replace any run of invalid characters with `_`, collapse repeated `_`, strip
  leading/trailing `_`, prefix `u` if it does not start with a letter, clamp to 30 characters.
- Reserved names (`admin`, `root`, `support`, `pikacircle`, `system`, `me`, `null`, `undefined`) are rejected.
- On update, the normalized handle is validated (`400` on invalid/reserved) and checked for uniqueness excluding the
  caller's own row (`409` when taken).

### `check_username` action

To check availability without saving, POST:

```json
{ "action": "check_username", "username": "<candidate>" }
```

This short-circuits the normal editable-field flow (it still requires an authenticated caller) and returns `200` with:

```json
{ "available": true, "normalized": "<normalized>" }
```

or, when unavailable:

```json
{ "available": false, "normalized": "<normalized>", "reason": "taken|invalid|reserved" }
```

Checking your own current handle reports `available: true` (the caller's own row is excluded from the taken check).

Required function variables:

- `APPWRITE_API_KEY` with TablesDB row read/create/update permissions for the `main` database.
- `APPWRITE_DATABASE_ID=main`

Appwrite provides `APPWRITE_FUNCTION_API_ENDPOINT` and `APPWRITE_FUNCTION_PROJECT_ID` at runtime.
