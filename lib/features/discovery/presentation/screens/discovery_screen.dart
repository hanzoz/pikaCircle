import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pikacircle/core/appwrite/appwrite_providers.dart';
import 'package:pikacircle/core/constants/table_ids.dart';
import 'package:pikacircle/features/shell/presentation/controllers/shell_controller.dart';
import 'package:pikacircle/shared/widgets/empty_state_card.dart';
import 'package:pikacircle/shared/widgets/session_avatar_list.dart';
import 'package:pikacircle/shared/widgets/session_details_page.dart';

part '../widgets/session_card.dart';
part '../widgets/session_details_page.dart';
part '../widgets/session_model.dart';

/// Discovery / "Find" tab — session, venue, and player search.
///
/// Loads published sessions from Appwrite TablesDB and shows them as swipeable
/// cards.
final discoverySessionsProvider = FutureProvider.autoDispose<List<_DiscoverySession>>((
  ref,
) async {
  String rowId(models.Row row) {
    final dataId = _DiscoverySession.stringValue(row.data[r'$id']);
    if (dataId != null) return dataId;

    try {
      return row.$id;
    } catch (_) {
      return '';
    }
  }

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
      .map(rowId)
      .where((id) => id.isNotEmpty)
      .toList(growable: false);
  final hostIds = sessionRows.rows
      .map((row) => _DiscoverySession.relationId(row.data['host_id']))
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList(growable: false);

  final Map<String, List<String>> confirmedNamesBySession =
      <String, List<String>>{};
  final Map<String, List<String>> waitlistedNamesBySession =
      <String, List<String>>{};
  final Map<String, int> joiningCountBySession = <String, int>{};
  final Map<String, int> waitlistCountBySession = <String, int>{};
  final Map<String, String> userNameById = <String, String>{};
  final Map<String, String> skillLevelByUserId = <String, String>{};
  final Map<String, double> skillRatingByUserId = <String, double>{};

  final userIdsFromParticipants = <String>{};

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
        .toSet();
    userIdsFromParticipants.addAll(userIds);

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

  final allUserIds = <String>{
    ...hostIds,
    ...userIdsFromParticipants,
  }.toList(growable: false);

  if (allUserIds.isNotEmpty) {
    try {
      final userRows = await tables.listRows(
        databaseId: config.databaseId,
        tableId: TableIds.users,
        queries: [Query.equal(r'$id', allUserIds), Query.limit(500)],
      );

      for (final row in userRows.rows) {
        final name = _DiscoverySession.stringValue(row.data['name']);
        final userId = rowId(row);
        if (name != null && userId.isNotEmpty) {
          userNameById[userId] = name;
        }
      }
    } on AppwriteException {
      // If user rows are not readable, keep count-only and fallback host labels.
    }

    if (hostIds.isNotEmpty) {
      try {
        final skillRows = await tables.listRows(
          databaseId: config.databaseId,
          tableId: TableIds.skills,
          queries: [Query.equal('user_id', hostIds), Query.limit(200)],
        );

        for (final row in skillRows.rows) {
          final userId = _DiscoverySession.relationId(row.data['user_id']);
          if (userId == null) continue;

          final level = _DiscoverySession.stringValue(row.data['level']);
          final rating = _DiscoverySession.doubleValue(
            row.data['overall_skill_rating'],
          );

          if (level != null) {
            skillLevelByUserId[userId] = level;
          }
          if (rating != null) {
            skillRatingByUserId[userId] = rating;
          }
        }
      } on AppwriteException {
        // Skill table may be unreadable for some users; fallback to session values.
      }
    }
  }

  return sessionRows.rows
      .map((row) {
        final sessionId = rowId(row);
        final hostId = _DiscoverySession.relationId(row.data['host_id']);
        return _DiscoverySession.fromRow(
          row,
          confirmedParticipantNames: confirmedNamesBySession[sessionId],
          waitlistedParticipantNames: waitlistedNamesBySession[sessionId],
          participantCountOverride: joiningCountBySession[sessionId],
          waitlistCountOverride: waitlistCountBySession[sessionId],
          hostNameOverride: hostId == null ? null : userNameById[hostId],
          hostSkillLevelOverride: hostId == null
              ? null
              : skillLevelByUserId[hostId],
          hostSkillRatingOverride: hostId == null
              ? null
              : skillRatingByUserId[hostId],
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
    final searchQuery = ref.watch(
      shellControllerProvider.select((ShellState state) => state.searchQuery),
    );

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

    final filteredSessions = _filterSessionsByTitle(sessions, searchQuery);

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
            child: filteredSessions.isNotEmpty
                ? CardSwiper(
                    controller: _swiperController,
                    cardsCount: filteredSessions.length,
                    numberOfCardsDisplayed: filteredSessions.length < 3
                        ? filteredSessions.length
                        : 3,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
                    scale: 0.93,
                    backCardOffset: const Offset(0, 26),
                    allowedSwipeDirection:
                        const AllowedSwipeDirection.symmetric(
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
                          return _DiscoverySessionCard(
                            session: filteredSessions[index],
                          );
                        },
                  )
                : const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 96),
                    child: EmptyStateCard(
                      title: 'No matching sessions',
                      message:
                          'Try a different title keyword to find sessions.',
                      icon: Icons.search_off_rounded,
                    ),
                  ),
          ),
        );
      },
    );
  }

  List<_DiscoverySession> _filterSessionsByTitle(
    List<_DiscoverySession> sessions,
    String query,
  ) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return sessions;

    return sessions
        .where((_DiscoverySession session) {
          final normalizedTitle = _normalizeSearchText(session.title);
          return _titleMatchesQuery(normalizedTitle, normalizedQuery);
        })
        .toList(growable: false);
  }

  bool _titleMatchesQuery(String normalizedTitle, String normalizedQuery) {
    if (normalizedTitle.contains(normalizedQuery)) return true;
    if (_isSubsequence(normalizedQuery, normalizedTitle)) return true;

    final acronym = normalizedTitle
        .split(' ')
        .where((String token) => token.isNotEmpty)
        .map((String token) => token[0])
        .join();
    if (acronym.contains(normalizedQuery)) return true;

    return false;
  }

  bool _isSubsequence(String query, String target) {
    var queryIndex = 0;
    for (var i = 0; i < target.length && queryIndex < query.length; i++) {
      if (target[i] == query[queryIndex]) {
        queryIndex++;
      }
    }
    return queryIndex == query.length;
  }

  String _normalizeSearchText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\\s]'), ' ')
        .replaceAll(RegExp(r'\\s+'), ' ')
        .trim();
  }
}
