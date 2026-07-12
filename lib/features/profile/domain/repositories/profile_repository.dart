import 'package:pikacircle/core/result/result.dart';
import 'package:pikacircle/features/profile/domain/entities/account_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/user_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/username_availability.dart';

/// Contract for reading and updating the signed-in user's profile.
///
/// Implementations translate data-layer errors into [Failure]s and return them
/// inside a [Result]; presentation folds over the result instead of catching.
abstract class ProfileRepository {
  /// Loads the [AccountProfile] (user + wallet) for [userId].
  Future<Result<AccountProfile>> loadProfile(String userId);

  /// Upserts the caller's editable profile fields via the profile-upsert
  /// function, then returns the refreshed [UserProfile].
  ///
  /// [editableFields] keys must be the wire snake_case names the function
  /// accepts (e.g. `name`, `date_of_birth`, `job_title`, `gender`,
  /// `linkedin_profile_url`, `profile_picture_file_id`). `username` is also an
  /// accepted editable wire key. [skillLevel], when provided, is sent as
  /// `skill_level` (beginner|intermediate|competitive).
  Future<Result<UserProfile>> upsertProfile({
    required String userId,
    required Map<String, Object?> editableFields,
    String? skillLevel,
  });

  /// Uploads avatar bytes to storage and saves avatar metadata on the user's
  /// profile row, then returns the refreshed [UserProfile].
  Future<Result<UserProfile>> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String fileName,
  });

  /// Checks whether [username] is available via the profile-upsert function,
  /// returning the normalized form and (when unavailable) a reason.
  Future<Result<UsernameAvailability>> checkUsername(String username);
}
