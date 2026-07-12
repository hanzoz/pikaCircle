import 'package:pikacircle/features/auth/domain/entities/auth_user.dart';

/// Coarse authentication lifecycle used to drive routing.
///
/// [unknown] is the initial state while the current session is still being
/// resolved; routing should hold (splash) rather than redirect during it.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Immutable snapshot of the app's authentication state.
///
/// Pairs an [AuthStatus] with the resolved [AuthUser] (present only when
/// [status] is [AuthStatus.authenticated]).
class AuthState {
  const AuthState({required this.status, this.user});

  /// The initial, still-resolving state.
  const AuthState.unknown() : this(status: AuthStatus.unknown);

  /// No active session.
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  /// An active session for [user].
  const AuthState.authenticated(AuthUser user)
    : this(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final AuthUser? user;

  /// Convenience accessor for the signed-in user's id, or `null`.
  String? get userId => user?.id;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState && other.status == status && other.user == user;
  }

  @override
  int get hashCode => Object.hash(status, user);

  @override
  String toString() => 'AuthState(status: $status, user: $user)';
}
