import 'package:appwrite/models.dart' as models;

import 'package:pikacircle/features/profile/domain/entities/sports_background.dart';

/// Maps an Appwrite `user_sports_backgrounds` [models.Row] into a domain
/// [SportsBackground], or `null` when the sport relationship is missing.
///
/// Data-layer only. Parsing is defensive: `is_primary` is coerced from
/// bool/String/num, and `sport_id` may be a plain ID or an expanded object.
abstract final class SportsBackgroundModel {
  static SportsBackground? fromRow(models.Row row) {
    final data = row.data;
    final sportId = _relationId(data['sport_id']);
    if (sportId == null) return null;
    return SportsBackground(
      sportId: sportId,
      level: _string(data['level']),
      isPrimary: _bool(data['is_primary']),
      yearsPlayed: _intOrNull(data['years_played']),
      notes: _string(data['notes']),
    );
  }

  /// Extracts the `$id` from a relationship value, or the raw string.
  static String? _relationId(Object? value) {
    if (value is Map) return _string(value[r'$id']);
    return _string(value);
  }

  /// Coerces a dynamic value into a nullable [int].
  static int? _intOrNull(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// Defensively parses a bool that may arrive as bool, String, or num.
  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  /// Coerces a dynamic value to a non-empty [String], or `null`.
  static String? _string(Object? value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }
}
