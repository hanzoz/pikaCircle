/// A user's favourite venue, mirroring the `user_favourite_venues` row.
///
/// Immutable value object with a const constructor and value equality.
/// Domain-only: no Flutter or Appwrite imports.
class FavouriteVenue {
  const FavouriteVenue({
    required this.venueId,
    this.sortOrder = 0,
  });

  final String venueId;
  final int sortOrder;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavouriteVenue &&
        other.venueId == venueId &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(venueId, sortOrder);

  @override
  String toString() =>
      'FavouriteVenue(venueId: $venueId, sortOrder: $sortOrder)';
}
