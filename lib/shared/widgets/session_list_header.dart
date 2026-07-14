import 'package:flutter/material.dart';

class SessionListHeader extends StatelessWidget {
  const SessionListHeader({
    required this.selectedDate,
    required this.sessionCount,
    required this.relativeDateTitle,
    super.key,
  });

  final DateTime selectedDate;
  final int sessionCount;
  final String Function(DateTime date) relativeDateTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = relativeDateTitle(selectedDate);
    final subtitle = sessionCount == 1 ? '1 session' : '$sessionCount sessions';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
