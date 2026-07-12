# session-join

Trusted Appwrite Function for joining PikaCircle sessions.

The Flutter app must not create `session_participants`, charge credits, update wallet balances, or increment access-code
usage directly. This function derives the caller from Appwrite's authenticated execution headers, validates the session
and optional access code, and creates the roster row server-side.

Join outcomes:

- Valid `qr_join` scans create `confirmed` when capacity is available.
- Valid `qr_join` scans create `waitlisted` when confirmed capacity is full.
- Non-QR joins follow the same outcome rule: eligible players are confirmed when capacity is available and waitlisted
  when full.
- The join flow does not create host approval or on-hold roster rows.

Required function variables:

- `APPWRITE_API_KEY` with TablesDB row read/create/update permissions for the `main` database.
- `APPWRITE_DATABASE_ID=main`

Appwrite provides `APPWRITE_FUNCTION_API_ENDPOINT` and `APPWRITE_FUNCTION_PROJECT_ID` at runtime.
