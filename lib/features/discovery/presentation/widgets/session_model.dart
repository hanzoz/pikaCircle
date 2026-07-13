part of '../screens/discovery_screen.dart';

class _DiscoverySession {
  const _DiscoverySession({
    required this.title,
    required this.excerpt,
    required this.scheduleLabel,
    required this.durationLabel,
    required this.confirmedParticipantNames,
    required this.waitlistedParticipantNames,
    required this.participantCount,
    required this.waitlistCount,
    required this.maxParticipants,
  });

  factory _DiscoverySession.fromRow(
    models.Row row, {
    List<String>? confirmedParticipantNames,
    List<String>? waitlistedParticipantNames,
    int? participantCountOverride,
    int? waitlistCountOverride,
  }) {
    final data = row.data;

    final title = stringValue(data['title']) ?? 'Untitled session';
    final scheduleLabel =
        _formatSessionSchedule(data['starts_at']) ??
        stringValue(data['timeLabel']);
    final durationLabel = _formatSessionDuration(data['session_duration']);
    final excerpt =
        stringValue(data['description']) ??
        _buildFallbackExcerpt(data) ??
        'Session details will appear soon.';

    final maxParticipants = _int(data['max_participants']);
    final remainingSlots = _int(data['remainingSlots']);
    final derivedParticipantCount =
        maxParticipants == null || remainingSlots == null
        ? 0
        : (maxParticipants - remainingSlots).clamp(0, maxParticipants);
    final resolvedParticipantCount =
        participantCountOverride ?? derivedParticipantCount;
    final resolvedWaitlistCount = waitlistCountOverride ?? 0;
    final resolvedConfirmedNames = confirmedParticipantNames == null
        ? const <String>[]
        : List<String>.unmodifiable(confirmedParticipantNames);
    final resolvedWaitlistedNames = waitlistedParticipantNames == null
        ? const <String>[]
        : List<String>.unmodifiable(waitlistedParticipantNames);

    return _DiscoverySession(
      title: title,
      excerpt: excerpt,
      scheduleLabel: scheduleLabel,
      durationLabel: durationLabel,
      confirmedParticipantNames: resolvedConfirmedNames,
      waitlistedParticipantNames: resolvedWaitlistedNames,
      participantCount: resolvedParticipantCount,
      waitlistCount: resolvedWaitlistCount,
      maxParticipants: maxParticipants,
    );
  }

  final String title;
  final String excerpt;
  final String? scheduleLabel;
  final String? durationLabel;
  final List<String> confirmedParticipantNames;
  final List<String> waitlistedParticipantNames;
  final int participantCount;
  final int waitlistCount;
  final int? maxParticipants;

  static String? composeScheduleLine(String? schedule, String? duration) {
    if (schedule == null && duration == null) return null;
    if (schedule == null) return duration;
    if (duration == null) return schedule;
    return '$schedule • $duration';
  }

  static String? _buildFallbackExcerpt(Map<String, dynamic> data) {
    final venue = stringValue(data['venue']);
    final timeLabel = stringValue(data['timeLabel']);
    final skill = stringValue(data['skill']);

    final parts = <String>[?venue, ?timeLabel, ?skill];

    if (parts.isEmpty) return null;
    return parts.join(' • ');
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

  static String? _formatSessionSchedule(Object? startsAt) {
    final raw = stringValue(startsAt);
    if (raw == null) return null;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;

    final local = parsed.toLocal();
    final dayName = _weekdayName(local.weekday);
    final monthName = _monthName(local.month);
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';

    return '$dayName, ${local.day} $monthName, $hour:$minute $suffix';
  }

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
}
