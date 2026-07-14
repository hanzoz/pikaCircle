part of '../screens/discovery_screen.dart';

class _SessionDetailsPage extends StatelessWidget {
  const _SessionDetailsPage({required this.session});

  final _DiscoverySession session;

  @override
  Widget build(BuildContext context) {
    return SessionDetailsPage(data: _toCommonData(session));
  }

  SessionDetailsData _toCommonData(_DiscoverySession source) {
    return SessionDetailsData(
      title: source.title,
      description: source.description,
      hostName: source.hostName,
      dateLabel: source.dateLabel,
      timeLabel: source.timeLabel,
      durationLabel: source.durationLabel ?? 'TBA',
      sessionType: source.sessionType,
      skillLevel: source.skillLevel,
      sponsorName: source.sponsorName,
      venue: source.venue,
      location: source.location,
      creditCost: source.creditCost,
      refundAvailable: source.refundAvailable,
      refundWindowLabel: source.refundWindowLabel,
      confirmedParticipantNames: source.confirmedParticipantNames,
      confirmedParticipantCount: source.participantCount,
      waitlistedParticipantNames: source.waitlistedParticipantNames,
      waitlistCount: source.waitlistCount,
      hostSkillLevel: source.hostSkillLevel,
      hostSkillRating: source.hostSkillRating,
    );
  }
}
