import 'package:flutter/material.dart';
import 'package:pikacircle/features/sessions/presentation/screens/sessions_screen.dart';
import 'package:pikacircle/shared/widgets/session_timeline_list.dart';
import 'hosted_session_card.dart';

class HostedSessionsList extends StatelessWidget {
  const HostedSessionsList({super.key, required this.sessions});

  final List<HostedSession> sessions;

  @override
  Widget build(BuildContext context) {
    return SessionTimelineList<HostedSession>(
      sessions: sessions,
      timeLabel: (session) => session.startTimeLabel,
      itemBuilder: (context, session) => HostedSessionCard(session: session),
    );
  }
}
