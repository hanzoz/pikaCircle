import 'package:pikacircle/core/result/result.dart';
import 'package:pikacircle/features/sessions/domain/entities/session_join_result.dart';

/// Session operations backed by trusted Appwrite Functions.
///
/// Only the join flow is wired for the MVP restructure; roster/host tools are
/// added later. All privileged logic (capacity, credits, skill, waitlist) lives
/// in the `session-join` function, not the client.
abstract class SessionRepository {
  /// Requests to join [sessionId], optionally presenting an [accessCode] for
  /// QR / private-invite sessions. The trusted function confirms the player
  /// when capacity exists or waitlists them when full.
  Future<Result<SessionJoinResult>> joinSession({
    required String sessionId,
    String? accessCode,
  });
}
