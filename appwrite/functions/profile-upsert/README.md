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

Required function variables:

- `APPWRITE_API_KEY` with TablesDB row read/create/update permissions for the `main` database.
- `APPWRITE_DATABASE_ID=main`

Appwrite provides `APPWRITE_FUNCTION_API_ENDPOINT` and `APPWRITE_FUNCTION_PROJECT_ID` at runtime.
