import 'package:flutter/material.dart';

typedef DateSelectionMatcher = bool Function(DateTime a, DateTime b);
typedef DateStampResolver = int Function(DateTime date);
typedef WeekdayShortFormatter = String Function(DateTime date);

class SelectableDateChips extends StatelessWidget {
  const SelectableDateChips({
    required this.availableDates,
    required this.sessionCountByDate,
    required this.selectedDate,
    required this.onDateSelected,
    required this.isSameDay,
    required this.dateStamp,
    required this.weekdayShort,
    super.key,
  });

  final List<DateTime> availableDates;
  final Map<int, int> sessionCountByDate;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateSelectionMatcher isSameDay;
  final DateStampResolver dateStamp;
  final WeekdayShortFormatter weekdayShort;

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
          final isSelected = isSameDay(date, selectedDate);
          return _SelectableDateChip(
            date: date,
            sessionCount: sessionCountByDate[dateStamp(date)] ?? 0,
            isSelected: isSelected,
            weekdayLabel: weekdayShort(date),
            onTap: () => onDateSelected(date),
          );
        },
      ),
    );
  }
}

class _SelectableDateChip extends StatelessWidget {
  const _SelectableDateChip({
    required this.date,
    required this.sessionCount,
    required this.isSelected,
    required this.weekdayLabel,
    required this.onTap,
  });

  final DateTime date;
  final int sessionCount;
  final bool isSelected;
  final String weekdayLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const neutralTextColor = Color(0xFF6F7482);
    const selectedTextColor = Color(0xFFFFFFFF);
    final selectedBackgroundColor = theme.colorScheme.secondary;
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
                    weekdayLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
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
                        fontSize: 24,
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
                    color: isSelected ? selectedBackgroundColor : Colors.white,
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
