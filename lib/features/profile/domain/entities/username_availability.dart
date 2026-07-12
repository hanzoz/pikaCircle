/// Result of a username-availability check against the profile-upsert function.
///
/// Immutable value object with a const constructor and value equality.
/// Domain-only: no Flutter or Appwrite imports.
class UsernameAvailability {
  const UsernameAvailability({
    required this.available,
    required this.normalized,
    this.reason,
  });

  /// Whether [normalized] is free to claim.
  final bool available;

  /// The server-normalized form of the requested username.
  final String normalized;

  /// A human-readable reason when the username is unavailable, else `null`.
  final String? reason;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsernameAvailability &&
        other.available == available &&
        other.normalized == normalized &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(available, normalized, reason);

  @override
  String toString() =>
      'UsernameAvailability(available: $available, '
      'normalized: $normalized, reason: $reason)';
}
