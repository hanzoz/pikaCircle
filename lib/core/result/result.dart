import 'package:appwrite/appwrite.dart';
import 'package:fpdart/fpdart.dart';

import 'package:pikacircle/core/error/exceptions.dart';
import 'package:pikacircle/core/error/failure.dart';

// Re-export fpdart so a single `import '.../core/result/result.dart'` provides
// Result, Right, Left, Unit, unit, Option, etc. without every repository also
// importing fpdart directly.
export 'package:fpdart/fpdart.dart';

/// The standard return type for repository operations.
///
/// `Left` carries a [Failure], `Right` carries the success value. Presentation
/// code folds over this instead of using try/catch.
typedef Result<T> = Either<Failure, T>;

/// Maps an [AppwriteException] to a user-safe [Failure].
Failure mapAppwriteException(AppwriteException e) {
  final code = e.code;
  if (code == 401) {
    return UnauthorizedFailure(e.message ?? 'Please sign in to continue.');
  }
  if (code != null && code >= 500) {
    return const ServerFailure();
  }
  if (code != null && code >= 400) {
    return RequestFailure(e.message ?? 'Request failed.', code: code);
  }
  return ServerFailure(e.message ?? 'Something went wrong. Please try again.');
}

/// Maps a data-layer [AppException] to a [Failure].
Failure mapAppException(AppException e) {
  return switch (e) {
    UnauthorizedException() => UnauthorizedFailure(e.message),
    NetworkException() => NetworkFailure(e.message),
    NotFoundException() => RequestFailure(e.message, code: e.code),
    _ => ServerFailure(e.message),
  };
}

/// Converts any caught error into a [Failure]. Use in repository `catch` blocks
/// as the single translation point between the data and domain layers.
Failure mapError(Object error) {
  return switch (error) {
    Failure f => f,
    AppwriteException e => mapAppwriteException(e),
    AppException e => mapAppException(e),
    _ => const ServerFailure(),
  };
}
