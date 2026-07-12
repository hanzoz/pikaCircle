import 'package:appwrite/models.dart' as models;

import 'package:pikacircle/core/result/result.dart';
import 'package:pikacircle/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pikacircle/features/auth/domain/entities/auth_user.dart';
import 'package:pikacircle/features/auth/domain/entities/oauth_provider.dart';
import 'package:pikacircle/features/auth/domain/repositories/auth_repository.dart';

/// [AuthRepository] backed by [AuthRemoteDataSource].
///
/// Every method funnels Appwrite calls through a try/catch that converts any
/// error into a [Failure] via [mapError], keeping the domain free of SDK
/// exceptions.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.signInWithEmail(
        email: email,
        password: password,
      );
      return Right(_toAuthUser(user));
    } on Object catch (e) {
      return Left(mapError(e));
    }
  }

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );
      return Right(_toAuthUser(user));
    } on Object catch (e) {
      return Left(mapError(e));
    }
  }

  @override
  Future<Result<Unit>> signOut() async {
    try {
      await _remote.signOut();
      return const Right(unit);
    } on Object catch (e) {
      return Left(mapError(e));
    }
  }

  @override
  Future<Result<AuthUser?>> currentUser() async {
    try {
      final user = await _remote.currentUser();
      return Right(user == null ? null : _toAuthUser(user));
    } on Object catch (e) {
      return Left(mapError(e));
    }
  }

  @override
  Future<Result<AuthUser>> signInWithOAuth(OAuthProvider provider) async {
    try {
      final user = await _remote.signInWithOAuth(provider);
      return Right(_toAuthUser(user));
    } on Object catch (e) {
      return Left(mapError(e));
    }
  }

  @override
  Future<Result<AuthUser>> completeOAuthSession({
    required String userId,
    required String secret,
  }) async {
    try {
      final user = await _remote.completeOAuthSession(
        userId: userId,
        secret: secret,
      );
      return Right(_toAuthUser(user));
    } on Object catch (e) {
      return Left(mapError(e));
    }
  }

  @override
  Future<Result<Unit>> sendPasswordRecovery(String email) async {
    try {
      await _remote.sendPasswordRecovery(email);
      return const Right(unit);
    } on Object catch (e) {
      return Left(mapError(e));
    }
  }

  AuthUser _toAuthUser(models.User user) {
    return AuthUser(
      id: user.$id,
      name: user.name,
      email: user.email,
      emailVerified: user.emailVerification,
    );
  }
}
