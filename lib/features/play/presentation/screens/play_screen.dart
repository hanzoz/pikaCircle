import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/core/constants/table_ids.dart';
import 'package:pikacircle/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pikacircle/shared/widgets/empty_state_card.dart';

final playSessionsProvider = FutureProvider.autoDispose<List<PlaySession>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null || userId.isEmpty) {
    return const <PlaySession>[];
  }

  final tables = ref.watch(appwriteTablesDbProvider);
  final config = ref.watch(appwriteConfigProvider);

  final participantRows = await tables.listRows(
    databaseId: config.databaseId,
    tableId: TableIds.sessionParticipants,
    queries: [
      Query.equal('user_id', userId),
      Query.equal('status', ['confirmed', 'checked_in', 'waitlisted']),
      Query.limit(200),
    ],
  );

  if (participantRows.rows.isEmpty) {
    return const <PlaySession>[];
  }

  final participantStatusBySessionId = <String, String>{};
  for (final row in participantRows.rows) {
    final sessionId = PlaySession.relationId(row.data['session_id']);
    final participantStatus = PlaySession.stringValue(row.data['status']);
    if (sessionId == null || participantStatus == null) {
      continue;
    }
    participantStatusBySessionId[sessionId] = participantStatus;
  }

  final sessionIds = participantStatusBySessionId.keys.toList(growable: false);
  if (sessionIds.isEmpty) {
    return const <PlaySession>[];
  }

  final sessionRows = await tables.listRows(
    databaseId: config.databaseId,
    tableId: TableIds.sessions,
    queries: [
      Query.equal(r'$id', sessionIds),
      Query.equal('status', ['published', 'in_progress', 'completed']),
      Query.orderAsc('starts_at'),
      Query.limit(200),
    ],
  );

  return sessionRows.rows
      .map(
        (row) => PlaySession.fromRow(
          row,
          participantStatus:
              participantStatusBySessionId[row.$id] ?? 'confirmed',
        ),
      )
      .toList(growable: false);
});

