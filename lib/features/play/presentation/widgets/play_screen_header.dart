import 'package:flutter/material.dart';
import 'package:pikacircle/features/play/presentation/screens/play_screen.dart';
import 'package:pikacircle/shared/widgets/session_list_header.dart';

class PlayScreenHeader extends StatelessWidget {
  const PlayScreenHeader({
    super.key,
    required this.selectedDate,
    required this.sessionCount,
  });

  final DateTime selectedDate;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    return SessionListHeader(
      selectedDate: selectedDate,
      sessionCount: sessionCount,
      relativeDateTitle: PlaySession.relativeDateTitle,
    );
  }
}
