import 'package:appwrite/models.dart' as models;

import 'package:pikacircle/features/profile/domain/entities/user_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/user_role.dart';

/// Maps an Appwrite `users` [models.Row] into a domain [UserProfile].
///
/// Data-layer only. Parsing is defensive: unknown roles are skipped, an
/// empty/absent `roles` list falls back to `[UserRole.user]`, and
/// `job_title_verified` is coerced from bool/String/num shapes.
abstract final class UserProfileModel {
  static UserProfile fromRow(models.Row row) {
    final data = row.data;
    return UserProfile(
      id: row.$id,
      name: _string(data['name']) ?? '',
      email: _string(data['email']) ?? '',
      username: _string(data['username']),
      dateOfBirth: _string(data['date_of_birth']),
      gender: _string(data['gender']),
      bio: _string(data['bio']),
      jobTitle: _string(data['job_title']),
      jobTitleVerified: _bool(data['job_title_verified']),
      linkedinProfileUrl: _string(data['linkedin_profile_url']),
      profilePictureFileId: _string(data['profile_picture_file_id']),
      membershipLevelId: _membershipLevelId(data['membership_level_id']),
      membershipLevelName: _membershipLevelName(data['membership_level_id']),
      roles: _roles(data['roles']),
    );
  }

  /// Extracts the `$id` from a membership_levels relationship value.
  /// Returns the raw string when Appwrite returns a plain ID.
  static String? _membershipLevelId(Object? value) {
    if (value is Map) return _string(value[r'$id']);
    return _string(value);
  }

  /// Extracts the `name` field from a membership_levels relationship object.
  static String? _membershipLevelName(Object? value) {
    if (value is Map) return _string(value['name']);
    return null;
  }

  /// Coerces a dynamic value to a non-empty [String], or `null`.
  static String? _string(Object? value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  /// Defensively parses a bool that may arrive as bool, String, or num.
  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  /// Parses the `roles` field (typically `List<dynamic>` of strings) into a
  /// `List<UserRole>`, skipping unknown values and defaulting to
  /// `[UserRole.user]` when empty or absent.
  static List<UserRole> _roles(Object? value) {
    if (value is List) {
      final parsed = <UserRole>[];
      for (final item in value) {
        if (item == null) continue;
        final role = UserRole.fromString(item.toString());
        if (role != null && !parsed.contains(role)) {
          parsed.add(role);
        }
      }
      if (parsed.isNotEmpty) return parsed;
    }
    return const [UserRole.user];
  }
}
