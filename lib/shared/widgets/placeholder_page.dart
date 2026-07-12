import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:pikacircle/shared/widgets/empty_state_card.dart';
import 'package:pikacircle/shared/widgets/pika_app_bar.dart';

/// A full glass page with a back-navigating app bar and a centered
/// [EmptyStateCard] body.
///
/// Extracted from the former private `_PlaceholderPage` in `main.dart` so
/// feature screens can present a titled placeholder without duplicating the
/// glass scaffold boilerplate.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassScaffold(
      backgroundColor: colorScheme.surface,
      statusBarStyle: GlassStatusBarStyle.auto,
      appBar: GlassAppBar(
        centerTitle: false,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        leading: PikaLeadingButton(
          leading: PikaAppBarLeading.back,
          initials: null,
          onTap: () => Navigator.of(context).pop(),
        ),
        actions: [PikaNavButton(icon: CupertinoIcons.bell)],
      ),
      body: EmptyStateCard(title: title, message: message, icon: icon),
    );
  }
}
