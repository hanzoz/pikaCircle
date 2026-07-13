import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pikacircle/features/profile/data/models/wallet_model.dart';
import 'package:pikacircle/features/profile/domain/entities/wallet.dart';
import 'package:pikacircle/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:pikacircle/features/wallet/data/models/wallet_transaction_model.dart';
import 'package:pikacircle/features/wallet/data/wallet_providers.dart';
import 'package:pikacircle/features/wallet/domain/entities/wallet_transaction.dart';

/// Loads the signed-in user's wallet balance and recent transactions.
class WalletController
    extends
        AsyncNotifier<
          ({Wallet? wallet, List<WalletTransaction> transactions})?
        > {
  WalletRemoteDataSource get _remote =>
      ref.read(walletRemoteDataSourceProvider);

  @override
  Future<({Wallet? wallet, List<WalletTransaction> transactions})?>
  build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;

    return _loadWalletHistory(userId);
  }

  Future<({Wallet? wallet, List<WalletTransaction> transactions})>
  _loadWalletHistory(String userId) async {
    final results = await Future.wait<Object?>([
      _remote.getWalletRow(userId),
      _remote.listTransactionRows(userId),
    ]);

    final walletRow = results[0] as models.Row?;
    final transactionRows = results[1] as models.RowList;

    final wallet = walletRow == null ? null : WalletModel.fromRow(walletRow);
    final transactions = transactionRows.rows
        .map((row) => WalletTransactionModel.fromRow(row))
        .toList(growable: false);

    return (wallet: wallet, transactions: transactions);
  }

  Future<void> reload() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      state = const AsyncData(null);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return _loadWalletHistory(userId);
    });
  }
}

final walletControllerProvider =
    AsyncNotifierProvider<
      WalletController,
      ({Wallet? wallet, List<WalletTransaction> transactions})?
    >(WalletController.new);
