import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/core/error/failure.dart';
import 'package:pikacircle/core/result/result.dart';
import 'package:pikacircle/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pikacircle/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:pikacircle/features/auth/domain/entities/auth_state.dart';
import 'package:pikacircle/features/auth/domain/entities/auth_user.dart';
import 'package:pikacircle/features/auth/domain/entities/oauth_provider.dart';
import 'package:pikacircle/features/auth/domain/repositories/auth_repository.dart';
import 'package:pikacircle/features/profile/data/profile_cache_providers.dart';
import 'package:pikacircle/features/profile/presentation/controllers/profile_controller.dart';

/// Appwrite-backed auth data source, wired from core Appwrite providers.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(
    ref.watch(appwriteAccountProvider),
    ref.watch(appwriteConfigProvider),
  ),
);

/// The auth repository the presentation layer depends on.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);

/// Drives the app's authentication state.
///
/// [build] resolves the current session once; the action methods perform
/// sign-in/up/out and OAuth, updating [state] and returning a [Failure] (or
/// `null` on success) so the UI can surface messages without dealing with
/// `AsyncError` directly.
class AuthController extends AsyncNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    final result = await _repo.currentUser();
    return result.match(
      (_) => const AuthState.unauthenticated(),
      (user) => user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user),
    );
  }

  /// Signs in with email + password. Returns a [Failure] on error, else `null`.
  Future<Failure?> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _run(
      () => _repo.signInWithEmail(email: email, password: password),
    );
  }

  /// Registers, signs in, then seeds the profile's skill level. Returns a
  /// [Failure] on error, else `null`.
  Future<Failure?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? skillLevel,
  }) {
    return _run(
      () => _repo.signUpWithEmail(name: name, email: email, password: password),
      skillLevel: skillLevel,
    );
  }

  /// Runs the Google OAuth flow (browser round trip), then seeds the profile's
  /// skill level. Returns a [Failure] on error, else `null`.
  Future<Failure?> signInWithGoogle({String? skillLevel}) {
    return _run(
      () => _repo.signInWithOAuth(OAuthProvider.google),
      skillLevel: skillLevel,
    );
  }

  /// Completes an OAuth login from a callback `userId`/`secret`. Returns a
  /// [Failure] on error, else `null`.
  Future<Failure?> signInWithOAuthCallback({
    required String userId,
    required String secret,
  }) {
    return _run(
      () => _repo.completeOAuthSession(userId: userId, secret: secret),
    );
  }

  /// Sends a password-recovery email. Returns a [Failure] on error, else
  /// `null`. Does not change auth state.
  Future<Failure?> sendPasswordRecovery(String email) async {
    final result = await _repo.sendPasswordRecovery(email);
    return result.match((failure) => failure, (_) => null);
  }

  /// Ends the current session. Returns a [Failure] on error, else `null`.
  Future<Failure?> signOut() async {
    state = const AsyncLoading<AuthState>();
    final result = await _repo.signOut();
    // Wipe local profile state regardless of network sign-out success, so no
    // stale data lingers on-device (mirrors presenting the user as signed out
    // even when the remote sign-out call fails).
    await ref.read(profileLocalDataSourceProvider).clear();
    ref.invalidate(profileControllerProvider);
    return result.match(
      (failure) {
        // Even if sign-out reporting failed, present the user as signed out.
        state = const AsyncData(AuthState.unauthenticated());
        return failure;
      },
      (_) {
        state = const AsyncData(AuthState.unauthenticated());
        return null;
      },
    );
  }

  /// Shared runner for the "sign in and become authenticated" flows.
  ///
  /// When [skillLevel] is provided, seeds the caller's profile row via the
  /// `profile-upsert` function after the session is established (registration
  /// and first-time Google sign-in). A failed seed does not fail the sign-in —
  /// the user is authenticated and can complete their profile later.
  Future<Failure?> _run(
    Future<Result<AuthUser>> Function() action, {
    String? skillLevel,
  }) async {
    state = const AsyncLoading<AuthState>();
    final result = await action();
    return await result.match(
      (failure) async {
        state = const AsyncData(AuthState.unauthenticated());
        return failure;
      },
      (user) async {
        // Authenticate first so currentUserIdProvider exposes the new user id.
        // ProfileController watches that id and loads the profile reactively,
        // so no explicit profile reload is needed here.
        state = AsyncData(AuthState.authenticated(user));
        if (skillLevel != null && skillLevel.isNotEmpty) {
          // Best-effort profile seed; ignore failure so auth still succeeds.
          await ref
              .read(profileControllerProvider.notifier)
              .updateProfile(editableFields: const {}, skillLevel: skillLevel);
        }
        return null;
      },
    );
  }
}

/// The app-wide authentication controller.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

/// Convenience accessor for the signed-in user's id, or `null`.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider).value?.userId,
);
