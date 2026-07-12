/// A role a user can hold in the app.
///
/// Mirrors the `roles` String-array field on the `users` row (values among
/// `user`, `host`, `admin`; the legacy value `normal_user` maps to [user]).
/// Domain-only: no Flutter or Appwrite imports.
enum UserRole {
  user,
  host,
  admin;

  /// The canonical snake_case string persisted in Appwrite for this role.
  String get wire => switch (this) {
    UserRole.user => 'user',
    UserRole.host => 'host',
    UserRole.admin => 'admin',
  };

  /// Parses a wire string into a [UserRole] (case-insensitive).
  ///
  /// Maps the legacy value `normal_user` to [UserRole.user]. Returns `null`
  /// for any unrecognized value so callers can skip unknown roles.
  static UserRole? fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'user':
      case 'normal_user':
        return UserRole.user;
      case 'host':
        return UserRole.host;
      case 'admin':
        return UserRole.admin;
      default:
        return null;
    }
  }
}
