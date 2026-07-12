import 'package:pikacircle/core/result/result.dart';
import 'package:pikacircle/features/auth/domain/entities/auth_user.dart';
import 'package:pikacircle/features/auth/domain/entities/oauth_provider.dart';

/// Contract for authentication operations.
///
/// Implemented in the data layer. All methods return a [Result] so callers
/// fold over success/failure instead of catching exceptions. This interface is
/// intentionally free of any Flutter or Appwrite types.
abstract interface class AuthRepository {
  /// Signs in with email + password, returning the resolved [AuthUser].
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registers a new account then signs in, returning the [AuthUser].
  Future<Result<AuthUser>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Ends the current session.
  Future<Result<Unit>> signOut();

  /// Resolves the currently signed-in user, or `null` when there is no
  /// active session.
  Future<Result<AuthUser?>> currentUser();

  /// Runs the full OAuth token flow for [provider] (opening a browser tab and
  /// handling the deep-link callback) and returns the resolved [AuthUser].
  Future<Result<AuthUser>> signInWithOAuth(OAuthProvider provider);

  /// Completes an OAuth login using the `userId`/`secret` returned to the
  /// success callback, returning the resolved [AuthUser].
  ///
  /// Used when the callback is captured out-of-band (e.g. an app deep-link
  /// handler) rather than through [signInWithOAuth].
  Future<Result<AuthUser>> completeOAuthSession({
    required String userId,
    required String secret,
  });

  /// Sends a password-recovery email to [email].
  Future<Result<Unit>> sendPasswordRecovery(String email);
}
