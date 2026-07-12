/// Base type for all domain-level failures.
///
/// Data sources throw [AppException]s; repositories catch them and convert
/// them into [Failure]s returned inside a [Result]. Presentation never sees
/// raw Appwrite exceptions.
sealed class Failure {
  const Failure(this.message);

  /// Human-readable, user-safe message.
  final String message;

  @override
  String toString() => '$runtimeType(message: $message)';
}

/// A network/transport problem (offline, TLS, timeout, DNS).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Please try again.']);
}

/// The caller is not authenticated or the session expired.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Please sign in to continue.']);
}

/// The request was rejected for validation/permission reasons (4xx).
class RequestFailure extends Failure {
  const RequestFailure(super.message, {this.code});

  final int? code;
}

/// A server-side error (5xx) or an unexpected/unknown failure.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong. Please try again.']);
}
