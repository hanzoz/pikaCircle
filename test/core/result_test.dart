import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pikacircle/core/error/exceptions.dart';
import 'package:pikacircle/core/error/failure.dart';
import 'package:pikacircle/core/result/result.dart';

void main() {
  group('mapAppwriteException', () {
    test('maps 401 to UnauthorizedFailure', () {
      final failure = mapAppwriteException(
        AppwriteException('nope', 401),
      );
      expect(failure, isA<UnauthorizedFailure>());
    });

    test('maps 4xx to RequestFailure carrying the code', () {
      final failure = mapAppwriteException(
        AppwriteException('bad request', 400),
      );
      expect(failure, isA<RequestFailure>());
      expect((failure as RequestFailure).code, 400);
    });

    test('maps 5xx to ServerFailure', () {
      final failure = mapAppwriteException(
        AppwriteException('boom', 500),
      );
      expect(failure, isA<ServerFailure>());
    });

    test('maps unknown/null code to ServerFailure', () {
      final failure = mapAppwriteException(AppwriteException('mystery'));
      expect(failure, isA<ServerFailure>());
    });
  });

  group('mapAppException', () {
    test('maps UnauthorizedException to UnauthorizedFailure', () {
      expect(
        mapAppException(const UnauthorizedException()),
        isA<UnauthorizedFailure>(),
      );
    });

    test('maps NetworkException to NetworkFailure', () {
      expect(
        mapAppException(const NetworkException()),
        isA<NetworkFailure>(),
      );
    });

    test('maps NotFoundException to RequestFailure', () {
      expect(
        mapAppException(const NotFoundException()),
        isA<RequestFailure>(),
      );
    });
  });

  group('mapError', () {
    test('passes through an existing Failure unchanged', () {
      const original = NetworkFailure('offline');
      expect(mapError(original), same(original));
    });

    test('translates AppwriteException', () {
      expect(
        mapError(AppwriteException('unauthorized', 401)),
        isA<UnauthorizedFailure>(),
      );
    });

    test('translates a data-layer AppException', () {
      expect(mapError(const NetworkException()), isA<NetworkFailure>());
    });

    test('falls back to ServerFailure for unknown errors', () {
      expect(mapError(Exception('???')), isA<ServerFailure>());
    });
  });
}
