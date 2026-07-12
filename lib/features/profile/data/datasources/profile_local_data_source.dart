import 'dart:convert';

import 'package:hive/hive.dart';

import 'package:pikacircle/features/profile/data/models/account_profile_cache.dart';
import 'package:pikacircle/features/profile/domain/entities/account_profile.dart';

/// Local, on-device cache of the signed-in user's [AccountProfile].
///
/// Backed by a Hive [Box] of JSON strings keyed by user id. All decode paths
/// are tolerant: a corrupt or missing entry yields `null` rather than throwing,
/// so a bad cache never breaks the app.
class ProfileLocalDataSource {
  ProfileLocalDataSource(this._box);

  final Box<String> _box;

  /// Reads the cached profile for [userId], or `null` on miss/decode error.
  AccountProfile? read(String userId) {
    try {
      final raw = _box.get(userId);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AccountProfileCache.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Writes [profile] to the cache under [userId].
  Future<void> write(String userId, AccountProfile profile) {
    return _box.put(userId, jsonEncode(AccountProfileCache.toJson(profile)));
  }

  /// Wipes all cached profiles (used on logout).
  Future<void> clear() => _box.clear();
}
