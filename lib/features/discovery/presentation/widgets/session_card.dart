part of '../screens/discovery_screen.dart';

class _DiscoverySessionCard extends StatelessWidget {
  const _DiscoverySessionCard({required this.session});

  final _DiscoverySession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduleText = _DiscoverySession.composeScheduleLine(
      session.scheduleLabel,
      session.durationLabel,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _SessionDetailsPage(session: session),
            ),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        session.title,
                        style: theme.textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _CapacityBadge(
                      confirmedCount: session.participantCount,
                      maxParticipants: session.maxParticipants,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _SessionTypeChip(label: _sessionTypeLabel),
                    _SkillLevelChip(label: session.skillLevel),
                  ],
                ),
              ),
              if (scheduleText != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          scheduleText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.place_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            session.venue,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (_shouldShowSponsorBlock) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        'Sponsored by',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session.sponsorName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_shouldShowHostRow) ...<Widget>[
                      _HostRow(
                        hostName: session.hostName,
                        hostAvatarUrl: session.hostAvatarUrl,
                        hostAvatarFileId: session.hostAvatarFileId,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _ParticipantGroups(
                      confirmedNames: session.confirmedParticipantNames,
                      confirmedAvatarUrls:
                          session.confirmedParticipantAvatarUrls,
                      confirmedAvatarFileIds:
                          session.confirmedParticipantAvatarFileIds,
                      confirmedCount: session.participantCount,
                      waitlistedNames: session.waitlistedParticipantNames,
                      waitlistedAvatarUrls:
                          session.waitlistedParticipantAvatarUrls,
                      waitlistedAvatarFileIds:
                          session.waitlistedParticipantAvatarFileIds,
                      waitlistCount: session.waitlistCount,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on _DiscoverySessionCard {
  String get _sessionTypeLabel =>
      session.hasHostId ? 'Hosted Session' : 'Open Play';
}

extension on _DiscoverySessionCard {
  bool get _shouldShowSponsorBlock {
    final sponsorName = session.sponsorName.trim();
    return sponsorName.isNotEmpty && sponsorName.toLowerCase() != 'no sponsor';
  }

  bool get _shouldShowHostRow {
    final sessionType = session.sessionType.trim().toLowerCase();
    final isOpenPlay = sessionType == 'open play';
    if (!isOpenPlay) return true;

    final hasHostName =
        session.hostName.trim().isNotEmpty &&
        session.hostName.trim().toLowerCase() != 'pikacircle';
    final hasHostAvatar =
        (session.hostAvatarUrl?.trim().isNotEmpty ?? false) ||
        (session.hostAvatarFileId?.trim().isNotEmpty ?? false);

    return hasHostName || hasHostAvatar;
  }
}

class _CapacityBadge extends StatelessWidget {
  const _CapacityBadge({
    required this.confirmedCount,
    required this.maxParticipants,
  });

  final int confirmedCount;
  final int? maxParticipants;

  @override
  Widget build(BuildContext context) {
    final label = maxParticipants == null
        ? '$confirmedCount'
        : '$confirmedCount/$maxParticipants';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _SessionTypeChip extends StatelessWidget {
  const _SessionTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.sports_tennis_rounded,
              size: 16,
              color: colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillLevelChip extends StatelessWidget {
  const _SkillLevelChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bolt_rounded,
              size: 16,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostRow extends StatelessWidget {
  const _HostRow({
    required this.hostName,
    required this.hostAvatarUrl,
    required this.hostAvatarFileId,
  });

  final String hostName;
  final String? hostAvatarUrl;
  final String? hostAvatarFileId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: <Widget>[
        SessionAvatar(
          name: hostName,
          imageUrl: hostAvatarUrl,
          avatarFileId: hostAvatarFileId,
          size: 28,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hostName,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ParticipantGroups extends StatelessWidget {
  const _ParticipantGroups({
    required this.confirmedNames,
    required this.confirmedAvatarUrls,
    required this.confirmedAvatarFileIds,
    required this.confirmedCount,
    required this.waitlistedNames,
    required this.waitlistedAvatarUrls,
    required this.waitlistedAvatarFileIds,
    required this.waitlistCount,
  });

  final List<String> confirmedNames;
  final List<String?> confirmedAvatarUrls;
  final List<String?> confirmedAvatarFileIds;
  final int confirmedCount;
  final List<String> waitlistedNames;
  final List<String?> waitlistedAvatarUrls;
  final List<String?> waitlistedAvatarFileIds;
  final int waitlistCount;

  @override
  Widget build(BuildContext context) {
    if (confirmedCount == 0 && waitlistCount == 0) {
      return Text(
        'No one has joined yet',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (confirmedCount > 0)
          _ParticipantGroupRow(
            label: 'Confirmed',
            names: confirmedNames,
            avatarUrls: confirmedAvatarUrls,
            avatarFileIds: confirmedAvatarFileIds,
            totalCount: confirmedCount,
          ),
        if (waitlistCount > 0) ...<Widget>[
          if (confirmedCount > 0) const SizedBox(height: 8),
          _ParticipantGroupRow(
            label: 'Waitlisted',
            names: waitlistedNames,
            avatarUrls: waitlistedAvatarUrls,
            avatarFileIds: waitlistedAvatarFileIds,
            totalCount: waitlistCount,
          ),
        ],
      ],
    );
  }
}

class _ParticipantGroupRow extends StatelessWidget {
  const _ParticipantGroupRow({
    required this.label,
    required this.names,
    required this.avatarUrls,
    required this.avatarFileIds,
    required this.totalCount,
  });

  final String label;
  final List<String> names;
  final List<String?> avatarUrls;
  final List<String?> avatarFileIds;
  final int totalCount;

  static const double _avatarSize = 28;
  static const double _avatarGap = 6;
  static const double _labelWidth = 84;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final availableWidth = constraints.maxWidth;
        final avatarStripWidth = (availableWidth - _labelWidth)
            .clamp(0.0, availableWidth)
            .toDouble();

        return Row(
          children: <Widget>[
            SizedBox(
              width: _labelWidth,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            SizedBox(
              width: avatarStripWidth,
              child: SessionAvatarList(
                names: names,
                avatarUrls: avatarUrls,
                avatarFileIds: avatarFileIds,
                totalCount: totalCount,
                avatarSize: _avatarSize,
                gap: _avatarGap,
                overlap: 10,
                scrollable: false,
                wrap: false,
              ),
            ),
          ],
        );
      },
    );
  }
}
