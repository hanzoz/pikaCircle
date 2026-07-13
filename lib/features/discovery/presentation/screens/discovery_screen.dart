import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import 'package:pikacircle/shared/widgets/empty_state_card.dart';

/// Discovery / "Find" tab — session, venue, and player search.
///
/// Placeholder for now. The session discovery list and filters will be added
/// in this feature's data/domain layers (see `docs/app workflows`).
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late final CardSwiperController _swiperController;

  final List<_DiscoverySession> _sessions = const <_DiscoverySession>[
    _DiscoverySession(
      title: 'Sunset Ladder Games',
      excerpt: 'Intermediate doubles, rotating partners every 15 minutes.',
      participantNames: <String>[
        'Amy T',
        'Jules N',
        'Ray K',
        'Miko L',
        'Tan C',
      ],
    ),
    _DiscoverySession(
      title: 'Beginner Friendly Clinic',
      excerpt: 'Coach-led drills and matchplay intro. Bring water and towel.',
      participantNames: <String>['Nora', 'Dylan', 'Ari'],
    ),
    _DiscoverySession(
      title: 'Saturday Open Play',
      excerpt: 'All levels welcome. Team balancing done on-site by host.',
      participantNames: <String>[],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _swiperController = CardSwiperController();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sessions.isEmpty) {
      return const EmptyStateCard(
        title: 'Find',
        message: 'Search and discovery will appear here.',
        icon: Icons.search_rounded,
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final availableWidth = constraints.maxWidth - 32;
        final availableHeight = constraints.maxHeight - 32;
        final swiperWidth = availableWidth > 420 ? 420.0 : availableWidth;
        final swiperHeight = availableHeight > 620 ? 620.0 : availableHeight;

        return Center(
          child: SizedBox(
            width: swiperWidth,
            height: swiperHeight,
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: _sessions.length,
              numberOfCardsDisplayed: _sessions.length < 3
                  ? _sessions.length
                  : 3,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
              scale: 0.93,
              backCardOffset: const Offset(0, 26),
              allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                horizontal: true,
                vertical: false,
              ),
              cardBuilder:
                  (
                    BuildContext context,
                    int index,
                    int horizontalThresholdPercentage,
                    int verticalThresholdPercentage,
                  ) {
                    return _DiscoverySessionCard(session: _sessions[index]);
                  },
            ),
          ),
        );
      },
    );
  }
}

class _DiscoverySessionCard extends StatelessWidget {
  const _DiscoverySessionCard({required this.session});

  final _DiscoverySession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            child: Text(
              session.title,
              style: theme.textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
            child: _ParticipantRow(participantNames: session.participantNames),
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

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participantNames});

  final List<String> participantNames;

  @override
  Widget build(BuildContext context) {
    final participantCount = participantNames.length;
    if (participantCount == 0) {
      return Text(
        'No one has joined yet',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final visibleNames = participantNames.take(3).toList(growable: false);
    final remaining = participantCount - visibleNames.length;

    return Row(
      children: <Widget>[
        SizedBox(
          width: 90,
          height: 30,
          child: Stack(
            children: <Widget>[
              for (int i = 0; i < visibleNames.length; i++)
                Positioned(
                  left: i * 22,
                  child: _AvatarChip(name: visibleNames[i]),
                ),
            ],
          ),
        ),
        if (remaining > 0)
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '+$remaining',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        Expanded(
          child: Text(
            '$participantCount joining',
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
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
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
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

class _DiscoverySession {
  const _DiscoverySession({
    required this.title,
    required this.excerpt,
    required this.participantNames,
  });

  final String title;
  final String excerpt;
  final List<String> participantNames;
}
