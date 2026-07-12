import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/core/error/failure.dart';
import 'package:pikacircle/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pikacircle/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:pikacircle/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:pikacircle/features/profile/domain/entities/account_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/app_workflow.dart';
import 'package:pikacircle/features/profile/domain/repositories/profile_repository.dart';

/// Wires the Appwrite services into the profile remote data source.
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSource(
    ref.watch(appwriteTablesDbProvider),
    ref.watch(appwriteFunctionsProvider),
    ref.watch(appwriteConfigProvider),
  ),
);

/// The default [ProfileRepository] implementation.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider)),
);

/// Loads and mutates the signed-in user's [AccountProfile].
///
/// The state is `null` when there is no authenticated user. Load failures
/// surface as an [AsyncError] carrying the [Failure]; mutation failures are
/// returned to the caller (see [updateProfile]) so forms can show inline
/// errors without tearing down the loaded profile.
class ProfileController extends AsyncNotifier<AccountProfile?> {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  Future<AccountProfile?> build() async {
    // Use read() to avoid circular dependency with AuthController.
    // Profile loads explicitly via updateProfile() or reload(), not reactively.
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;

    final result = await _repo.loadProfile(userId);
    return result.fold(
      // Throwing surfaces the failure as AsyncError to the UI.
      (failure) => throw failure,
      (profile) => profile,
    );
  }

  /// Re-fetches the profile from scratch, moving state through loading.
  Future<void> reload() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      state = const AsyncData(null);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.loadProfile(userId);
      return result.fold((failure) => throw failure, (profile) => profile);
    });
  }

  /// Upserts the caller's editable profile fields, then reloads the profile.
  ///
  /// Returns `null` on success. On failure, restores the previously loaded
  /// data and returns the [Failure] so the caller can present it. Returns an
  /// [UnauthorizedFailure] when there is no signed-in user.
  Future<Failure?> updateProfile({
    required Map<String, Object?> editableFields,
    String? skillLevel,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return const UnauthorizedFailure();
    }

    final previous = state;
    // Assigning AsyncLoading on an AsyncNotifier automatically preserves the
    // previous value/error (the framework applies copyWithPrevious for us),
    // so forms can keep showing data while the write is in flight.
    state = const AsyncLoading<AccountProfile?>();

    final result = await _repo.upsertProfile(
      userId: userId,
      editableFields: editableFields,
      skillLevel: skillLevel,
    );

    return result.fold(
      (failure) {
        // Roll back to whatever we were showing before the attempt.
        state = previous;
        return failure;
      },
      (_) async {
        await reload();
        return null;
      },
    );
  }
}

/// The app-wide profile controller.
final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, AccountProfile?>(
      ProfileController.new,
    );

/// The current app workflow (player/host) derived from the loaded profile.
///
/// Defaults to [AppWorkflow.player] while loading, on error, or when signed
/// out. The shell watches this to decide host-only tab visibility.
final currentWorkflowProvider = Provider<AppWorkflow>(
  (ref) =>
      ref.watch(profileControllerProvider).value?.workflow ??
      AppWorkflow.player,
);
