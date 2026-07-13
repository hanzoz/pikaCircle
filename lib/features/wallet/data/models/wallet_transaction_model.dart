import 'package:appwrite/models.dart' as models;

import 'package:pikacircle/features/wallet/domain/entities/wallet_transaction.dart';

/// Maps an Appwrite `transactions` [models.Row] into a domain transaction.
abstract final class WalletTransactionModel {
  static WalletTransaction fromRow(models.Row row) {
    final data = row.data;
    return WalletTransaction(
      id: row.$id,
      type: _string(data['type']) ?? 'adjustment',
      creditsDelta: _num(data['credits_delta']),
      transactionDate: _date(data['transaction_date']),
      remarks: _string(data['remarks']),
      sessionId: _relationId(data['session_id']),
    );
  }

  static num _num(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static DateTime _date(Object? value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static String? _relationId(Object? value) {
    if (value is Map) {
      final id = value[r'$id'];
      return id?.toString();
    }
    return _string(value);
  }
}
