# user-provision

Event-triggered Appwrite Function that auto-provisions a new user at registration time. It listens to the
`users.*.create` event, so it fires for **both** email/password and Google OAuth signups.

The function derives the new user from the event payload (the created user object delivered as JSON), then performs
three idempotent steps:

1. **Auth label** — ensures the `user` label is present on the auth account (preserving any existing labels).
2. **`users` row** — creates `users/{userId}` when missing, with `roles=['user']`, `membership_level_id=bronze`, and
   `job_title_verified=false`. Existing rows are left unchanged.
3. **`wallet` row** — provisions `wallet/{userId}` when missing with `10` free credits, `0` paid credits, and an
   expiry at the end of the current UTC month. Existing wallets are left unchanged.

Because it is fully idempotent, re-delivery of the event will not duplicate or overwrite anything.

Required function variables:

- `APPWRITE_API_KEY` with TablesDB row read/create permissions for the `main` database, plus Users read/write scope
  (needed for `updateLabels`).
- `APPWRITE_DATABASE_ID=main`

Appwrite provides `APPWRITE_FUNCTION_API_ENDPOINT` and `APPWRITE_FUNCTION_PROJECT_ID` at runtime.
