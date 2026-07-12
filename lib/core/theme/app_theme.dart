import 'package:flutter/material.dart';

/// Centralized Material theming for PikaCircle.
///
/// Colors and typography mirror the playCircle design system.
abstract final class AppTheme {
  // Brand palette
  static const Color rose = Color(0xFFE11D48);
  static const Color roseSoft = Color(0xFFFB7185);
  static const Color roseDeep = Color(0xFF881337);
  static const Color blue = Color(0xFF2563EB);
  static const Color ink = Color(0xFF172033);
  static const Color canvas = Color(0xFFE7E9EE);
  static const Color card = Color(0xFFFFFCFD);
  static const Color freeCredit = Color(0xFFE11D48);
  static const Color paidCredit = Color(0xFF16A34A);
  static const Color line = Color(0xFFF2D7DD);

  static ThemeData get light {
    final baseTextTheme = ThemeData.light().textTheme;
    const headingFamily = 'Arial Narrow';
    const bodyFamily = 'Arial';

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: const ColorScheme.light(
        primary: rose,
        onPrimary: Colors.white,
        secondary: blue,
        onSecondary: Colors.white,
        surface: const Color(0xFFE7E9EE),
        onSurface: ink,
        error: rose,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        displaySmall: const TextStyle(
          fontFamily: headingFamily,
          fontSize: 42,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 0.95,
        ),
        headlineMedium: const TextStyle(
          fontFamily: headingFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleLarge: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        titleMedium: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyLarge: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 16,
          color: ink,
          height: 1.3,
        ),
        bodyMedium: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 14,
          color: Color(0xFF4B5563),
          height: 1.35,
        ),
      ),
    );
  }

  static ThemeData get dark {
    final baseTextTheme = ThemeData.dark().textTheme;
    const headingFamily = 'Arial Narrow';
    const bodyFamily = 'Arial';

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: rose,
        brightness: Brightness.dark,
      ),
      textTheme: baseTextTheme.copyWith(
        displaySmall: const TextStyle(
          fontFamily: headingFamily,
          fontSize: 42,
          fontWeight: FontWeight.w700,
          height: 0.95,
        ),
        headlineMedium: const TextStyle(
          fontFamily: headingFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 16,
          height: 1.3,
        ),
        bodyMedium: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 14,
          height: 1.35,
        ),
      ),
    );
  }
}
