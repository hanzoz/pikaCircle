import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pikacircle/shared/widgets/pika_app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final appBarHeight = topInset + 44;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FA),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: const PikaAppBar(leading: PikaAppBarLeading.back),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _sampleNotifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          final item = _sampleNotifications[index];

          return DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7EAF0)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, size: 18, color: item.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.timeAgo,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;
  final Color accent;
}

const List<_NotificationItem> _sampleNotifications = <_NotificationItem>[
  _NotificationItem(
    title: 'Session Reminder',
    message: 'Your Open Play at CourtSide starts in 2 hours.',
    timeAgo: '2h ago',
    icon: CupertinoIcons.calendar,
    accent: Color(0xFF2F6BFF),
  ),
  _NotificationItem(
    title: 'Join Request Approved',
    message: 'You are confirmed for Friday Evening Hosted Session.',
    timeAgo: '5h ago',
    icon: CupertinoIcons.check_mark_circled,
    accent: Color(0xFF16A34A),
  ),
  _NotificationItem(
    title: 'Credits Updated',
    message: '10 credits were added to your wallet.',
    timeAgo: '1d ago',
    icon: CupertinoIcons.creditcard,
    accent: Color(0xFF0EA5E9),
  ),
];
