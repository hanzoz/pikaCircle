import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import 'package:pikacircle/core/config/appwrite_config.dart';
import 'package:pikacircle/core/constants/table_ids.dart';

/// Reads the caller's `wallet` row from Appwrite TablesDB.
///
/// The wallet row id equals the user id (one wallet per user). Balance
/// mutations (charges, refunds, resets) are performed only by trusted
/// functions, so this data source is read-only.
class WalletRemoteDataSource {
  const WalletRemoteDataSource(this._tables, this._config);

  final TablesDB _tables;
  final AppwriteConfig _config;

  /// Returns the raw wallet row for [userId], or null when no wallet exists yet.
  Future<models.Row?> getWalletRow(String userId) async {
    try {
      return await _tables.getRow(
        databaseId: _config.databaseId,
        tableId: TableIds.wallet,
        rowId: userId,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      rethrow;
    }
  }
}
