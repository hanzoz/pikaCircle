import 'package:pikacircle/core/result/result.dart';
import 'package:pikacircle/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:pikacircle/features/profile/data/models/favourite_venue_model.dart';
import 'package:pikacircle/features/profile/data/models/play_format_option_model.dart';
import 'package:pikacircle/features/profile/data/models/play_preferences_model.dart';
import 'package:pikacircle/features/profile/data/models/sport_option_model.dart';
import 'package:pikacircle/features/profile/data/models/sports_background_model.dart';
import 'package:pikacircle/features/profile/data/models/user_profile_model.dart';
import 'package:pikacircle/features/profile/data/models/venue_option_model.dart';
import 'package:pikacircle/features/profile/data/models/wallet_model.dart';
import 'package:pikacircle/features/profile/domain/entities/account_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/favourite_venue.dart';
import 'package:pikacircle/features/profile/domain/entities/play_preferences.dart';
import 'package:pikacircle/features/profile/domain/entities/profile_edit_data.dart';
import 'package:pikacircle/features/profile/domain/entities/sports_background.dart';
import 'package:pikacircle/features/profile/domain/entities/user_profile.dart';
import 'package:pikacircle/features/profile/domain/entities/username_availability.dart';
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
      final Wallet? wallet = walletRow == null
          ? null
          : WalletModel.fromRow(walletRow);

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

  @override
  Future<Result<UserProfile>> uploadAvatar({
    required String userId,
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final fileId = await _remote.uploadAvatar(
        bytes: bytes,
        fileName: fileName,
      );
      await _remote.updateAvatarForUser(userId: userId, fileId: fileId);
      final userRow = await _remote.getUserRowAfterUpsert(userId);

      return Right(UserProfileModel.fromRow(userRow));
    } catch (e) {
      return Left(mapError(e));
    }
  }

  @override
  Future<Result<UsernameAvailability>> checkUsername(String username) async {
    try {
      final body = await _remote.checkUsernameAvailable(username);
      return Right(
        UsernameAvailability(
          available: body['available'] as bool? ?? false,
          normalized: body['normalized'] as String? ?? '',
          reason: body['reason'] as String?,
        ),
      );
    } catch (e) {
      return Left(mapError(e));
    }
  }

  @override
  Future<Result<ProfileEditData>> loadEditData(String userId) async {
    try {
      final userRow = await _remote.getUserRow(userId);
      final user = UserProfileModel.fromRow(userRow);

      final prefsRow = await _remote.getPlayPreferences(userId);
      final PlayPreferences? playPreferences = prefsRow == null
          ? null
          : PlayPreferencesModel.fromRow(prefsRow);

      final favouriteRows = await _remote.listFavouriteVenues(userId);
      final favouriteVenues = <FavouriteVenue>[
        for (final row in favouriteRows) ?FavouriteVenueModel.fromRow(row),
      ];

      final backgroundRows = await _remote.listSportsBackgrounds(userId);
      final sportsBackgrounds = <SportsBackground>[
        for (final row in backgroundRows) ?SportsBackgroundModel.fromRow(row),
      ];

      final venueRows = await _remote.listVenues();
      final venueOptions = [
        for (final row in venueRows) VenueOptionModel.fromRow(row),
      ];

      final sportRows = await _remote.listSports();
      final sportOptions = [
        for (final row in sportRows) SportOptionModel.fromRow(row),
      ];

      final formatRows = await _remote.listPlayFormats();
      final formatOptions = [
        for (final row in formatRows) PlayFormatOptionModel.fromRow(row),
      ];

      return Right(
        ProfileEditData(
          user: user,
          playPreferences: playPreferences,
          favouriteVenues: favouriteVenues,
          sportsBackgrounds: sportsBackgrounds,
          venueOptions: venueOptions,
          sportOptions: sportOptions,
          formatOptions: formatOptions,
        ),
      );
    } catch (e) {
      return Left(mapError(e));
    }
  }

  @override
  Future<Result<void>> saveEditData({
    required String userId,
    required Map<String, Object?> payload,
  }) async {
    try {
      await _remote.upsertProfileAggregate(payload);
      return const Right(null);
    } catch (e) {
      return Left(mapError(e));
    }
  }
}
