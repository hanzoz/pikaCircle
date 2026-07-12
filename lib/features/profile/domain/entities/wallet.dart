/// A user's credit wallet, mirroring the `wallet` row (see `docs/database.md`).
///
/// Immutable value object with a const constructor and value equality.
/// Domain-only: no Flutter or Appwrite imports.
class Wallet {
  const Wallet({
    required this.id,
    this.freeCredits = 0,
    this.paidCredits = 0,
    this.freeCreditsExpiryDate,
  });

  /// The Appwrite wallet row id (`row.$id`).
  final String id;
  final num freeCredits;
  final num paidCredits;
  final String? freeCreditsExpiryDate;

  /// Combined spendable balance across free and paid credits.
  num get totalCredits => freeCredits + paidCredits;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wallet &&
        other.id == id &&
        other.freeCredits == freeCredits &&
        other.paidCredits == paidCredits &&
        other.freeCreditsExpiryDate == freeCreditsExpiryDate;
  }

  @override
  int get hashCode =>
      Object.hash(id, freeCredits, paidCredits, freeCreditsExpiryDate);

  @override
  String toString() =>
      'Wallet(id: $id, freeCredits: $freeCredits, paidCredits: $paidCredits)';
}
