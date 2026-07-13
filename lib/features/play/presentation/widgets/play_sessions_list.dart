import 'package:flutter/material.dart';
import 'package:pikacircle/features/play/presentation/screens/play_screen.dart';
import 'play_session_card.dart';

class PlaySessionsList extends StatelessWidget {
  const PlaySessionsList({required this.sessions});

  final List<PlaySession> sessions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < sessions.length; index++) ...[
          PlaySessionTimelineItem(
            session: sessions[index],
            showTopLine: index != 0,
            showBottomLine: index != sessions.length - 1,
          ),
          if (index != sessions.length - 1) const PlayTimelineGapConnector(),
        ],
      ],
    );
  }
}

class PlaySessionTimelineItem extends StatelessWidget {
  const PlaySessionTimelineItem({
    required this.session,
    required this.showTopLine,
    required this.showBottomLine,
  });

  final PlaySession session;
  final bool showTopLine;
  final bool showBottomLine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlayTimelineDot(
            session: session,
            showTopLine: showTopLine,
            showBottomLine: showBottomLine,
          ),
          const SizedBox(width: 16),
          Expanded(child: PlaySessionCard(session: session)),
        ],
      ),
    );
  }
}

class PlayTimelineDot extends StatelessWidget {
  const PlayTimelineDot({
    required this.session,
    required this.showTopLine,
    required this.showBottomLine,
  });

  final PlaySession session;
  final bool showTopLine;
  final bool showBottomLine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 72,
      child: Column(
        children: [
          if (showTopLine)
            Container(width: 2, height: 10, color: colorScheme.outlineVariant),
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                session.startTimeLabel,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: showBottomLine
                  ? Container(width: 2, color: colorScheme.outlineVariant)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayTimelineGapConnector extends StatelessWidget {
  const PlayTimelineGapConnector();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.only(left: 35),
      child: SizedBox(
        height: 18,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(width: 2, height: 18, color: color),
        ),
      ),
    );
  }
}
