import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/core/constants/table_ids.dart';
import 'package:pikacircle/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pikacircle/shared/widgets/empty_state_card.dart';
import '../widgets/hosted_sessions_list.dart';
import '../widgets/session_date_chips.dart';
import '../widgets/session_screen_header.dart';

/// Provider for the Sessions tab (host-only): sessions where the current user is the appointed host.
/// This is for hosts to manage their own sessions, separate from playing in others' sessions.
/// Fetches from sessions table where host_id matches the current user.
/// A host won't see their hosted session in the Play tab unless they explicitly join as a participant.
final hostedSessionsProvider = FutureProvider.autoDispose<List<HostedSession>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || userId.isEmpty) {
    return const <HostedSession>[];
  }

  final tables = ref.watch(appwriteTablesDbProvider);
  final config = ref.watch(appwriteConfigProvider);

  /// Query sessions table: user must be the appointed host (host_id = userId)
  final sessionRows = await tables.listRows(
    databaseId: config.databaseId,
    tableId: TableIds.sessions,
    queries: [
      Query.equal('host_id', userId),
      Query.equal('status', ['published', 'in_progress', 'completed']),
      Query.orderAsc('starts_at'),
      Query.limit(200),
    ],
  );

  if (sessionRows.rows.isEmpty) {
    return const <HostedSession>[];
  }

  return sessionRows.rows
      .map((row) => HostedSession.fromRow(row))
      .toList(growable: false);
});

