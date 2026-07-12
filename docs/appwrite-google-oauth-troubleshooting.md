# Appwrite Google OAuth troubleshooting

## Symptom

Google shows:

> Access blocked: This app's request is invalid

## Verified root cause

Run:

```bash
python3 scripts/check_appwrite_oauth.py
```

If it prints a redirect URI like this, Appwrite/proxy is misconfigured:

```text
http://app.moonlabsentertainment.com:443/v1/account/sessions/oauth2/callback/google/6a0a88940013e0e16b8b
```

Google rejects that URL because it is `http://` on port `443`. The callback must be HTTPS.

If it prints `redirect_uri_mismatch`, Appwrite is generating the correct HTTPS callback but Google Cloud has not
allowlisted it yet.

## Server-side fix

Set these Appwrite environment variables on the Appwrite host, then restart Appwrite:

```env
_APP_OPTIONS_FORCE_HTTPS=enabled
_APP_DOMAIN=app.moonlabsentertainment.com
_APP_CONSOLE_DOMAIN=app.moonlabsentertainment.com
```

Also ensure Cloudflare / reverse proxy uses HTTPS to the Appwrite origin:

- Cloudflare SSL/TLS mode: `Full` or `Full (strict)`, not `Flexible`.
- Nginx/Caddy/Traefik should proxy to Appwrite's HTTPS origin, not plain HTTP.

## Google Cloud setting

After the Appwrite redirect becomes HTTPS, add this Authorized Redirect URI in Google Cloud Console:

```text
https://app.moonlabsentertainment.com/v1/account/sessions/oauth2/callback/google/6a0a88940013e0e16b8b
```

The current Google OAuth client ID seen from Appwrite is:

```text
3340011727-2a7nttavhji7inaada0en2sk0fms58q6.apps.googleusercontent.com
```

Make sure you add the redirect URI to that exact OAuth client.

Re-run the diagnostic script. It should print:

```text
Google OAuth redirect URI looks valid.
```
