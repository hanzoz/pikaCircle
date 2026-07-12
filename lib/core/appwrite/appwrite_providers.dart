import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/appwrite_config.dart';

/// Resolved Appwrite configuration. Overridden in `main()` with a value built
/// from the environment, and overridable in tests with a fake config.
final appwriteConfigProvider = Provider<AppwriteConfig>((ref) {
  throw UnimplementedError(
    'appwriteConfigProvider must be overridden in ProviderScope '
    '(see bootstrap in main.dart).',
  );
});

/// The shared Appwrite [Client]. All Appwrite services are derived from this.
///
/// Override this single provider in tests (or the service providers below) to
/// swap in fakes without touching feature code.
final appwriteClientProvider = Provider<Client>((ref) {
  final config = ref.watch(appwriteConfigProvider);
  // DEV ONLY: remove `setSelfSigned` for production builds.
  // Production must use a publicly trusted TLS certificate.
  return Client()
      .setEndpoint(config.endpoint)
      .setProject(config.projectId)
      .setSelfSigned(status: true);
});

/// Appwrite Account service (auth, sessions, OAuth).
final appwriteAccountProvider = Provider<Account>((ref) {
  return Account(ref.watch(appwriteClientProvider));
});

/// Appwrite TablesDB service (rows in the `main` database).
final appwriteTablesDbProvider = Provider<TablesDB>((ref) {
  return TablesDB(ref.watch(appwriteClientProvider));
});

/// Appwrite Functions service (trusted server flows such as `profile-upsert`
/// and `session-join`).
final appwriteFunctionsProvider = Provider<Functions>((ref) {
  return Functions(ref.watch(appwriteClientProvider));
});

/// Appwrite Storage service (avatar / announcement buckets).
final appwriteStorageProvider = Provider<Storage>((ref) {
  return Storage(ref.watch(appwriteClientProvider));
});