class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final sessionsState = ref.watch(playSessionsProvider);

    if (sessionsState.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (sessionsState.hasError) {
      return EmptyStateCard(
        title: 'Play',
        message:
            'Could not load your sessions right now. Pull to refresh later.',
        icon: Icons.sports_tennis_rounded,
      );
    }

    final sessions = sessionsState.value ?? const <PlaySession>[];
    if (sessions.isEmpty) {
      return const EmptyStateCard(
        title: 'Play',
        message: 'Sessions you are playing in will appear here.',
        icon: Icons.sports_tennis_rounded,
      );
    }

    final availableDates = PlaySession.availableDates(sessions);
    final sessionCountByDate = PlaySession.sessionCountByDate(sessions);
    final selectedDate = _resolveSelectedDate(availableDates);
    final topContentPadding =
        MediaQuery.paddingOf(context).top + kToolbarHeight + 16;
    final filteredSessions =
        sessions
            .where((session) => session.isOnDate(selectedDate))
            .toList(growable: false)
          ..sort(PlaySession.compareByStartTime);

    return RefreshIndicator.adaptive(
      onRefresh: () async {
        ref.invalidate(playSessionsProvider);
        await ref.read(playSessionsProvider.future);
      },
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, topContentPadding, 20, 120),
            children: [
              _DateFilterHeader(
                selectedDate: selectedDate,
                sessionCount: filteredSessions.length,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 102,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(2, 8, 10, 2),
                  itemCount: availableDates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final date = availableDates[index];
                    final isSelected = PlaySession.isSameDay(
                      date,
                      selectedDate,
                    );
                    return _PlayDateChip(
                      date: date,
                      sessionCount:
                          sessionCountByDate[PlaySession.dateStamp(date)] ?? 0,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              ...[
                for (
                  var index = 0;
                  index < filteredSessions.length;
                  index++
                ) ...[
                  _SessionTimelineItem(
                    session: filteredSessions[index],
                    showTopLine: index != 0,
                    showBottomLine: index != filteredSessions.length - 1,
                  ),
                  if (index != filteredSessions.length - 1)
                    const _TimelineGapConnector(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  DateTime _resolveSelectedDate(List<DateTime> availableDates) {
    if (availableDates.isEmpty) {
      return PlaySession.dateOnly(DateTime.now());
    }

    final selectedDate = _selectedDate;
    if (selectedDate != null) {
      for (final candidate in availableDates) {
        if (PlaySession.isSameDay(candidate, selectedDate)) {
          return candidate;
        }
      }
    }

    final today = PlaySession.dateOnly(DateTime.now());
    for (final candidate in availableDates) {
      if (PlaySession.isSameDay(candidate, today)) {
        return candidate;
      }
    }

    return availableDates.first;
  }
}

class _DateFilterHeader extends StatelessWidget {
  const _DateFilterHeader({
    required this.selectedDate,
    required this.sessionCount,
  });

  final DateTime selectedDate;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = PlaySession.relativeDateTitle(selectedDate);
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

class _PlayDateChip extends StatelessWidget {
  const _PlayDateChip({
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
                    PlaySession.weekdayShort(date),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(shape: BoxShape.circle),
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

class _SessionTimelineItem extends StatelessWidget {
  const _SessionTimelineItem({
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
          SizedBox(
            width: 72,
            child: Column(
              children: [
                if (showTopLine)
                  Container(
                    width: 2,
                    height: 10,
                    color: colorScheme.outlineVariant,
                  ),
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF0F1F5)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        label: session.sessionTypeLabel,
                        icon: Icons.sports_tennis_rounded,
                        foregroundColor: colorScheme.tertiary,
                        backgroundColor: colorScheme.tertiaryContainer,
                      ),
                      _StatusChip(
                        label: session.skillLevelLabel,
                        icon: Icons.bolt_rounded,
                        foregroundColor: colorScheme.secondary,
                        backgroundColor: colorScheme.secondaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    session.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (session.locationLine != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.locationLine!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    session.excerpt,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _MetaLabel(
                        icon: Icons.group_outlined,
                        label: session.rosterLabel,
                      ),
                      if (session.durationLabel != null)
                        _MetaLabel(
                          icon: Icons.timelapse_rounded,
                          label: session.durationLabel!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineGapConnector extends StatelessWidget {
  const _TimelineGapConnector();

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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class PlaySession {
  const PlaySession({
    required this.startsAt,
    required this.title,
    required this.excerpt,
    required this.scheduleLine,
    required this.locationLine,
    required this.durationLabel,
    required this.sessionType,
    required this.skillLevel,
    required this.participantStatus,
    required this.sessionStatus,
    required this.participantCount,
    required this.maxParticipants,
  });

  factory PlaySession.fromRow(
    models.Row row, {
    required String participantStatus,
  }) {
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

    return PlaySession(
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
      participantStatus: participantStatus,
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
  final String participantStatus;
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

  String get participantStatusLabel {
    return switch (participantStatus) {
      'checked_in' => 'Playing now',
      'waitlisted' => 'Waitlisted',
      _ => 'Confirmed',
    };
  }

  IconData get participantStatusIcon {
    return switch (participantStatus) {
      'checked_in' => Icons.sports_tennis_rounded,
      'waitlisted' => Icons.hourglass_top_rounded,
      _ => Icons.check_circle_rounded,
    };
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

  static List<DateTime> availableDates(List<PlaySession> sessions) {
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

  static Map<int, int> sessionCountByDate(List<PlaySession> sessions) {
    final countByDate = <int, int>{};

    for (final session in sessions) {
      final startsAt = session.startsAt;
      if (startsAt == null) continue;
      final stamp = dateStamp(startsAt);
      countByDate[stamp] = (countByDate[stamp] ?? 0) + 1;
    }

    return Map<int, int>.unmodifiable(countByDate);
  }

  static int compareByStartTime(PlaySession a, PlaySession b) {
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
