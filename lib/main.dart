import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:pikacircle/app/app.dart';
import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/core/config/appwrite_config.dart';
import 'package:pikacircle/core/config/env.dart';
import 'package:pikacircle/core/theme/glass_theme.dart';
import 'package:pikacircle/features/profile/data/profile_cache_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load public client config (.env.client only — never the server .env).
  await Env.load();
  final appwriteConfig = AppwriteConfig.fromEnv();

  // Bootstrap the on-device profile cache before the app reads it.
  await Hive.initFlutter();
  final profileBox = await Hive.openBox<String>('profile_cache');

  await LiquidGlassWidgets.initialize();

  runApp(
    ProviderScope(
      overrides: [
        // Provide the resolved Appwrite config to the whole provider graph.
        appwriteConfigProvider.overrideWithValue(appwriteConfig),
        // Inject the opened Hive box backing the profile cache.
        profileCacheBoxProvider.overrideWithValue(profileBox),
      ],
      child: LiquidGlassWidgets.wrap(
        adaptiveQuality: AppGlassTheme.adaptiveQuality,
        theme: AppGlassTheme.data,
        child: const PikaCircleApp(),
      ),
    ),
  );
}
