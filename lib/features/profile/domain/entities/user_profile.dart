import 'package:pikacircle/features/profile/domain/entities/app_workflow.dart';
import 'package:pikacircle/features/profile/domain/entities/user_role.dart';

/// A signed-in user's profile, mirroring the editable + derived fields of the
/// `users` row (see `docs/database.md`).
///
/// Immutable value object with a const constructor and value equality.
/// Domain-only: no Flutter or Appwrite imports.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.jobTitle,
    this.jobTitleVerified = false,
    this.linkedinProfileUrl,
    this.profilePictureFileId,
    this.membershipLevelId,
    this.roles = const [UserRole.user],
  });

  /// The Appwrite user/row id (`row.$id`).
  final String id;
  final String name;
  final String email;
  final String? dateOfBirth;
  final String? gender;
  final String? bio;
  final String? jobTitle;
  final bool jobTitleVerified;
  final String? linkedinProfileUrl;
  final String? profilePictureFileId;
  final String? membershipLevelId;
  final List<UserRole> roles;

  /// Whether the user holds the `host` role.
  bool get isHost => roles.contains(UserRole.host);

  /// The app shell this user should see. `host` when [isHost], else `player`.
  AppWorkflow get workflow => isHost ? AppWorkflow.host : AppWorkflow.player;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.dateOfBirth == dateOfBirth &&
        other.gender == gender &&
        other.bio == bio &&
        other.jobTitle == jobTitle &&
        other.jobTitleVerified == jobTitleVerified &&
        other.linkedinProfileUrl == linkedinProfileUrl &&
        other.profilePictureFileId == profilePictureFileId &&
        other.membershipLevelId == membershipLevelId &&
        _listEquals(other.roles, roles);
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    dateOfBirth,
    gender,
    bio,
    jobTitle,
    jobTitleVerified,
    linkedinProfileUrl,
    profilePictureFileId,
    membershipLevelId,
    Object.hashAll(roles),
  );

  @override
  String toString() =>
      'UserProfile(id: $id, name: $name, email: $email, roles: $roles)';
}

/// Order-sensitive list equality used for value comparison of [UserRole] lists.
bool _listEquals(List<UserRole> a, List<UserRole> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
