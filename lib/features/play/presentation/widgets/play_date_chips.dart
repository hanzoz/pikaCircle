import 'package:flutter/material.dart';
import 'package:pikacircle/features/play/presentation/screens/play_screen.dart';
import 'package:pikacircle/shared/widgets/selectable_date_chips.dart';

class PlayDateChips extends StatelessWidget {
  const PlayDateChips({
    super.key,
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
    return SelectableDateChips(
      availableDates: availableDates,
      sessionCountByDate: sessionCountByDate,
      selectedDate: selectedDate,
      onDateSelected: onDateSelected,
      isSameDay: PlaySession.isSameDay,
      dateStamp: PlaySession.dateStamp,
      weekdayShort: PlaySession.weekdayShort,
    );
  }
}
