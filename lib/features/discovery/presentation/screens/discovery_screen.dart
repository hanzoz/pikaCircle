import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' show ExecutionMethod;
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

enum _SessionTimeFilter { morning, afternoon, night }

/// Discovery / "Find" tab — session, venue, and player search.
///
/// Loads published sessions from Appwrite TablesDB and shows them as swipeable
/// cards.
final discoverySessionsProvider = FutureProvider.autoDispose<List<_DiscoverySession>>((
  ref,
) async {
  const int maxIdsPerQuery = 100;
  final now = DateTime.now();

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
  final functions = ref.watch(appwriteFunctionsProvider);
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

  final visibleSessionRows = sessionRows.rows
      .where((row) {
        final startsAt = _DiscoverySession._dateTimeValue(
          row.data['starts_at'],
        );
        if (startsAt == null) {
          return false;
        }

        final durationMinutes = _DiscoverySession._int(
          row.data['session_duration'],
        );
        if (durationMinutes == null || durationMinutes <= 0) {
          return startsAt.isAfter(now);
        }

        final endsAt = startsAt.add(Duration(minutes: durationMinutes));
        return endsAt.isAfter(now);
      })
      .toList(growable: false);

  if (visibleSessionRows.isEmpty) {
    return const <_DiscoverySession>[];
  }

  final sessionIds = visibleSessionRows
      .map(rowId)
      .where((id) => id.isNotEmpty)
      .toList(growable: false);
  final hostIds = visibleSessionRows
      .map((row) => _DiscoverySession.relationId(row.data['host_id']))
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList(growable: false);

  final Map<String, List<String>> confirmedNamesBySession =
      <String, List<String>>{};
  final Map<String, List<String>> waitlistedNamesBySession =
      <String, List<String>>{};
  final Map<String, List<String?>> confirmedAvatarsBySession =
      <String, List<String?>>{};
  final Map<String, List<String?>> confirmedAvatarFileIdsBySession =
      <String, List<String?>>{};
  final Map<String, List<String?>> waitlistedAvatarsBySession =
      <String, List<String?>>{};
  final Map<String, List<String?>> waitlistedAvatarFileIdsBySession =
      <String, List<String?>>{};
  final Map<String, int> joiningCountBySession = <String, int>{};
  final Map<String, int> waitlistCountBySession = <String, int>{};
  final Map<String, String> userNameById = <String, String>{};
  final Map<String, String> avatarByUserId = <String, String>{};
  final Map<String, String> avatarFileIdByUserId = <String, String>{};
  final Map<String, String> skillLevelByUserId = <String, String>{};
  final Map<String, double> skillRatingByUserId = <String, double>{};

  final userIdsFromParticipants = <String>{};
  var participantRows = const <models.Row>[];
  final Map<String, List<String>> relationNamesBySession =
      <String, List<String>>{};
  final Map<String, List<String>> relationWaitlistedNamesBySession =
      <String, List<String>>{};
  final Map<String, List<String?>> relationAvatarsBySession =
      <String, List<String?>>{};
  final Map<String, List<String?>> relationAvatarFileIdsBySession =
      <String, List<String?>>{};
  final Map<String, List<String?>> relationWaitlistedAvatarsBySession =
      <String, List<String?>>{};
  final Map<String, List<String?>> relationWaitlistedAvatarFileIdsBySession =
      <String, List<String?>>{};

  try {
    final participantsResponse = await tables.listRows(
      databaseId: config.databaseId,
      tableId: TableIds.sessionParticipants,
      queries: [
        Query.equal('session_id', sessionIds),
        Query.equal('status', ['confirmed', 'checked_in', 'waitlisted']),
        Query.limit(500),
      ],
    );
    participantRows = participantsResponse.rows;

    final userIds = participantRows
        .map((row) => _DiscoverySession.relationId(row.data['user_id']))
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    userIdsFromParticipants.addAll(userIds);

    for (final row in participantRows) {
      final data = row.data;
      final sessionId = _DiscoverySession.relationId(data['session_id']);
      if (sessionId == null) continue;

      final relationUser = data['user_id'];
      String? relationName;
      String? relationAvatar;
      String? relationAvatarFileId;
      if (relationUser is Map) {
        relationName = _DiscoverySession.stringValue(relationUser['name']);
        relationAvatar = _DiscoverySession.stringValue(
          relationUser['profile_picture_url'],
        );
        relationAvatarFileId = _DiscoverySession.stringValue(
          relationUser['profile_picture_file_id'],
        );
      }

      final status = _DiscoverySession.stringValue(data['status']);
      final isWaitlisted = status == 'waitlisted';

      if (isWaitlisted) {
        waitlistCountBySession[sessionId] =
            (waitlistCountBySession[sessionId] ?? 0) + 1;

        if (relationName != null) {
          final names = relationWaitlistedNamesBySession.putIfAbsent(
            sessionId,
            () => <String>[],
          );
          names.add(relationName);
          final avatars = relationWaitlistedAvatarsBySession.putIfAbsent(
            sessionId,
            () => <String?>[],
          );
          avatars.add(relationAvatar);
          final avatarFileIds = relationWaitlistedAvatarFileIdsBySession
              .putIfAbsent(sessionId, () => <String?>[]);
          avatarFileIds.add(relationAvatarFileId);
        }
        continue;
      }

      joiningCountBySession[sessionId] =
          (joiningCountBySession[sessionId] ?? 0) + 1;

      if (relationName != null) {
        final names = relationNamesBySession.putIfAbsent(
          sessionId,
          () => <String>[],
        );
        names.add(relationName);
        final avatars = relationAvatarsBySession.putIfAbsent(
          sessionId,
          () => <String?>[],
        );
        avatars.add(relationAvatar);
        final avatarFileIds = relationAvatarFileIdsBySession.putIfAbsent(
          sessionId,
          () => <String?>[],
        );
        avatarFileIds.add(relationAvatarFileId);
      }
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
      final execution = await functions.createExecution(
        functionId: config.userPublicProfilesFunctionId,
        body: jsonEncode(<String, Object?>{'userIds': allUserIds}),
        method: ExecutionMethod.pOST,
        headers: const {'content-type': 'application/json'},
      );

      final body = _decodeExecutionBody(execution.responseBody);
      if (execution.responseStatusCode >= 400) {
        final message =
            body['error']?.toString() ??
            'Could not load participant display names.';
        throw AppwriteException(message, execution.responseStatusCode);
      }

      final namesByUserId = body['namesByUserId'];
      if (namesByUserId is Map) {
        for (final entry in namesByUserId.entries) {
          final userId = entry.key.toString().trim();
          final name = entry.value?.toString().trim();
          if (userId.isNotEmpty && name != null && name.isNotEmpty) {
            userNameById[userId] = name;
          }
        }
      }

      final avatarUrlById = body['avatarByUserId'];
      if (avatarUrlById is Map) {
        for (final entry in avatarUrlById.entries) {
          final userId = entry.key.toString().trim();
          final avatar = entry.value?.toString().trim();
          if (userId.isNotEmpty && avatar != null && avatar.isNotEmpty) {
            avatarByUserId[userId] = avatar;
          }
        }
      }

      final avatarFileIdMap = body['avatarFileIdByUserId'];
      if (avatarFileIdMap is Map) {
        for (final entry in avatarFileIdMap.entries) {
          final userId = entry.key.toString().trim();
          final avatarFileId = entry.value?.toString().trim();
          if (userId.isNotEmpty &&
              avatarFileId != null &&
              avatarFileId.isNotEmpty) {
            avatarFileIdByUserId[userId] = avatarFileId;
          }
        }
      }
    } on AppwriteException {
      // Fall through to the direct table backfill below.
    }

    if (userNameById.length < allUserIds.length ||
        avatarByUserId.length < allUserIds.length ||
        avatarFileIdByUserId.length < allUserIds.length) {
      try {
        for (
          var start = 0;
          start < allUserIds.length;
          start += maxIdsPerQuery
        ) {
          final end = (start + maxIdsPerQuery).clamp(0, allUserIds.length);
          final batch = allUserIds.sublist(start, end);

          final userRows = await tables.listRows(
            databaseId: config.databaseId,
            tableId: TableIds.users,
            queries: [Query.equal(r'$id', batch), Query.limit(maxIdsPerQuery)],
          );

          for (final row in userRows.rows) {
            final name = _DiscoverySession.stringValue(row.data['name']);
            final avatar = _DiscoverySession.stringValue(
              row.data['profile_picture_url'],
            );
            final avatarFileId = _DiscoverySession.stringValue(
              row.data['profile_picture_file_id'],
            );
            final userId = rowId(row);
            if (name != null && userId.isNotEmpty) {
              userNameById[userId] = name;
            }
            if (avatar != null && userId.isNotEmpty) {
              avatarByUserId[userId] = avatar;
            }
            if (avatarFileId != null && userId.isNotEmpty) {
              avatarFileIdByUserId[userId] = avatarFileId;
            }
          }
        }
      } on AppwriteException {
        // If user rows are not readable, keep count-only and relation-name fallback.
      }
    }

    for (final row in participantRows) {
      final data = row.data;
      final sessionId = _DiscoverySession.relationId(data['session_id']);
      if (sessionId == null) continue;

      final userId = _DiscoverySession.relationId(data['user_id']);
      final participantName = userId == null ? null : userNameById[userId];
      if (participantName == null) continue;

      final status = _DiscoverySession.stringValue(data['status']);
      final isWaitlisted = status == 'waitlisted';

      final targetMap = isWaitlisted
          ? waitlistedNamesBySession
          : confirmedNamesBySession;
      final names = targetMap.putIfAbsent(sessionId, () => <String>[]);
      names.add(participantName);

      final targetAvatarMap = isWaitlisted
          ? waitlistedAvatarsBySession
          : confirmedAvatarsBySession;
      final avatars = targetAvatarMap.putIfAbsent(sessionId, () => <String?>[]);
      avatars.add(avatarByUserId[userId]);

      final targetAvatarFileIdMap = isWaitlisted
          ? waitlistedAvatarFileIdsBySession
          : confirmedAvatarFileIdsBySession;
      final avatarFileIds = targetAvatarFileIdMap.putIfAbsent(
        sessionId,
        () => <String?>[],
      );
      avatarFileIds.add(avatarFileIdByUserId[userId]);
    }

    for (final entry in relationNamesBySession.entries) {
      if ((confirmedNamesBySession[entry.key] ?? const <String>[]).isNotEmpty) {
        continue;
      }
      confirmedNamesBySession[entry.key] = List<String>.from(entry.value);
      confirmedAvatarsBySession[entry.key] = List<String?>.from(
        relationAvatarsBySession[entry.key] ?? const <String?>[],
      );
      confirmedAvatarFileIdsBySession[entry.key] = List<String?>.from(
        relationAvatarFileIdsBySession[entry.key] ?? const <String?>[],
      );
    }
    for (final entry in relationWaitlistedNamesBySession.entries) {
      if ((waitlistedNamesBySession[entry.key] ?? const <String>[])
          .isNotEmpty) {
        continue;
      }
      waitlistedNamesBySession[entry.key] = List<String>.from(entry.value);
      waitlistedAvatarsBySession[entry.key] = List<String?>.from(
        relationWaitlistedAvatarsBySession[entry.key] ?? const <String?>[],
      );
      waitlistedAvatarFileIdsBySession[entry.key] = List<String?>.from(
        relationWaitlistedAvatarFileIdsBySession[entry.key] ??
            const <String?>[],
      );
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

  // Participant rosters are owner-only readable, so a browsing user cannot read
  // other people's session_participants rows directly. Resolve the public
  // roster (names + avatars) through the admin-key roster function and let it
  // authoritatively populate the confirmed/waitlisted maps and counts. Setting
  // the counts to the resolved roster lengths also prevents phantom placeholder
  // avatars that a derived participant count would otherwise produce.
  try {
    final execution = await functions.createExecution(
      functionId: config.sessionPublicRosterFunctionId,
      body: jsonEncode(<String, Object?>{'sessionIds': sessionIds}),
      method: ExecutionMethod.pOST,
      headers: const {'content-type': 'application/json'},
    );

    final body = _decodeExecutionBody(execution.responseBody);
    if (execution.responseStatusCode < 400) {
      final rosterBySession = body['rosterBySession'];
      if (rosterBySession is Map) {
        for (final entry in rosterBySession.entries) {
          final sessionId = entry.key.toString().trim();
          final roster = entry.value;
          if (sessionId.isEmpty || roster is! Map) continue;

          final confirmed = _rosterEntries(roster['confirmed']);
          final waitlisted = _rosterEntries(roster['waitlisted']);

          confirmedNamesBySession[sessionId] = confirmed.names;
          confirmedAvatarsBySession[sessionId] = confirmed.avatarUrls;
          confirmedAvatarFileIdsBySession[sessionId] = confirmed.avatarFileIds;
          joiningCountBySession[sessionId] = confirmed.names.length;

          waitlistedNamesBySession[sessionId] = waitlisted.names;
          waitlistedAvatarsBySession[sessionId] = waitlisted.avatarUrls;
          waitlistedAvatarFileIdsBySession[sessionId] =
              waitlisted.avatarFileIds;
          waitlistCountBySession[sessionId] = waitlisted.names.length;
        }
      }
    }
  } on AppwriteException {
    // Roster unavailable; fall back to whatever the direct queries resolved.
  }

  return visibleSessionRows
      .map((row) {
        final sessionId = rowId(row);
        final hostId = _DiscoverySession.relationId(row.data['host_id']);
        return _DiscoverySession.fromRow(
          row,
          confirmedParticipantNames: confirmedNamesBySession[sessionId],
          waitlistedParticipantNames: waitlistedNamesBySession[sessionId],
          confirmedParticipantAvatarUrls: confirmedAvatarsBySession[sessionId],
          confirmedParticipantAvatarFileIds:
              confirmedAvatarFileIdsBySession[sessionId],
          waitlistedParticipantAvatarUrls:
              waitlistedAvatarsBySession[sessionId],
          waitlistedParticipantAvatarFileIds:
              waitlistedAvatarFileIdsBySession[sessionId],
          participantCountOverride: joiningCountBySession[sessionId],
          waitlistCountOverride: waitlistCountBySession[sessionId],
          hasHostId: hostId != null,
          hostNameOverride: hostId == null ? null : userNameById[hostId],
          hostAvatarOverride: hostId == null ? null : avatarByUserId[hostId],
          hostAvatarFileIdOverride: hostId == null
              ? null
              : avatarFileIdByUserId[hostId],
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

Map<String, dynamic> _decodeExecutionBody(String responseBody) {
  if (responseBody.isEmpty) return const {};
  final decoded = jsonDecode(responseBody);
  if (decoded is Map<String, dynamic>) return decoded;
  return const {};
}

/// Parses a roster array (`confirmed`/`waitlisted`) from the session roster
/// function into aligned name/avatar-url/avatar-file-id lists. Each entry
/// contributes exactly one slot so the avatar list never renders phantom
/// placeholders. A missing name falls back to an empty string (initials blank);
/// the avatar image still renders from its URL or file id when present.
({List<String> names, List<String?> avatarUrls, List<String?> avatarFileIds})
_rosterEntries(Object? value) {
  final names = <String>[];
  final avatarUrls = <String?>[];
  final avatarFileIds = <String?>[];
  if (value is List) {
    for (final item in value) {
      if (item is! Map) continue;
      names.add(_DiscoverySession.stringValue(item['name']) ?? '');
      avatarUrls.add(_DiscoverySession.stringValue(item['avatarUrl']));
      avatarFileIds.add(_DiscoverySession.stringValue(item['avatarFileId']));
    }
  }
  return (names: names, avatarUrls: avatarUrls, avatarFileIds: avatarFileIds);
}

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  late final CardSwiperController _swiperController;
  final Set<_SessionTimeFilter> _selectedTimeFilters = <_SessionTimeFilter>{
    _SessionTimeFilter.morning,
    _SessionTimeFilter.afternoon,
    _SessionTimeFilter.night,
  };
  bool _notFullOnly = false;

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

    final filteredSessions = _filterSessions(
      sessions,
      searchQuery,
      _selectedTimeFilters,
      _notFullOnly,
    );

    return SafeArea(
      top: true,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: _openFiltersSheet,
                icon: const Icon(Icons.tune_rounded),
                label: Text(_hasActiveFilters ? 'Filters' : 'Filter'),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final availableWidth = constraints.maxWidth - 32;
                final availableHeight = constraints.maxHeight - 32;
                final swiperWidth = availableWidth > 420
                    ? 420.0
                    : availableWidth;
                final swiperHeight = availableHeight > 540
                    ? 540.0
                    : availableHeight;

                return Align(
                  alignment: Alignment.topCenter,
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
                                  'Try a different title keyword or time filter.',
                              icon: Icons.search_off_rounded,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_DiscoverySession> _filterSessions(
    List<_DiscoverySession> sessions,
    String query,
    Set<_SessionTimeFilter> timeFilters,
    bool notFullOnly,
  ) {
    final normalizedQuery = _normalizeSearchText(query);
    return sessions
        .where((_DiscoverySession session) {
          final matchesTitle =
              normalizedQuery.isEmpty ||
              _titleMatchesQuery(
                _normalizeSearchText(session.title),
                normalizedQuery,
              );
          final matchesTime = _matchesTimeFilter(session, timeFilters);
          final matchesStatus = !notFullOnly || _matchesNotFull(session);
          return matchesTitle && matchesTime && matchesStatus;
        })
        .toList(growable: false);
  }

  bool _matchesNotFull(_DiscoverySession session) {
    final maxParticipants = session.maxParticipants;
    if (maxParticipants == null) return true;
    return session.participantCount < maxParticipants;
  }

  bool _matchesTimeFilter(
    _DiscoverySession session,
    Set<_SessionTimeFilter> filters,
  ) {
    final startsAt = session.startsAt;
    if (startsAt == null) return false;

    if (filters.isEmpty) return true;

    final hour = startsAt.hour;
    final isMorning = hour >= 5 && hour < 12;
    final isAfternoon = hour >= 12 && hour < 17;
    final isNight = hour >= 17 || hour < 5;

    return (filters.contains(_SessionTimeFilter.morning) && isMorning) ||
        (filters.contains(_SessionTimeFilter.afternoon) && isAfternoon) ||
        (filters.contains(_SessionTimeFilter.night) && isNight);
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

  bool get _hasActiveFilters =>
      _selectedTimeFilters.length != _SessionTimeFilter.values.length ||
      _notFullOnly;

  void _openFiltersSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final tempTimeFilters = <_SessionTimeFilter>{..._selectedTimeFilters};
        var tempNotFullOnly = _notFullOnly;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            void toggleTimeFilter(_SessionTimeFilter filter) {
              setModalState(() {
                if (tempTimeFilters.contains(filter)) {
                  tempTimeFilters.remove(filter);
                } else {
                  tempTimeFilters.add(filter);
                }
              });
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Filter sessions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Time',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _TimeFilterChip(
                          label: 'Morning',
                          selected: tempTimeFilters.contains(
                            _SessionTimeFilter.morning,
                          ),
                          onSelected: () {
                            toggleTimeFilter(_SessionTimeFilter.morning);
                          },
                        ),
                        _TimeFilterChip(
                          label: 'Afternoon',
                          selected: tempTimeFilters.contains(
                            _SessionTimeFilter.afternoon,
                          ),
                          onSelected: () {
                            toggleTimeFilter(_SessionTimeFilter.afternoon);
                          },
                        ),
                        _TimeFilterChip(
                          label: 'Evening',
                          selected: tempTimeFilters.contains(
                            _SessionTimeFilter.night,
                          ),
                          onSelected: () {
                            toggleTimeFilter(_SessionTimeFilter.night);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _TimeFilterChip(
                          label: 'Not full',
                          selected: tempNotFullOnly,
                          onSelected: () {
                            setModalState(() {
                              tempNotFullOnly = !tempNotFullOnly;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                _selectedTimeFilters
                                  ..clear()
                                  ..addAll(
                                    tempTimeFilters.isEmpty
                                        ? _SessionTimeFilter.values
                                        : tempTimeFilters,
                                  );
                                _notFullOnly = tempNotFullOnly;
                              });
                              ref.invalidate(discoverySessionsProvider);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Confirm'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TimeFilterChip extends StatelessWidget {
  const _TimeFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      side: BorderSide(
        color: selected ? colorScheme.primary : colorScheme.outlineVariant,
      ),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
