import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Liquid Glass theming configuration.
///
/// Extracted from the inline `LiquidGlassWidgets.wrap` call that used to live in
/// `main.dart` so the glass look is configured in one place.
abstract final class AppGlassTheme {
  static const bool adaptiveQuality = true;

  static GlassThemeData get data => GlassThemeData.simple(
    blur: 10,
    thickness: 30,
    quality: GlassQuality.standard,
  );
}
