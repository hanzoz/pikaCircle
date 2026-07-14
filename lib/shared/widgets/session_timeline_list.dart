import 'package:flutter/material.dart';

class SessionTimelineList<T> extends StatelessWidget {
  const SessionTimelineList({
    required this.sessions,
    required this.timeLabel,
    required this.itemBuilder,
    super.key,
  });

  final List<T> sessions;
  final String Function(T session) timeLabel;
  final Widget Function(BuildContext context, T session) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < sessions.length; index++) ...[
          _SessionTimelineItem<T>(
            session: sessions[index],
            showTopLine: index != 0,
            showBottomLine: index != sessions.length - 1,
            timeLabel: timeLabel,
            itemBuilder: itemBuilder,
          ),
          if (index != sessions.length - 1)
            const _SessionTimelineGapConnector(),
        ],
      ],
    );
  }
}

class _SessionTimelineItem<T> extends StatelessWidget {
  const _SessionTimelineItem({
    required this.session,
    required this.showTopLine,
    required this.showBottomLine,
    required this.timeLabel,
    required this.itemBuilder,
  });

  final T session;
  final bool showTopLine;
  final bool showBottomLine;
  final String Function(T session) timeLabel;
  final Widget Function(BuildContext context, T session) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SessionTimelineDot<T>(
            session: session,
            showTopLine: showTopLine,
            showBottomLine: showBottomLine,
            timeLabel: timeLabel,
          ),
          const SizedBox(width: 16),
          Expanded(child: itemBuilder(context, session)),
        ],
      ),
    );
  }
}

class _SessionTimelineDot<T> extends StatelessWidget {
  const _SessionTimelineDot({
    required this.session,
    required this.showTopLine,
    required this.showBottomLine,
    required this.timeLabel,
  });

  final T session;
  final bool showTopLine;
  final bool showBottomLine;
  final String Function(T session) timeLabel;

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
                timeLabel(session),
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

class _SessionTimelineGapConnector extends StatelessWidget {
  const _SessionTimelineGapConnector();

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
