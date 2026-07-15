/// A user's play preferences, mirroring the `user_play_preferences` row.
///
/// Immutable value object with a const constructor and value equality.
/// Domain-only: no Flutter or Appwrite imports.
class PlayPreferences {
  const PlayPreferences({
    this.preferredTimeSlots = const [],
    this.preferredDays = const [],
    this.preferredFormatIds = const [],
    this.notes,
  });

  final List<String> preferredTimeSlots;
  final List<String> preferredDays;
  final List<String> preferredFormatIds;
  final String? notes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayPreferences &&
        _listEquals(other.preferredTimeSlots, preferredTimeSlots) &&
        _listEquals(other.preferredDays, preferredDays) &&
        _listEquals(other.preferredFormatIds, preferredFormatIds) &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(preferredTimeSlots),
    Object.hashAll(preferredDays),
    Object.hashAll(preferredFormatIds),
    notes,
  );

  @override
  String toString() =>
      'PlayPreferences(preferredTimeSlots: $preferredTimeSlots, '
      'preferredDays: $preferredDays, '
      'preferredFormatIds: $preferredFormatIds, notes: $notes)';
}

/// Order-sensitive list equality used for value comparison of String lists.
bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
