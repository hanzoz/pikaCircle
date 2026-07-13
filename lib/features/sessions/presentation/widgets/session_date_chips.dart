import 'package:flutter/material.dart';
import 'package:pikacircle/features/sessions/presentation/screens/sessions_screen.dart';

class SessionDateChips extends StatelessWidget {
  const SessionDateChips({
    required this.availableDates,
    required this.sessionCountByDate,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final List<DateTime> availableDates;
  final Map<int, int> sessionCountByDate;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(2, 8, 10, 2),
        itemCount: availableDates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = availableDates[index];
          final isSelected = HostedSession.isSameDay(date, selectedDate);
          return SessionDateChip(
            date: date,
            sessionCount:
                sessionCountByDate[HostedSession.dateStamp(date)] ?? 0,
            isSelected: isSelected,
            onTap: () => onDateSelected(date),
          );
        },
      ),
    );
  }
}

class SessionDateChip extends StatelessWidget {
  const SessionDateChip({
    required this.date,
    required this.sessionCount,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final int sessionCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const neutralTextColor = Color(0xFF6F7482);
    const selectedTextColor = Color(0xFF2563EB);
    const selectedBackgroundColor = Color(0xFFEFF6FF);
    final backgroundColor = isSelected ? selectedBackgroundColor : Colors.white;
    final foregroundColor = isSelected ? selectedTextColor : neutralTextColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 60,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    HostedSession.weekdayShort(date),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? selectedTextColor : neutralTextColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$sessionCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
