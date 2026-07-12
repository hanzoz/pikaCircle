import 'package:flutter/material.dart';

import 'package:pikacircle/shared/widgets/empty_state_card.dart';

/// Home tab — the authenticated landing view.
///
/// Placeholder content for now; the home feed (suggested sessions,
/// announcements) will be built out in its data/domain layers later.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateCard(
      title: 'Home',
      message: 'Your activity will appear here.',
      icon: Icons.home_rounded,
    );
  }
}