/// Sessions tab for hosts showing their created/hosted sessions.
/// 
/// Key distinction from Play tab:
/// - **Play tab**: Sessions where the user is a confirmed participant (joined others' sessions)
/// - **Sessions tab**: Sessions where the user is the appointed host (owns/manages sessions)
/// 
/// Hosts see only sessions where they are the appointed host (host_id = user_id).
/// To play in a session, a host must join separately via the Play tab.
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final sessionsState = ref.watch(hostedSessionsProvider);

    if (sessionsState.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (sessionsState.hasError) {
      return EmptyStateCard(
        title: 'Sessions',
        message:
            'Could not load your sessions right now. Pull to refresh later.',
        icon: Icons.calendar_month_rounded,
      );
    }

    final sessions = sessionsState.value ?? const <HostedSession>[];
    if (sessions.isEmpty) {
      return const EmptyStateCard(
        title: 'Sessions',
        message: 'Sessions you host will appear here.',
        icon: Icons.calendar_month_rounded,
      );
    }

    final availableDates = HostedSession.availableDates(sessions);
    final sessionCountByDate = HostedSession.sessionCountByDate(sessions);
    final selectedDate = _resolveSelectedDate(availableDates);
    final topContentPadding =
        MediaQuery.paddingOf(context).top + kToolbarHeight + 16;
    final filteredSessions =
        sessions
            .where((session) => session.isOnDate(selectedDate))
            .toList(growable: false)
          ..sort(HostedSession.compareByStartTime);

    return RefreshIndicator.adaptive(
      onRefresh: () async {
        ref.invalidate(hostedSessionsProvider);
        await ref.read(hostedSessionsProvider.future);
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, topContentPadding, 20, 120),
            children: [
              SessionScreenHeader(
                selectedDate: selectedDate,
                sessionCount: filteredSessions.length,
              ),
              const SizedBox(height: 18),
              SessionDateChips(
                availableDates: availableDates,
                sessionCountByDate: sessionCountByDate,
                selectedDate: selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
              const SizedBox(height: 28),
              HostedSessionsList(sessions: filteredSessions),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _resolveSelectedDate(List<DateTime> availableDates) {
    if (availableDates.isEmpty) {
      return HostedSession.dateOnly(DateTime.now());
    }

    final selectedDate = _selectedDate;
    if (selectedDate != null) {
      for (final candidate in availableDates) {
        if (HostedSession.isSameDay(candidate, selectedDate)) {
          return candidate;
        }
      }
    }

    final today = HostedSession.dateOnly(DateTime.now());
    for (final candidate in availableDates) {
      if (HostedSession.isSameDay(candidate, today)) {
        return candidate;
      }
    }

    return availableDates.first;
  }
}

class HostedSession {
  const HostedSession({
    required this.startsAt,
    required this.title,
    required this.excerpt,
    required this.scheduleLine,
    required this.locationLine,
    required this.durationLabel,
    required this.sessionType,
    required this.skillLevel,
    required this.sessionStatus,
    required this.participantCount,
    required this.maxParticipants,
  });

  factory HostedSession.fromRow(models.Row row) {
    final data = row.data;
    final startsAt = _dateTime(data['starts_at']);
    final title = stringValue(data['title']) ?? 'Untitled session';
    final schedule = _formatSessionSchedule(startsAt);
    final duration = _formatSessionDuration(data['session_duration']);
    final location =
        stringValue(data['location']) ?? stringValue(data['venue']);
    final excerpt =
        stringValue(data['description']) ??
        _buildFallbackExcerpt(data) ??
        'Session details will appear soon.';
    final maxParticipants = _int(data['max_participants']);
    final remainingSlots = _int(data['remainingSlots']);
    final participantCount = maxParticipants == null || remainingSlots == null
        ? null
        : (maxParticipants - remainingSlots).clamp(0, maxParticipants);

    return HostedSession(
      startsAt: startsAt,
      title: title,
      excerpt: excerpt,
      scheduleLine: _composeScheduleLine(schedule, duration),
      locationLine: location,
      durationLabel: duration,
      sessionType:
          stringValue(data['session_type']) ?? stringValue(data['type']),
      skillLevel:
          stringValue(data['skill_level']) ?? stringValue(data['skill']),
      sessionStatus: stringValue(data['status']) ?? 'published',
      participantCount: participantCount,
      maxParticipants: maxParticipants,
    );
  }

  final DateTime? startsAt;
  final String title;
  final String excerpt;
  final String? scheduleLine;
  final String? locationLine;
  final String? durationLabel;
  final String? sessionType;
  final String? skillLevel;
  final String sessionStatus;
  final int? participantCount;
  final int? maxParticipants;

  String get sessionTypeLabel {
    final raw = sessionType;
    if (raw == null || raw.isEmpty) return 'Open Play';
    return _titleCaseWords(raw);
  }

  String get skillLevelLabel {
    final raw = skillLevel;
    if (raw == null || raw.isEmpty) return 'All Levels';
    return _titleCaseWords(raw);
  }

  String get startTimeLabel {
    final startsAt = this.startsAt;
    if (startsAt == null) return 'TBD';

    final hour = startsAt.hour % 12 == 0 ? 12 : startsAt.hour % 12;
    final minute = startsAt.minute.toString().padLeft(2, '0');
    final suffix = startsAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute\n$suffix';
  }

  String get sessionStatusLabel {
    return switch (sessionStatus) {
      'in_progress' => 'In progress',
      'completed' => 'Completed',
      _ => 'Upcoming',
    };
  }

  IconData get sessionStatusIcon {
    return switch (sessionStatus) {
      'in_progress' => Icons.play_circle_fill_rounded,
      'completed' => Icons.task_alt_rounded,
      _ => Icons.calendar_month_rounded,
    };
  }

  String get rosterLabel {
    if (participantCount == null) return 'Roster pending';
    if (maxParticipants == null) return '$participantCount joined';
    return '$participantCount/$maxParticipants players';
  }

  bool isOnDate(DateTime date) {
    final startsAt = this.startsAt;
    if (startsAt == null) return false;
    return isSameDay(startsAt, date);
  }

  static List<DateTime> availableDates(List<HostedSession> sessions) {
    final seen = <String>{};
    final dates = <DateTime>[];

    for (final session in sessions) {
      final startsAt = session.startsAt;
      if (startsAt == null) continue;
      final date = dateOnly(startsAt);
      final key = '${date.year}-${date.month}-${date.day}';
      if (seen.add(key)) {
        dates.add(date);
      }
    }

    dates.sort((a, b) => a.compareTo(b));
    return List<DateTime>.unmodifiable(dates);
  }

  static Map<int, int> sessionCountByDate(List<HostedSession> sessions) {
    final countByDate = <int, int>{};

    for (final session in sessions) {
      final startsAt = session.startsAt;
      if (startsAt == null) continue;
      final stamp = dateStamp(startsAt);
      countByDate[stamp] = (countByDate[stamp] ?? 0) + 1;
    }

    return Map<int, int>.unmodifiable(countByDate);
  }

  static int compareByStartTime(HostedSession a, HostedSession b) {
    final left = a.startsAt;
    final right = b.startsAt;
    if (left == null && right == null) return a.title.compareTo(b.title);
    if (left == null) return 1;
    if (right == null) return -1;
    return left.compareTo(right);
  }

  static DateTime dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static int dateStamp(DateTime value) {
    final date = dateOnly(value);
    return date.year * 10000 + date.month * 100 + date.day;
  }

  static bool isSameDay(DateTime left, DateTime right) {
    final normalizedLeft = dateOnly(left);
    final normalizedRight = dateOnly(right);
    return normalizedLeft.year == normalizedRight.year &&
        normalizedLeft.month == normalizedRight.month &&
        normalizedLeft.day == normalizedRight.day;
  }

  static String relativeDateTitle(DateTime date) {
    final normalizedDate = dateOnly(date);
    final today = dateOnly(DateTime.now());
    final dayDelta = normalizedDate.difference(today).inDays;
    final prefix = switch (dayDelta) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => weekdayName(normalizedDate.weekday),
    };
    return '$prefix, ${normalizedDate.day} ${monthName(normalizedDate.month)} ${normalizedDate.year}';
  }

  static String weekdayShort(DateTime date) {
    return _weekdayName(date.weekday);
  }

  static String? stringValue(Object? value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static String? relationId(Object? value) {
    if (value is Map) {
      final relationValue = value[r'$id'];
      return stringValue(relationValue);
    }
    return stringValue(value);
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static DateTime? _dateTime(Object? value) {
    final raw = stringValue(value);
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  static String? _buildFallbackExcerpt(Map<String, dynamic> data) {
    final skill = stringValue(data['skill']);
    final timeLabel = stringValue(data['timeLabel']);
    final parts = <String>[?skill, ?timeLabel];
    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  static String? _composeScheduleLine(String? schedule, String? duration) {
    if (schedule == null && duration == null) return null;
    if (schedule == null) return duration;
    if (duration == null) return schedule;
    return '$schedule • $duration';
  }

  static String? _formatSessionSchedule(DateTime? startsAt) {
    if (startsAt == null) return null;

    final dayName = _weekdayName(startsAt.weekday);
    final monthName = _monthName(startsAt.month);
    final hour = startsAt.hour % 12 == 0 ? 12 : startsAt.hour % 12;
    final minute = startsAt.minute.toString().padLeft(2, '0');
    final suffix = startsAt.hour >= 12 ? 'PM' : 'AM';

    return '$dayName, ${startsAt.day} $monthName, $hour:$minute $suffix';
  }

  static String weekdayName(int weekday) => _weekdayName(weekday);

  static String monthName(int month) => _monthName(month);

  static String _weekdayName(int weekday) {
    const days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  static String _monthName(int month) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  static String? _formatSessionDuration(Object? durationValue) {
    final minutes = _int(durationValue);
    if (minutes == null || minutes <= 0) return null;

    final hours = minutes ~/ 60;
    final remainderMinutes = minutes % 60;

    if (hours == 0) return '${minutes}m';
    if (remainderMinutes == 0) return '${hours}h';
    return '${hours}h ${remainderMinutes}m';
  }

  static String _titleCaseWords(String value) {
    return value
        .trim()
        .split(RegExp(r'[\s_-]+'))
        .where((token) => token.isNotEmpty)
        .map((token) {
          if (token.length == 1) return token.toUpperCase();
          return '${token[0].toUpperCase()}${token.substring(1).toLowerCase()}';
        })
        .join(' ');
  }
}
