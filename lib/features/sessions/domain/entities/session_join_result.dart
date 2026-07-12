/// Result of a `session-join` trusted-function call.
///
/// Mirrors the JSON returned by the `session-join` Appwrite Function:
/// `status` is `confirmed` or `waitlisted`, plus a `message`, an `existing`
/// flag, and an optional `participantId`.
enum JoinStatus { confirmed, waitlisted, unknown }

class SessionJoinResult {
  const SessionJoinResult({
    required this.status,
    required this.message,
    required this.alreadyJoined,
    this.participantId,
  });

  final JoinStatus status;
  final String message;

  /// True when the caller already had a participant row for this session.
  final bool alreadyJoined;

  final String? participantId;

  static JoinStatus statusFromWire(String? value) {
    return switch (value) {
      'confirmed' => JoinStatus.confirmed,
      'waitlisted' => JoinStatus.waitlisted,
      _ => JoinStatus.unknown,
    };
  }
}
