import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed accessor over the public client environment (`.env.client`).
///
/// Only public Appwrite values live here (endpoint, project id, bucket ids,
/// function ids). The server API key from the root `.env` must never be loaded
/// into the Flutter client.
abstract final class Env {
  /// Loads `.env.client` into [dotenv]. Call once during app bootstrap before
  /// reading any values.
  static Future<void> load() async {
    await dotenv.load(fileName: '.env.client');
  }

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required env key "$key" in .env.client. '
        'Ensure the file is listed under flutter/assets and contains this key.',
      );
    }
    return value;
  }

  static String get appwriteProjectId => _require('APPWRITE_PROJECT_ID');
  static String get appwriteEndpoint => _require('APPWRITE_ENDPOINT');
  static String get appwriteDatabaseId => _require('APPWRITE_DATABASE_ID');
  static String get avatarBucketId => _require('APPWRITE_AVATAR_BUCKET_ID');
  static String get announcementBucketId =>
      _require('APPWRITE_ANNOUNCEMENT_BUCKET_ID');
  static String get profileFunctionId =>
      _require('APPWRITE_PROFILE_FUNCTION_ID');
  static String get sessionJoinFunctionId =>
      _require('APPWRITE_SESSION_JOIN_FUNCTION_ID');
  static String get userPublicProfilesFunctionId =>
      _require('APPWRITE_USER_PUBLIC_PROFILES_FUNCTION_ID');
  static String get sessionPublicRosterFunctionId =>
      _require('APPWRITE_SESSION_PUBLIC_ROSTER_FUNCTION_ID');
}
