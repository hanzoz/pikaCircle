import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import 'package:pikacircle/core/config/appwrite_config.dart';
import 'package:pikacircle/features/auth/domain/entities/oauth_provider.dart';

/// Thin wrapper over the Appwrite [Account] service.
///
/// Returns raw Appwrite models and lets [AppwriteException]s propagate; the
/// repository maps them to `Failure`s.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._account, this._config);

  final Account _account;
  final AppwriteConfig _config;

  /// Creates an email/password session, then returns the current user.
  Future<models.User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _account.createEmailPasswordSession(email: email, password: password);
    return _account.get();
  }

  /// Registers a new account and signs in as that user.
  ///
  /// Refuses to open a second session while one is already active (Appwrite
  /// rejects that), so any current session is cleared first.
  Future<models.User> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await _account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );
    // Best-effort: clear any existing session before signing in as the new user.
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException {
      // No active session to clear; safe to continue.
    }
    await _account.createEmailPasswordSession(email: email, password: password);
    return _account.get();
  }

  /// Ends the current session.
  Future<void> signOut() {
    return _account.deleteSession(sessionId: 'current');
  }

  /// Returns the current user, or `null` when there is no active session
  /// (Appwrite responds 401 for the unauthenticated case).
  Future<models.User?> currentUser() async {
    try {
      return await _account.get();
    } on AppwriteException catch (e) {
      if (e.code == 401) return null;
      rethrow;
    }
  }

  /// Runs the full OAuth token flow for [provider] and returns the signed-in
  /// user.
  ///
  /// Steps:
  /// 1. Clear any existing session (Appwrite rejects creating a second one).
  /// 2. Build the Appwrite OAuth2 token URL and open it in a browser tab via
  ///    [FlutterWebAuth2], which returns to the app's registered deep-link
  ///    scheme (`appwrite-callback-<projectId>://...`) once the user consents.
  /// 3. Parse `userId` + `secret` from the callback and exchange them for a
  ///    session with `Account.createSession`.
  ///
  /// Throws [AppwriteException] if Appwrite rejects any step, or a
  /// `PlatformException`/[FormatException] if the browser round trip is
  /// cancelled or returns an unexpected callback.
  Future<models.User> signInWithOAuth(OAuthProvider provider) async {
    // Clear any stale session so createSession below can establish a fresh one.
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException {
      // No active session to clear; safe to continue.
    }

    final providerValue = _mapProvider(provider).value;
    final oauthUrl = _config.oauthTokenUrl(provider: providerValue);

    final result = await FlutterWebAuth2.authenticate(
      url: oauthUrl.toString(),
      callbackUrlScheme: _config.oauthCallbackScheme,
      options: const FlutterWebAuth2Options(
        // Web finishes the flow on the hosting page; native uses the scheme.
        preferEphemeral: true,
      ),
    );

    final callback = Uri.parse(result);
    final userId = callback.queryParameters['userId'];
    final secret = callback.queryParameters['secret'];

    if (userId == null || secret == null) {
      final error = callback.queryParameters['error'];
      throw AppwriteException(
        error == null || error.trim().isEmpty
            ? 'Google sign-in did not return a session token.'
            : 'Google sign-in failed: ${error.trim()}',
        400,
      );
    }

    await _account.createSession(userId: userId, secret: secret);
    return _account.get();
  }

  /// Whether OAuth via [signInWithOAuth] is supported on this platform.
  ///
  /// `flutter_web_auth_2` needs a native deep-link scheme; guard callers so the
  /// flow is only offered where it can complete.
  bool get supportsOAuth => !kIsWeb;

  /// Completes an OAuth login from an externally captured `userId`/`secret`.
  ///
  /// Retained for callers that receive the callback out-of-band (e.g. an app
  /// deep-link handler) rather than through [signInWithOAuth].
  Future<models.User> completeOAuthSession({
    required String userId,
    required String secret,
  }) async {
    await _account.createSession(userId: userId, secret: secret);
    return _account.get();
  }

  /// Sends a password-recovery email. The [url] is where the user lands to
  /// complete the reset; it must be an allowed platform URL in the Appwrite
  /// console.
  Future<void> sendPasswordRecovery(String email) {
    return _account.createRecovery(
      email: email,
      url: '${_config.endpoint}/auth/recovery',
    );
  }

  enums.OAuthProvider _mapProvider(OAuthProvider provider) {
    return switch (provider) {
      OAuthProvider.google => enums.OAuthProvider.google,
      OAuthProvider.apple => enums.OAuthProvider.apple,
      OAuthProvider.facebook => enums.OAuthProvider.facebook,
    };
  }
}
