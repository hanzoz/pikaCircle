import 'package:pikacircle/core/result/result.dart';
import 'package:pikacircle/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:pikacircle/features/profile/data/models/user_profile_model.dart';
import 'package:pikacircle/features/profile/data/models/wallet_model.dart';
import 'package:pikacircle/features/profile/domain/entities/account_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/user_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/wallet.dart';
import 'package:pikacircle/features/profile/domain/repositories/profile_repository.dart';

/// Default [ProfileRepository] backed by [ProfileRemoteDataSource].
///
/// Catches any data-layer error and translates it into a [Failure] via
/// `mapError`, returning it as the `Left` of a [Result].
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Result<AccountProfile>> loadProfile(String userId) async {
    try {
      final userRow = await _remote.getUserRow(userId);
      final user = UserProfileModel.fromRow(userRow);

      final walletRow = await _remote.getWalletRow(userId);
      final Wallet? wallet =
          walletRow == null ? null : WalletModel.fromRow(walletRow);

      return Right(AccountProfile(user: user, wallet: wallet));
    } catch (e) {
      return Left(mapError(e));
    }
  }

  @override
  Future<Result<UserProfile>> upsertProfile({
    required String userId,
    required Map<String, Object?> editableFields,
    String? skillLevel,
  }) async {
    try {
      await _remote.upsertProfile(
        editableFields: editableFields,
        skillLevel: skillLevel,
      );

      // Re-fetch the authoritative row so the returned profile reflects any
      // server-side normalization the function applied.
      final userRow = await _remote.getUserRow(userId);
      return Right(UserProfileModel.fromRow(userRow));
    } catch (e) {
      return Left(mapError(e));
    }
  }
}
