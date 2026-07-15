import 'package:appwrite/models.dart' as models;

import 'package:pikacircle/features/profile/domain/entities/sport_option.dart';

/// Maps an Appwrite `sports` [models.Row] into a domain [SportOption].
///
/// Data-layer only. Parsing is defensive: `display_name` falls back to `name`
/// when absent, and `name` falls back to an empty string.
abstract final class SportOptionModel {
  static SportOption fromRow(models.Row row) {
    final data = row.data;
    final name = _string(data['name']) ?? '';
    return SportOption(
      id: row.$id,
      name: name,
      displayName: _string(data['display_name']) ?? name,
    );
  }

  /// Coerces a dynamic value to a non-empty [String], or `null`.
  static String? _string(Object? value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }
}
