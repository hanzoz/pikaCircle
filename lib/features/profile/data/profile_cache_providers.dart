import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:pikacircle/features/profile/data/datasources/profile_local_data_source.dart';

/// The opened Hive box backing the profile cache.
///
/// Must be overridden in `main()` with the box opened during Hive bootstrap
/// (mirrors how `appwriteConfigProvider` is injected).
final profileCacheBoxProvider = Provider<Box<String>>(
  (ref) => throw UnimplementedError(
    'profileCacheBoxProvider must be overridden in main()',
  ),
);

/// The on-device profile cache, wired from the opened Hive box.
final profileLocalDataSourceProvider = Provider<ProfileLocalDataSource>(
  (ref) => ProfileLocalDataSource(ref.watch(profileCacheBoxProvider)),
);
