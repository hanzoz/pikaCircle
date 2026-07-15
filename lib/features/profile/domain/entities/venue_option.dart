/// A selectable venue option for the Edit Profile favourite-venues dropdown,
/// mirroring a `venues` row.
///
/// Immutable value object with a const constructor and value equality.
/// Domain-only: no Flutter or Appwrite imports.
class VenueOption {
  const VenueOption({
    required this.id,
    required this.name,
    this.city,
  });

  final String id;
  final String name;
  final String? city;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VenueOption &&
        other.id == id &&
        other.name == name &&
        other.city == city;
  }

  @override
  int get hashCode => Object.hash(id, name, city);

  @override
  String toString() => 'VenueOption(id: $id, name: $name, city: $city)';
}
