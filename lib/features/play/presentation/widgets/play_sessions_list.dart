import 'package:flutter/material.dart';
import 'package:pikacircle/features/play/presentation/screens/play_screen.dart';
import 'package:pikacircle/shared/widgets/session_timeline_list.dart';
import 'play_session_card.dart';

class PlaySessionsList extends StatelessWidget {
  const PlaySessionsList({super.key, required this.sessions});

  final List<PlaySession> sessions;

  @override
  Widget build(BuildContext context) {
    return SessionTimelineList<PlaySession>(
      sessions: sessions,
      timeLabel: (session) => session.startTimeLabel,
      itemBuilder: (context, session) => PlaySessionCard(session: session),
    );
  }
}
