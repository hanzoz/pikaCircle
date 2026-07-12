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

  /// Decodes the function response body into a JSON map, tolerating an empty
  /// or non-object body.
  Map<String, dynamic> _decodeBody(String responseBody) {
    if (responseBody.isEmpty) return const {};
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'value': decoded};
  }
}
