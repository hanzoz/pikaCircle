import 'package:flutter/material.dart';

import 'package:pikacircle/shared/widgets/empty_state_card.dart';

/// Sessions tab. Shown as "Play" and (for hosts) "My Sessions".
///
/// Placeholder for now. Joining, roster, and host tools are wired through the
/// `session-join` trusted function in this feature's data layer.
class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateCard(
      title: 'Sessions',
      message: 'Upcoming sessions will appear here.',
      icon: Icons.calendar_month_rounded,
    );
  }
}
