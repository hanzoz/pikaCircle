import 'package:appwrite/models.dart' as models;

import 'package:pikacircle/features/profile/domain/entities/venue_option.dart';

/// Maps an Appwrite `venues` [models.Row] into a domain [VenueOption].
///
/// Data-layer only. Parsing is defensive: `name` falls back to an empty
/// string and `city` is nullable.
abstract final class VenueOptionModel {
  static VenueOption fromRow(models.Row row) {
    final data = row.data;
    return VenueOption(
      id: row.$id,
      name: _string(data['name']) ?? '',
      city: _string(data['city']),
    );
  }

  /// Coerces a dynamic value to a non-empty [String], or `null`.
  static String? _string(Object? value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }
}
