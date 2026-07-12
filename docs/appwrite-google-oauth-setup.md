# Google sign-in (Appwrite OAuth) — setup

This app signs in with Google using **Appwrite's OAuth2 token flow** opened in a
browser tab via `flutter_web_auth_2`, then exchanges the returned
`userId`/`secret` for a session. The **app code is complete**, but Google
sign-in will **fail at runtime until the server-side pieces below are
configured**. Email/password sign-up and sign-in work without any of this.

## The values for THIS project

| Thing | Value |
| --- | --- |
| Appwrite project id | `6a45bd5200114e7b1f52` |
| Appwrite endpoint | `https://app.moonlabsentertainment.com/v1` |
| Deep-link callback scheme | `appwrite-callback-6a45bd5200114e7b1f52` |
| Google authorized redirect URI | `https://app.moonlabsentertainment.com/v1/account/sessions/oauth2/callback/google/6a45bd5200114e7b1f52` |

> ⚠️ **Note:** `docs/appwrite-google-oauth-troubleshooting.md` currently lists
> project id `6a0a88940013e0e16b8b` — that is a **different project** (copied
> from another app) and is **not** correct for pikaCircle. Use
> `6a45bd5200114e7b1f52` (this project) everywhere for Google sign-in here.

## What the app already does (no action needed)

- `AppwriteConfig.oauthTokenUrl(...)` builds
  `…/v1/account/tokens/oauth2/google?project=…&success=…&failure=…&scopes[]=email&scopes[]=profile`.
- `AuthRemoteDataSource.signInWithOAuth(...)` opens it with `FlutterWebAuth2`,
  using callback scheme `appwrite-callback-6a45bd5200114e7b1f52`, parses
  `userId`/`secret`, and calls `Account.createSession`.
- Native deep-link handlers are registered:
  - Android: `com.linusu.flutter_web_auth_2.CallbackActivity` in
    `android/app/src/main/AndroidManifest.xml`.
  - iOS: `CFBundleURLSchemes` in `ios/Runner/Info.plist`.
- After first sign-up / Google sign-in, the chosen skill level is written to the
  user's profile via the `profile-upsert` function.

## What YOU must configure (server side) — required for Google to work

### 1. Enable the Google provider in Appwrite

Appwrite Console → your project (`6a45bd5200114e7b1f52`) → **Auth → Settings →
OAuth2 Providers → Google** → toggle **Enabled**, and paste the **Google OAuth
Client ID** and **Client secret** (from step 2).

### 2. Create / configure the Google OAuth client

Google Cloud Console → **APIs & Services → Credentials → OAuth client ID** (type:
Web application). Under **Authorized redirect URIs**, add **exactly**:

```text
https://app.moonlabsentertainment.com/v1/account/sessions/oauth2/callback/google/6a45bd5200114e7b1f52
```

Copy the client's **Client ID** and **Client secret** back into Appwrite
(step 1).

### 3. Appwrite must generate HTTPS callbacks

The redirect URI above must be **https** (not `http` on port 443). On the
Appwrite host, ensure:

```env
_APP_OPTIONS_FORCE_HTTPS=enabled
_APP_DOMAIN=app.moonlabsentertainment.com
_APP_CONSOLE_DOMAIN=app.moonlabsentertainment.com
```

and that Cloudflare / the reverse proxy talks to Appwrite over HTTPS
(Cloudflare SSL/TLS mode `Full` or `Full (strict)`, not `Flexible`). See
`docs/appwrite-google-oauth-troubleshooting.md` for the failure symptoms if this
is wrong (Google shows *"Access blocked: This app's request is invalid"* or
`redirect_uri_mismatch`).

### 4. Add the native platforms in Appwrite (recommended)

Appwrite Console → project → **Overview → Add platform**:
- **Flutter (Android)** with the app's package name (`applicationId`).
- **Flutter (iOS)** with the app's bundle id.

This allowlists the app so Appwrite accepts its requests.

## How to verify

1. `flutter run` on a real device/emulator.
2. Onboarding → **Continue with Google** → a browser tab opens Google consent →
   after approving, the tab closes and the app lands in the authenticated shell.
3. If it fails, the error surfaced in the app (and
   `docs/appwrite-google-oauth-troubleshooting.md`) points at which of steps 1–3
   is misconfigured.

## Password recovery note

`sendPasswordRecovery` calls `Account.createRecovery` with a `url` of
`https://app.moonlabsentertainment.com/v1/auth/recovery`. For the reset link to
work, that URL must be reachable and listed as an allowed platform URL in the
Appwrite console (or swap it for a real recovery landing page you host).
