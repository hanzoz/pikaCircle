import 'package:flutter/material.dart';
import 'package:pikacircle/features/play/presentation/screens/play_screen.dart';
import 'package:pikacircle/shared/widgets/session_info_card.dart';

class PlaySessionCard extends StatelessWidget {
  const PlaySessionCard({super.key, required this.session});

  final PlaySession session;

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
