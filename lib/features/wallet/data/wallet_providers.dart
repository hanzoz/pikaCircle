import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/features/wallet/data/datasources/wallet_remote_data_source.dart';

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSource(
    ref.watch(appwriteTablesDbProvider),
    ref.watch(appwriteConfigProvider),
  );
});
