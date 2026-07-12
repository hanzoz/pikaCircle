import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/app/router/app_router.dart';
import 'package:pikacircle/core/theme/app_theme.dart';

/// Root application widget.
///
/// Wires the [GoRouter] (with auth-redirect guard) and shared Material theming.
/// Glass theming is applied above this widget in `main.dart` via
/// `LiquidGlassWidgets.wrap`.
class PikaCircleApp extends ConsumerWidget {
  const PikaCircleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'PikaCircle',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
