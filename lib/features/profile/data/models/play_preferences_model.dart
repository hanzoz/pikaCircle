import 'package:appwrite/models.dart' as models;

import 'package:pikacircle/features/profile/domain/entities/play_preferences.dart';

/// Maps an Appwrite `user_play_preferences` [models.Row] into a domain
/// [PlayPreferences].
///
/// Data-layer only. Parsing is defensive: array fields coerce each element to
/// a non-empty String, and absent fields default to empty lists.
abstract final class PlayPreferencesModel {
  static PlayPreferences fromRow(models.Row row) {
    final data = row.data;
    return PlayPreferences(
      preferredTimeSlots: _stringList(data['preferred_time_slots']),
      preferredDays: _stringList(data['preferred_days']),
      preferredFormatIds: _stringList(data['preferred_format_ids']),
      notes: _string(data['notes']),
    );
  }

  /// Coerces a dynamic value into a `List<String>`, skipping null/empty items.
  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    final parsed = <String>[];
    for (final item in value) {
      final str = _string(item);
      if (str != null) parsed.add(str);
    }
    return parsed;
  }

  /// Coerces a dynamic value to a non-empty [String], or `null`.
  static String? _string(Object? value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }
}
