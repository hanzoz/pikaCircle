import 'package:pikacircle/features/profile/domain/entities/account_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/user_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/user_role.dart';
import 'package:pikacircle/features/profile/domain/entities/wallet.dart';

/// Plain-JSON (de)serialization for caching an [AccountProfile] locally.
///
/// Data-layer only. This is the single place that knows the cache JSON shape;
/// it keeps Hive/JSON concerns out of the domain entities. Parsing is
/// defensive (mirroring `UserProfileModel`/`WalletModel`) so a corrupt or
/// out-of-date cache is simply ignored rather than crashing the app.
abstract final class AccountProfileCache {
  /// The current cache schema version. Bump when the shape changes so older
  /// entries are rejected by [fromJson].
  static const int _version = 3;

  /// Serializes [p] into a plain JSON-encodable map.
  static Map<String, dynamic> toJson(AccountProfile p) {
    final user = p.user;
    final wallet = p.wallet;
    return {
      '_v': _version,
      'user': {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'username': user.username,
        'date_of_birth': user.dateOfBirth,
        'gender': user.gender,
        'bio': user.bio,
        'job_title': user.jobTitle,
        'job_title_verified': user.jobTitleVerified,
        'linkedin_profile_url': user.linkedinProfileUrl,
        'profile_picture_file_id': user.profilePictureFileId,
        'profile_picture_url': user.profilePictureUrl,
        'membership_level_id': user.membershipLevelId,
        'membership_level_name': user.membershipLevelName,
        'roles': [for (final role in user.roles) role.wire],
      },
      'wallet': wallet == null
          ? null
          : {
              'id': wallet.id,
              'free_credits': wallet.freeCredits,
              'paid_credits': wallet.paidCredits,
              'free_credits_expiry_date': wallet.freeCreditsExpiryDate,
            },
    };
  }

  /// Rebuilds an [AccountProfile] from [json], or returns `null` when the map
  /// is malformed or its schema version is unknown.
  static AccountProfile? fromJson(Map<String, dynamic> json) {
    if (json['_v'] != _version) return null;

    final userJson = json['user'];
    if (userJson is! Map) return null;

    final id = _string(userJson['id']);
    if (id == null) return null;

    final user = UserProfile(
      id: id,
      name: _string(userJson['name']) ?? '',
      email: _string(userJson['email']) ?? '',
      username: _string(userJson['username']),
      dateOfBirth: _string(userJson['date_of_birth']),
      gender: _string(userJson['gender']),
      bio: _string(userJson['bio']),
      jobTitle: _string(userJson['job_title']),
      jobTitleVerified: _bool(userJson['job_title_verified']),
      linkedinProfileUrl: _string(userJson['linkedin_profile_url']),
      profilePictureFileId: _string(userJson['profile_picture_file_id']),
      profilePictureUrl: _string(userJson['profile_picture_url']),
      membershipLevelId: _string(userJson['membership_level_id']),
      membershipLevelName: _string(userJson['membership_level_name']),
      roles: _roles(userJson['roles']),
    );

    final wallet = _wallet(json['wallet']);

    return AccountProfile(user: user, wallet: wallet);
  }

  /// Rebuilds a nullable [Wallet] from its cached map form.
  static Wallet? _wallet(Object? value) {
    if (value is! Map) return null;
    final id = _string(value['id']);
    if (id == null) return null;
    return Wallet(
      id: id,
      freeCredits: _num(value['free_credits']),
      paidCredits: _num(value['paid_credits']),
      freeCreditsExpiryDate: _string(value['free_credits_expiry_date']),
    );
  }

  /// Coerces a dynamic value to a non-empty [String], or `null`.
  static String? _string(Object? value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  /// Coerces a dynamic value into a [num], defaulting to `0`.
  static num _num(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim()) ?? 0;
    return 0;
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

  /// Parses the cached `roles` list into a `List<UserRole>`, skipping unknown
  /// values and defaulting to `[UserRole.user]` when empty or absent.
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
