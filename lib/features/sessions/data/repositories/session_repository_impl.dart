import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/core/result/result.dart';
import 'package:pikacircle/features/sessions/data/datasources/session_remote_data_source.dart';
import 'package:pikacircle/features/sessions/domain/entities/session_join_result.dart';
import 'package:pikacircle/features/sessions/domain/repositories/session_repository.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._remote);

  final SessionRemoteDataSource _remote;

  @override
  Future<Result<SessionJoinResult>> joinSession({
    required String sessionId,
    String? accessCode,
  }) async {
    try {
      final result = await _remote.joinSession(
        sessionId: sessionId,
        accessCode: accessCode,
      );
      return Right(result);
    } catch (e) {
      return Left(mapError(e));
    }
  }
}

final sessionRemoteDataSourceProvider = Provider<SessionRemoteDataSource>((ref) {
  return SessionRemoteDataSource(
    ref.watch(appwriteFunctionsProvider),
    ref.watch(appwriteConfigProvider),
  );
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepositoryImpl(ref.watch(sessionRemoteDataSourceProvider));
});
