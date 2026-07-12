import 'package:flutter/material.dart';

import 'package:pikacircle/shared/widgets/empty_state_card.dart';

/// Discovery / "Find" tab — session, venue, and player search.
///
/// Placeholder for now. The session discovery list and filters will be added
/// in this feature's data/domain layers (see `docs/app workflows`).
class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateCard(
      title: 'Find',
      message: 'Search and discovery will appear here.',
      icon: Icons.search_rounded,
    );
  }
}
