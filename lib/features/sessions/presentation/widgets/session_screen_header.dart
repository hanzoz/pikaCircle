import 'package:flutter/material.dart';
import 'package:pikacircle/features/sessions/presentation/screens/sessions_screen.dart';
import 'package:pikacircle/shared/widgets/session_list_header.dart';

class SessionScreenHeader extends StatelessWidget {
  const SessionScreenHeader({
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
      relativeDateTitle: HostedSession.relativeDateTitle,
    );
  }
}
