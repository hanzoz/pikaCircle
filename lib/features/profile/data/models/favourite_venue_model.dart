import 'package:appwrite/models.dart' as models;

import 'package:pikacircle/features/profile/domain/entities/favourite_venue.dart';

/// Maps an Appwrite `user_favourite_venues` [models.Row] into a domain
/// [FavouriteVenue], or `null` when the venue relationship is missing.
///
/// Data-layer only. The `venue_id` relationship may arrive as a plain ID
/// string or an expanded object carrying `$id`.
abstract final class FavouriteVenueModel {
  static FavouriteVenue? fromRow(models.Row row) {
    final data = row.data;
    final venueId = _relationId(data['venue_id']);
    if (venueId == null) return null;
    return FavouriteVenue(
      venueId: venueId,
      sortOrder: _int(data['sort_order']),
    );
  }

  /// Extracts the `$id` from a relationship value, or the raw string.
  static String? _relationId(Object? value) {
    if (value is Map) return _string(value[r'$id']);
    return _string(value);
  }

  /// Coerces a dynamic value into an [int], defaulting to `0`.
  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  /// Coerces a dynamic value to a non-empty [String], or `null`.
  static String? _string(Object? value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }
}
