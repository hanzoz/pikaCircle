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

    return DecoratedBox(
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
          const _PlaceholderImage(),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              session.excerpt,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: _ParticipantGroups(
              confirmedNames: session.confirmedParticipantNames,
              confirmedCount: session.participantCount,
              waitlistedNames: session.waitlistedParticipantNames,
              waitlistCount: session.waitlistCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF92A5FF), Color(0xFF64D8CB)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.white, size: 44),
        ),
      ),
    );
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

class _ParticipantGroups extends StatelessWidget {
  const _ParticipantGroups({
    required this.confirmedNames,
    required this.confirmedCount,
    required this.waitlistedNames,
    required this.waitlistCount,
  });

  final List<String> confirmedNames;
  final int confirmedCount;
  final List<String> waitlistedNames;
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
            totalCount: confirmedCount,
          ),
        if (waitlistCount > 0) ...<Widget>[
          if (confirmedCount > 0) const SizedBox(height: 8),
          _ParticipantGroupRow(
            label: 'Waitlisted',
            names: waitlistedNames,
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
    required this.totalCount,
  });

  final String label;
  final List<String> names;
  final int totalCount;

  static const double _avatarRadius = 14;
  static const double _avatarDiameter = _avatarRadius * 2;
  static const double _avatarStep = 22;
  static const double _avatarStripHeight = 28;
  static const double _labelWidth = 84;
  static const double _minStripWidth = 68;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final availableWidth = constraints.maxWidth;
        final avatarStripWidth = (availableWidth - _labelWidth).clamp(
          _minStripWidth,
          availableWidth,
        );

        final maxVisible = _maxAvatarsForWidth(avatarStripWidth);
        final visibleCount = totalCount < maxVisible ? totalCount : maxVisible;
        final knownVisible = names.length < visibleCount
            ? names.length
            : visibleCount;
        final hasOverflow = totalCount > visibleCount;
        final overflowCount = hasOverflow ? totalCount - visibleCount : 0;

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
              height: _avatarStripHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  for (int i = 0; i < knownVisible; i++)
                    Positioned(
                      left: i * _avatarStep,
                      child: _AvatarChip(name: names[i]),
                    ),
                  for (int i = knownVisible; i < visibleCount; i++)
                    Positioned(
                      left: i * _avatarStep,
                      child: const _UnknownAvatarChip(),
                    ),
                  if (hasOverflow)
                    Positioned(
                      left: (visibleCount - 1) * _avatarStep,
                      child: _OverflowAvatarChip(count: overflowCount),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  int _maxAvatarsForWidth(double width) {
    if (width <= _avatarDiameter) return 1;
    return ((width - _avatarDiameter) / _avatarStep).floor() + 1;
  }
}

class _AvatarChip extends StatelessWidget {
  const _AvatarChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    return CircleAvatar(
      radius: 14,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: CircleAvatar(
        radius: 12,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          initials,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final segments = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String token) => token.isNotEmpty)
        .toList(growable: false);

    if (segments.isEmpty) return '?';
    if (segments.length == 1) return segments.first[0].toUpperCase();
    return '${segments.first[0]}${segments.last[0]}'.toUpperCase();
  }
}

class _OverflowAvatarChip extends StatelessWidget {
  const _OverflowAvatarChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: CircleAvatar(
        radius: 12,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Text(
          '+$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _UnknownAvatarChip extends StatelessWidget {
  const _UnknownAvatarChip();

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: CircleAvatar(
        radius: 12,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.person_outline_rounded,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
