import 'package:flutter/material.dart';
import 'package:pikacircle/features/sessions/presentation/screens/sessions_screen.dart';
import 'package:pikacircle/shared/widgets/session_info_card.dart';

class HostedSessionCard extends StatelessWidget {
  const HostedSessionCard({super.key, required this.session});

  final HostedSession session;

  @override
  Widget build(BuildContext context) {
    return SessionInfoCard(
      title: session.title,
      excerpt: session.excerpt,
      sessionTypeLabel: session.sessionTypeLabel,
      skillLevelLabel: session.skillLevelLabel,
      rosterLabel: session.rosterLabel,
      locationLine: session.locationLine,
      durationLabel: session.durationLabel,
    );
  }
}
