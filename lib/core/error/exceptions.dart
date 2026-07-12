/// Exceptions thrown by the data layer (data sources).
///
/// These are internal to data/ and never surfaced to presentation. Repositories
/// translate them into `Failure`s (see `result.dart`).
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final int? code;

  @override
  String toString() => 'AppException($code): $message';
}

/// Raised when a remote call fails at the transport level.
class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error']);
}

/// Raised when Appwrite returns an authentication error (401).
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized'])
    : super(code: 401);
}

/// Raised when a requested resource does not exist (404).
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found']) : super(code: 404);
}
