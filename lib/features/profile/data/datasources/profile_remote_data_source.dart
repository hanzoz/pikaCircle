import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;

import 'package:pikacircle/core/config/appwrite_config.dart';
import 'package:pikacircle/core/constants/table_ids.dart';

/// Talks to Appwrite for profile reads and writes.
///
/// Data-layer only: methods return raw Appwrite models (or decoded JSON) and
/// let [AppwriteException]s propagate. The repository catches and translates
/// them into `Failure`s.
class ProfileRemoteDataSource {
  ProfileRemoteDataSource(
    this._tables,
    this._functions,
    this._storage,
    this._config,
  );

  final TablesDB _tables;
  final Functions _functions;
  final Storage _storage;
  final AppwriteConfig _config;

  /// Fetches the caller's `users` row. Throws on any Appwrite error.
  Future<models.Row> getUserRow(String userId) {
    return _tables.getRow(
      databaseId: _config.databaseId,
      tableId: TableIds.users,
      rowId: userId,
    );
  }

  /// Fetches the caller's `wallet` row, or `null` when it does not exist yet
  /// (Appwrite 404). Rethrows all other Appwrite errors.
  Future<models.Row?> getWalletRow(String userId) async {
    try {
      return await _tables.getRow(
        databaseId: _config.databaseId,
        tableId: TableIds.wallet,
        rowId: userId,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      rethrow;
    }
  }

  /// Convenience re-fetch of the `users` row after an upsert. Identical to
  /// [getUserRow]; kept as a named seam for readability at call sites.
  Future<models.Row> getUserRowAfterUpsert(String userId) => getUserRow(userId);

  /// Calls the `profile-upsert` function with the caller's editable fields.
  ///
  /// Builds the JSON payload from [editableFields] (wire snake_case keys),
  /// adding `skill_level` when [skillLevel] is provided, and POSTs it. The
  /// caller's user id is injected server-side via the `x-appwrite-user-id`
  /// header, so it is not sent here.
  ///
  /// Returns the decoded success map. Throws an [AppwriteException] carrying
  /// the function's `error` message and status code when the response status
  /// is >= 400.
  Future<Map<String, dynamic>> upsertProfile({
    required Map<String, Object?> editableFields,
    String? skillLevel,
  }) async {
    final payload = <String, Object?>{
      ...editableFields,
      'skill_level': ?skillLevel,
    };

    final execution = await _functions.createExecution(
      functionId: _config.profileFunctionId,
      body: jsonEncode(payload),
      method: ExecutionMethod.pOST,
      headers: const {'content-type': 'application/json'},
    );

    final body = _decodeBody(execution.responseBody);

    if (execution.responseStatusCode >= 400) {
      final message = body['error']?.toString() ?? 'Profile update failed';
      throw AppwriteException(message, execution.responseStatusCode);
    }

    return body;
  }

  /// Checks whether [username] is available. POSTs {action:'check_username',
  /// username} to the profile-upsert function. Returns the decoded map,
  /// expected shape:
  /// `{ available: bool, normalized: String, reason?: String }`.
  ///
  /// Throws an [AppwriteException] carrying the function's `error` message and
  /// status code when the response status is >= 400.
  Future<Map<String, dynamic>> checkUsernameAvailable(String username) async {
    final execution = await _functions.createExecution(
      functionId: _config.profileFunctionId,
      body: jsonEncode({'action': 'check_username', 'username': username}),
      method: ExecutionMethod.pOST,
      headers: const {'content-type': 'application/json'},
    );

    final body = _decodeBody(execution.responseBody);

    if (execution.responseStatusCode >= 400) {
      final message = body['error']?.toString() ?? 'Username check failed';
      throw AppwriteException(message, execution.responseStatusCode);
    }

    return body;
  }

  /// Uploads avatar bytes into the configured avatars bucket via the
  /// authenticated Appwrite SDK client. Returns the created storage file id.
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileName,
  }) async {
    final file = await _storage.createFile(
      bucketId: _config.avatarBucketId,
      fileId: ID.unique(),
      file: InputFile.fromBytes(bytes: bytes, filename: fileName),
    );
    return file.$id;
  }

  /// Writes avatar file metadata to the caller's `users` row.
  Future<void> updateAvatarForUser({
    required String userId,
    required String fileId,
  }) async {
    final avatarUrl = _avatarViewUrl(fileId);
    await upsertProfile(
      editableFields: {
        'profile_picture_file_id': fileId,
        'profile_picture_url': avatarUrl,
      },
    );
  }

  String _avatarViewUrl(String fileId) {
    final endpointUri = Uri.parse(_config.endpoint);
    final basePath = endpointUri.path.replaceFirst(RegExp(r'/+$'), '');
    final path =
        '$basePath/storage/buckets/${_config.avatarBucketId}/files/$fileId/view';
    return endpointUri
        .replace(path: path, queryParameters: {'project': _config.projectId})
        .toString();
  }

  /// Fetches the caller's `user_play_preferences` row, or `null` when it does
  /// not exist yet. Tries a direct [TablesDB.getRow] by row id first (the
  /// preferences row id typically matches the user id), and on a 404 falls
  /// back to a `listRows` filtered by `user_id`. Rethrows other Appwrite
  /// errors.
  Future<models.Row?> getPlayPreferences(String userId) async {
    try {
      return await _tables.getRow(
        databaseId: _config.databaseId,
        tableId: TableIds.userPlayPreferences,
        rowId: userId,
      );
    } on AppwriteException catch (e) {
      if (e.code != 404) rethrow;
    }

    final list = await _tables.listRows(
      databaseId: _config.databaseId,
      tableId: TableIds.userPlayPreferences,
      queries: [Query.equal('user_id', userId), Query.limit(1)],
    );
    return list.rows.isEmpty ? null : list.rows.first;
  }

  /// Lists the caller's `user_favourite_venues` rows.
  Future<List<models.Row>> listFavouriteVenues(String userId) async {
    final list = await _tables.listRows(
      databaseId: _config.databaseId,
      tableId: TableIds.userFavouriteVenues,
      queries: [Query.equal('user_id', userId), Query.limit(200)],
    );
    return list.rows;
  }

  /// Lists the caller's `user_sports_backgrounds` rows.
  Future<List<models.Row>> listSportsBackgrounds(String userId) async {
    final list = await _tables.listRows(
      databaseId: _config.databaseId,
      tableId: TableIds.userSportsBackgrounds,
      queries: [Query.equal('user_id', userId), Query.limit(200)],
    );
    return list.rows;
  }

  /// Reads the `venues` catalog for dropdown options.
  Future<List<models.Row>> listVenues() async {
    final list = await _tables.listRows(
      databaseId: _config.databaseId,
      tableId: TableIds.venues,
      queries: [Query.limit(200)],
    );
    return list.rows;
  }

  /// Reads the `sports` catalog for dropdown options.
  Future<List<models.Row>> listSports() async {
    final list = await _tables.listRows(
      databaseId: _config.databaseId,
      tableId: TableIds.sports,
      queries: [Query.limit(200)],
    );
    return list.rows;
  }

  /// Reads the `play_formats` catalog for dropdown options.
  Future<List<models.Row>> listPlayFormats() async {
    final list = await _tables.listRows(
      databaseId: _config.databaseId,
      tableId: TableIds.playFormats,
      queries: [Query.limit(200)],
    );
    return list.rows;
  }

  /// Calls the `profile-upsert` function with a nested aggregate [payload]
  /// covering the user's profile fields plus play preferences, favourite
  /// venues, and sports backgrounds. POSTs the JSON payload; the caller's user
  /// id is injected server-side via the `x-appwrite-user-id` header.
  ///
  /// Returns the decoded success map. Throws an [AppwriteException] carrying
  /// the function's `error` message and status code when the response status
  /// is >= 400.
  Future<Map<String, dynamic>> upsertProfileAggregate(
    Map<String, Object?> payload,
  ) async {
    final execution = await _functions.createExecution(
      functionId: _config.profileFunctionId,
      body: jsonEncode(payload),
      method: ExecutionMethod.pOST,
      headers: const {'content-type': 'application/json'},
    );

    final body = _decodeBody(execution.responseBody);

    if (execution.responseStatusCode >= 400) {
      final message = body['error']?.toString() ?? 'Profile update failed';
      throw AppwriteException(message, execution.responseStatusCode);
    }

    return body;
  }

  /// Decodes the function response body into a JSON map, tolerating an empty
  /// or non-object body.
  Map<String, dynamic> _decodeBody(String responseBody) {
    if (responseBody.isEmpty) return const {};
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'value': decoded};
  }
}
