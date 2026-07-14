part of '../screens/discovery_screen.dart';

class _DiscoverySession {
  const _DiscoverySession({
    required this.title,
    required this.excerpt,
    required this.description,
    required this.scheduleLabel,
    required this.dateLabel,
    required this.timeLabel,
    required this.durationLabel,
    required this.sessionType,
    required this.skillLevel,
    required this.sponsorName,
    required this.hostName,
    required this.hostSkillLevel,
    required this.hostSkillRating,
    required this.venue,
    required this.location,
    required this.creditCost,
    required this.refundAvailable,
    required this.refundWindowLabel,
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
    String? hostNameOverride,
    String? hostSkillLevelOverride,
    double? hostSkillRatingOverride,
  }) {
    final data = row.data;

    final title = stringValue(data['title']) ?? 'Untitled session';
    final scheduleLabel =
        _formatSessionSchedule(data['starts_at']) ??
        stringValue(data['timeLabel']);
    final durationLabel = _formatSessionDuration(data['session_duration']);
    final description =
        stringValue(data['description']) ??
        _buildFallbackExcerpt(data) ??
        'Session details will appear soon.';
    final excerpt = description;
    final startsAt = _dateTimeValue(data['starts_at']);
    final dateLabel = startsAt == null ? 'TBA' : _formatDate(startsAt);
    final timeLabel = startsAt == null
        ? (stringValue(data['timeLabel']) ?? 'TBA')
        : _formatTime(startsAt);
    final sessionType = _formatTokenLabel(data['session_type']) ?? 'Social';
    final skillLevel =
        _formatTokenLabel(data['skill_level']) ??
        _formatTokenLabel(data['skill']) ??
        'All levels';
    final sponsorName = stringValue(data['sponsor']) ?? 'No sponsor';
    final hostName =
        hostNameOverride ?? stringValue(data['host_name']) ?? 'Host';
    final hostSkillLevel =
        _formatTokenLabel(hostSkillLevelOverride) ?? skillLevel;
    final hostSkillRating = hostSkillRatingOverride;
    final venue = stringValue(data['venue']) ?? 'Venue TBA';
    final location = stringValue(data['location']) ?? 'Location TBA';
    final creditCost = _int(data['credit_cost']) ?? _int(data['credits']) ?? 0;
    final refundAvailable = _bool(data['refund_available']) ?? false;
    final refundWindowLabel = _formatRefundWindow(data['refund_window_hours']);

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
      description: description,
      scheduleLabel: scheduleLabel,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      durationLabel: durationLabel,
      sessionType: sessionType,
      skillLevel: skillLevel,
      sponsorName: sponsorName,
      hostName: hostName,
      hostSkillLevel: hostSkillLevel,
      hostSkillRating: hostSkillRating,
      venue: venue,
      location: location,
      creditCost: creditCost,
      refundAvailable: refundAvailable,
      refundWindowLabel: refundWindowLabel,
      confirmedParticipantNames: resolvedConfirmedNames,
      waitlistedParticipantNames: resolvedWaitlistedNames,
      participantCount: resolvedParticipantCount,
      waitlistCount: resolvedWaitlistCount,
      maxParticipants: maxParticipants,
    );
  }

  final String title;
  final String excerpt;
  final String description;
  final String? scheduleLabel;
  final String dateLabel;
  final String timeLabel;
  final String? durationLabel;
  final String sessionType;
  final String skillLevel;
  final String sponsorName;
  final String hostName;
  final String hostSkillLevel;
  final double? hostSkillRating;
  final String venue;
  final String location;
  final int creditCost;
  final bool refundAvailable;
  final String refundWindowLabel;
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

  static bool? _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return null;
  }

  static double? doubleValue(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static DateTime? _dateTimeValue(Object? value) {
    final raw = stringValue(value);
    if (raw == null) return null;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return parsed.toLocal();
  }

  static String? _formatSessionSchedule(Object? startsAt) {
    final local = _dateTimeValue(startsAt);
    if (local == null) return null;

    final dayName = _weekdayName(local.weekday);
    final monthName = _monthName(local.month);
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';

    return '$dayName, ${local.day} $monthName, $hour:$minute $suffix';
  }

  static String _formatDate(DateTime local) {
    final dayName = _weekdayName(local.weekday);
    final monthName = _monthName(local.month);
    return '$dayName, ${local.day} $monthName ${local.year}';
  }

  static String _formatTime(DateTime local) {
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  static String? _formatTokenLabel(Object? value) {
    final raw = stringValue(value);
    if (raw == null) return null;

    final normalized = raw.trim().toLowerCase().replaceAll('_', ' ');
    if (normalized.isEmpty) return null;

    return normalized
        .split(' ')
        .where((token) => token.isNotEmpty)
        .map(
          (token) =>
              '${token[0].toUpperCase()}${token.length > 1 ? token.substring(1) : ''}',
        )
        .join(' ');
  }

  static String _formatRefundWindow(Object? value) {
    final hours = _int(value);
    if (hours == null || hours <= 0) {
      return 'No refund window';
    }
    if (hours == 1) {
      return '1 hour before start';
    }
    return '$hours hours before start';
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
