import 'package:flutter/material.dart';
import 'package:pikacircle/features/play/presentation/screens/play_screen.dart';
import 'package:pikacircle/shared/widgets/session_details_page.dart';
import 'package:pikacircle/shared/widgets/session_info_card.dart';

class PlaySessionCard extends StatelessWidget {
  const PlaySessionCard({super.key, required this.session});

  final PlaySession session;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SessionDetailsPage(data: _toCommonData()),
            ),
          );
        },
        child: SessionInfoCard(
          title: session.title,
          excerpt: session.excerpt,
          sessionTypeLabel: session.sessionTypeLabel,
          skillLevelLabel: session.skillLevelLabel,
          rosterLabel: session.rosterLabel,
          locationLine: session.locationLine,
          durationLabel: session.durationLabel,
        ),
      ),
    );
  }

  SessionDetailsData _toCommonData() {
    final startsAt = session.startsAt;
    return SessionDetailsData(
      title: session.title,
      description: session.excerpt,
      hostName: session.hostName,
      dateLabel: startsAt == null ? 'TBA' : _formatDate(startsAt),
      timeLabel: startsAt == null ? 'TBA' : _formatTime(startsAt),
      durationLabel: session.durationLabel ?? 'TBA',
      sessionType: session.sessionTypeLabel,
      skillLevel: session.skillLevelLabel,
      sponsorName: session.sponsorName,
      venue: session.venue,
      location: session.location,
      creditCost: session.creditCost,
      refundAvailable: session.refundAvailable,
      refundWindowLabel: session.refundWindowLabel,
      confirmedParticipantNames: session.confirmedParticipantNames,
      confirmedParticipantCount: session.participantCount ?? 0,
      waitlistedParticipantNames: session.waitlistedParticipantNames,
      waitlistCount: session.waitlistCount,
      confirmedParticipantAvatarUrls: session.confirmedParticipantAvatarUrls,
      confirmedParticipantAvatarFileIds:
          session.confirmedParticipantAvatarFileIds,
      waitlistedParticipantAvatarUrls: session.waitlistedParticipantAvatarUrls,
      waitlistedParticipantAvatarFileIds:
          session.waitlistedParticipantAvatarFileIds,
      hostAvatarUrl: session.hostAvatarUrl,
      hostAvatarFileId: session.hostAvatarFileId,
      hostSkillLevel: session.hostSkillLevelLabel,
      hostSkillRating: session.hostSkillRating,
    );
  }

  String _formatDate(DateTime local) {
    const weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
    return '${weekdays[local.weekday - 1]}, ${local.day} ${months[local.month - 1]} ${local.year}';
  }

  String _formatTime(DateTime local) {
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}
