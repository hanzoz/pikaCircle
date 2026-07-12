# Appwrite TLS CERTIFICATE_VERIFY_FAILED - problem and current workaround

Status: Temporary development workaround is in place.

This document replaces older instructions that referenced
lib/core/network/corporate_ca.dart and bundled CA files. That approach is no
longer used in this project.

## Problem summary

Appwrite calls from Flutter can fail with:

HandshakeException: Handshake error in client
OS Error: CERTIFICATE_VERIFY_FAILED

Browsers on developer machines may still work, which makes this issue confusing.

## Why this happens

The endpoint certificate chain is not trusted by the runtime trust store used
by Flutter/Dart on target devices.

Result: browser access may work on some developer machines, while Flutter API
calls fail with CERTIFICATE_VERIFY_FAILED on emulator/device.

## What is the wrong fix

Do not use Client.setSelfSigned(true) as a production solution.

That setting disables certificate verification and must not ship to production.

## Temporary workaround currently used

The current Appwrite client provider enables:

- Client.setSelfSigned(status: true)

Location:

- lib/core/appwrite/appwrite_providers.dart

Important:

- This is development/staging only.
- It disables strict certificate validation and must not be used for
   production releases.

## Long-term real fix

Serve a publicly trusted certificate on the Appwrite endpoint, for example via
the edge proxy in front of Appwrite.

After that, remove all TLS bypass behavior from the app client setup.

## Production cleanup checklist

When public TLS is ready, do all of the following:

1. In lib/core/appwrite/appwrite_providers.dart, remove
   .setSelfSigned(status: true) from Client setup.
2. Keep endpoint and project configuration unchanged.
3. Verify login and normal Appwrite API calls on physical device/emulator with
   no TLS handshake error.
4. Build a release variant and re-verify authentication/API flows.

## Quick validation command for chain inspection

echo | openssl s_client -connect app.moonlabsentertainment.com:443 \
  -servername app.moonlabsentertainment.com -showcerts 2>/dev/null \
  | grep -E "s:|i:"
