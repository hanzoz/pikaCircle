import 'package:appwrite/models.dart' as models;

import 'package:pikacircle/features/profile/domain/entities/wallet.dart';

/// Maps an Appwrite `wallet` [models.Row] into a domain [Wallet].
///
/// Data-layer only. Credit values are coerced from int/double/String shapes
/// into `num`, defaulting to `0` when absent or unparseable.
abstract final class WalletModel {
  static Wallet fromRow(models.Row row) {
    final data = row.data;
    return Wallet(
      id: row.$id,
      freeCredits: _num(data['free_credits']),
      paidCredits: _num(data['paid_credits']),
      freeCreditsExpiryDate: _string(data['free_credits_expiry_date']),
    );
  }

  /// Coerces a dynamic value into a [num], handling int/double/String and
  /// defaulting to `0`.
  static num _num(Object? value) {
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  /// Coerces a dynamic value to a non-empty [String], or `null`.
  static String? _string(Object? value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }
}
