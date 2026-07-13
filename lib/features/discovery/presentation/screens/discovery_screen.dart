import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/core/constants/table_ids.dart';
import 'package:pikacircle/shared/widgets/empty_state_card.dart';

part '../widgets/session_card.dart';
part '../widgets/session_model.dart';

/// Discovery / "Find" tab — session, venue, and player search.
///
/// Loads published sessions from Appwrite TablesDB and shows them as swipeable
/// cards.
final discoverySessionsProvider =
    FutureProvider.autoDispose<List<_DiscoverySession>>((ref) async {
      final tables = ref.watch(appwriteTablesDbProvider);
      final config = ref.watch(appwriteConfigProvider);

      final sessionRows = await tables.listRows(
        databaseId: config.databaseId,
        tableId: TableIds.sessions,
        queries: [
          Query.equal('status', 'published'),
          Query.orderAsc('starts_at'),
          Query.limit(40),
        ],
      );

      if (sessionRows.rows.isEmpty) {
        return const <_DiscoverySession>[];
      }

      final sessionIds = sessionRows.rows
          .map((row) => row.$id)
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      final Map<String, List<String>> confirmedNamesBySession =
          <String, List<String>>{};
      final Map<String, List<String>> waitlistedNamesBySession =
          <String, List<String>>{};
      final Map<String, int> joiningCountBySession = <String, int>{};
      final Map<String, int> waitlistCountBySession = <String, int>{};

      try {
        final participantRows = await tables.listRows(
          databaseId: config.databaseId,
          tableId: TableIds.sessionParticipants,
          queries: [
            Query.equal('session_id', sessionIds),
            Query.equal('status', ['confirmed', 'checked_in', 'waitlisted']),
            Query.limit(500),
          ],
        );

        final userIds = participantRows.rows
            .map((row) => _DiscoverySession.relationId(row.data['user_id']))
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList(growable: false);

        final Map<String, String> userNameById = <String, String>{};

        if (userIds.isNotEmpty) {
          try {
            final userRows = await tables.listRows(
              databaseId: config.databaseId,
              tableId: TableIds.users,
              queries: [Query.equal(r'$id', userIds), Query.limit(500)],
            );

            for (final row in userRows.rows) {
              final name = _DiscoverySession.stringValue(row.data['name']);
              if (name != null) {
                userNameById[row.$id] = name;
              }
            }
          } on AppwriteException {
            // If profile rows are not readable for discovery, keep count-only UI.
          }
        }

        for (final row in participantRows.rows) {
          final data = row.data;
          final sessionId = _DiscoverySession.relationId(data['session_id']);
          if (sessionId == null) continue;

          final userId = _DiscoverySession.relationId(data['user_id']);
          final participantName = userId == null ? null : userNameById[userId];

          final status = _DiscoverySession.stringValue(data['status']);
          final isWaitlisted = status == 'waitlisted';

          if (isWaitlisted) {
            waitlistCountBySession[sessionId] =
                (waitlistCountBySession[sessionId] ?? 0) + 1;

            if (participantName != null) {
              final names = waitlistedNamesBySession.putIfAbsent(
                sessionId,
                () => <String>[],
              );
              names.add(participantName);
            }
            continue;
          }

          joiningCountBySession[sessionId] =
              (joiningCountBySession[sessionId] ?? 0) + 1;

          if (participantName == null) continue;

          final names = confirmedNamesBySession.putIfAbsent(
            sessionId,
            () => <String>[],
          );
          names.add(participantName);
        }
      } on AppwriteException {
        // If participants query is blocked/unavailable, fall back to session-only data.
      }

      return sessionRows.rows
          .map((row) {
            return _DiscoverySession.fromRow(
              row,
              confirmedParticipantNames: confirmedNamesBySession[row.$id],
              waitlistedParticipantNames: waitlistedNamesBySession[row.$id],
              participantCountOverride: joiningCountBySession[row.$id],
              waitlistCountOverride: waitlistCountBySession[row.$id],
            );
          })
          .toList(growable: false);
    });

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  late final CardSwiperController _swiperController;

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
    final sessionsState = ref.watch(discoverySessionsProvider);

    if (sessionsState.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (sessionsState.hasError) {
      return EmptyStateCard(
        title: 'Find',
        message: 'Could not load sessions right now. Pull to refresh later.',
        icon: Icons.search_off_rounded,
      );
    }

    final sessions = sessionsState.value ?? const <_DiscoverySession>[];

    if (sessions.isEmpty) {
      return const EmptyStateCard(
        title: 'Find',
        message: 'No published sessions yet.',
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
              cardsCount: sessions.length,
              numberOfCardsDisplayed: sessions.length < 3 ? sessions.length : 3,
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
                    return _DiscoverySessionCard(session: sessions[index]);
                  },
            ),
          ),
        );
      },
    );
  }
}
