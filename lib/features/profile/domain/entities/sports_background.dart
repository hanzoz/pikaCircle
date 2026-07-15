/// A user's sports background, mirroring the `user_sports_backgrounds` row.
///
/// Immutable value object with a const constructor and value equality.
/// Domain-only: no Flutter or Appwrite imports.
class SportsBackground {
  const SportsBackground({
    required this.sportId,
    this.level,
    this.isPrimary = false,
    this.yearsPlayed,
    this.notes,
  });

  final String sportId;
  final String? level;
  final bool isPrimary;
  final int? yearsPlayed;
  final String? notes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SportsBackground &&
        other.sportId == sportId &&
        other.level == level &&
        other.isPrimary == isPrimary &&
        other.yearsPlayed == yearsPlayed &&
        other.notes == notes;
  }

  @override
  int get hashCode =>
      Object.hash(sportId, level, isPrimary, yearsPlayed, notes);

  @override
  String toString() =>
      'SportsBackground(sportId: $sportId, level: $level, '
      'isPrimary: $isPrimary, yearsPlayed: $yearsPlayed, notes: $notes)';
}
