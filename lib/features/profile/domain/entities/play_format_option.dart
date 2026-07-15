/// A selectable play-format option for the Edit Profile preferences dropdown,
/// mirroring a `play_formats` row.
///
/// Immutable value object with a const constructor and value equality.
/// Domain-only: no Flutter or Appwrite imports.
class PlayFormatOption {
  const PlayFormatOption({
    required this.id,
    required this.name,
    required this.displayName,
  });

  final String id;
  final String name;
  final String displayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayFormatOption &&
        other.id == id &&
        other.name == name &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => Object.hash(id, name, displayName);

  @override
  String toString() =>
      'PlayFormatOption(id: $id, name: $name, displayName: $displayName)';
}
