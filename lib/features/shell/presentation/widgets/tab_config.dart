import 'package:flutter/material.dart';

/// Static configuration for one primary navigation destination in the shell.
///
/// Extracted from the private `_TabConfig` that used to live in `main.dart`.
class TabConfig {
  const TabConfig({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.message,
    required this.glowColor,
  });

  final String title;
  final IconData icon;
  final IconData activeIcon;
  final String message;
  final Color glowColor;
}
