/// An authenticated user as understood by the domain layer.
///
/// This is a pure, framework-agnostic value object. It carries only the
/// identity fields the app needs and intentionally knows nothing about
/// Appwrite's `User` model or any transport concerns.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerified,
  });

  /// The stable unique identifier for the user (Appwrite `$id`).
  final String id;

  /// The user's display name.
  final String name;

  /// The user's email address.
  final String email;

  /// Whether the user has verified their email address.
  final bool emailVerified;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthUser &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.emailVerified == emailVerified;
  }

  @override
  int get hashCode => Object.hash(id, name, email, emailVerified);

  @override
  String toString() =>
      'AuthUser(id: $id, name: $name, email: $email, '
      'emailVerified: $emailVerified)';
}
