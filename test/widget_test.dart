import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:pikacircle/app/app.dart';
import 'package:pikacircle/core/result/result.dart';
import 'package:pikacircle/features/auth/domain/entities/auth_user.dart';
import 'package:pikacircle/features/auth/domain/entities/oauth_provider.dart';
import 'package:pikacircle/features/auth/domain/repositories/auth_repository.dart';
import 'package:pikacircle/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pikacircle/features/profile/data/profile_cache_providers.dart';
import 'package:pikacircle/features/profile/domain/entities/account_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/user_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/user_role.dart';
import 'package:pikacircle/features/profile/domain/entities/username_availability.dart';
import 'package:pikacircle/features/profile/domain/entities/wallet.dart';
import 'package:pikacircle/features/profile/domain/repositories/profile_repository.dart';
import 'package:pikacircle/features/profile/presentation/controllers/profile_controller.dart';

/// Auth repo that reports a signed-in user without touching Appwrite.
class _FakeAuthRepository implements AuthRepository {
  const _FakeAuthRepository(this._user);

  final AuthUser _user;

  @override
  Future<Result<AuthUser?>> currentUser() async => Right(_user);

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async => Right(_user);

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async => Right(_user);

  @override
  Future<Result<AuthUser>> completeOAuthSession({
    required String userId,
    required String secret,
  }) async => Right(_user);

  @override
  Future<Result<AuthUser>> signInWithOAuth(OAuthProvider provider) async =>
      Right(_user);

  @override
  Future<Result<Unit>> sendPasswordRecovery(String email) async =>
      const Right(unit);

  @override
  Future<Result<Unit>> signOut() async => const Right(unit);
}

/// Profile repo returning a fixed host profile.
class _FakeProfileRepository implements ProfileRepository {
  const _FakeProfileRepository(this._profile);

  final AccountProfile _profile;

  @override
  Future<Result<AccountProfile>> loadProfile(String userId) async =>
      Right(_profile);

  @override
  Future<Result<UserProfile>> upsertProfile({
    required String userId,
    required Map<String, Object?> editableFields,
    String? skillLevel,
  }) async => Right(_profile.user);

  @override
  Future<Result<UserProfile>> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) async => Right(_profile.user);

  @override
  Future<Result<UsernameAvailability>> checkUsername(String username) async =>
      Right(UsernameAvailability(available: true, normalized: username));
}

void main() {
  late Box<String> profileBox;

  setUpAll(() async {
    // Cache-first ProfileController reads a Hive box; back it with an
    // in-memory box for tests so the box provider override has a real target.
    Hive.init('./.dart_tool/hive_test');
    profileBox = await Hive.openBox<String>('profile_cache_test');
  });

  setUp(() async {
    await profileBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  const user = AuthUser(
    id: 'user-1',
    name: 'Alex',
    email: 'alex@example.com',
    emailVerified: true,
  );

  const profile = AccountProfile(
    user: UserProfile(
      id: 'user-1',
      name: 'Alex',
      email: 'alex@example.com',
      jobTitleVerified: false,
      roles: [UserRole.user, UserRole.host],
    ),
    wallet: Wallet(id: 'user-1', freeCredits: 10, paidCredits: 0),
  );

  Widget bootstrap() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          const _FakeAuthRepository(user),
        ),
        profileRepositoryProvider.overrideWithValue(
          const _FakeProfileRepository(profile),
        ),
        profileCacheBoxProvider.overrideWithValue(profileBox),
      ],
      child: const PikaCircleApp(),
    );
  }

  testWidgets('authenticated shell renders primary tabs', (tester) async {
    await tester.pumpWidget(bootstrap());
    await tester.pumpAndSettle();

    // Primary navigation destinations are present.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Wallet'), findsWidgets);

    // Host workflow relabels the third tab.
    expect(find.text('Sessions'), findsWidgets);
  });
}
