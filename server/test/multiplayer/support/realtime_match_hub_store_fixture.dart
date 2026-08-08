part of '../realtime_match_hub_test.dart';

TypeMatcher<MultiplayerException> _multiplayerError(String code) {
  return isA<MultiplayerException>().having(
    (error) => error.code,
    'code',
    code,
  );
}

ServerpodOperationalEventSink _recordingOperationalEvents(
  List<String> messages,
) {
  return ServerpodOperationalEventSink.withWriter((
    message, {
    required level,
    stackTrace,
  }) {
    messages.add(message);
  });
}

Future<_RunningMatchFixture> _startRunningMatch(
  String suffix, {
  ServerOperationalEventSink operationalEvents =
      const NoopServerOperationalEventSink(),
}) async {
  final mapCatalog = _FakeMapCatalog(_testMap());
  final hub = RealtimeMatchHub(
    commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
  );
  final store = _MemoryMatchStore(operationalEvents: operationalEvents);
  final openMatch = await hub.createMatch(
    store: store,
    userIdentifier: 'owner-user-$suffix',
    request: CreateMatchRequest(
      name: 'Retry burst $suffix',
      mapName: 'verdantia',
      maxPlayers: 2,
      minPlayers: 2,
      private: false,
    ),
  );
  await _connectTestParticipant(
    hub: hub,
    store: store,
    userIdentifier: 'owner-user-$suffix',
    matchId: openMatch.id,
  );
  final joined = await hub.joinMatch(
    store: store,
    userIdentifier: 'guest-user-$suffix',
    matchId: openMatch.id,
  );
  await _connectTestParticipant(
    hub: hub,
    store: store,
    userIdentifier: 'guest-user-$suffix',
    matchId: joined.id,
  );
  final match = await hub.startMatch(
    store: store,
    userIdentifier: 'owner-user-$suffix',
    matchId: joined.id,
    snapshotFactory: InitialMultiplayerSnapshotFactory(mapCatalog: mapCatalog),
  );
  return _RunningMatchFixture(hub: hub, store: store, match: match);
}

final class _RunningMatchFixture {
  const _RunningMatchFixture({
    required this.hub,
    required this.store,
    required this.match,
  });

  final RealtimeMatchHub hub;
  final _MemoryMatchStore store;
  final WireMatch match;
}

abstract class _MemoryPresenceMatchStore implements MultiplayerMatchStore {
  final Map<String, StoredMatchState> _states = {};
  final Map<String, int> _presenceRowIds = {};
  var _nextPresenceRowId = 1;

  @override
  Future<ExpiredPresenceLeasePage> listExpiredPresenceLeases({
    required DateTime nowUtc,
    ExpiredPresenceLeaseCursor? after,
  }) async {
    final cutoff = nowUtc.toUtc();
    final candidates = <ExpiredPresenceLeaseCandidate>[];
    for (final entry in _states.entries) {
      for (final lease in entry.value.presenceLeases.values) {
        if (!lease.isExpiredAt(cutoff)) continue;
        final rowId = _presenceRowId(entry.key, lease.userIdentifier);
        if (after != null) {
          final expiresAtOrder = lease.expiresAt.compareTo(after.expiresAt);
          if (expiresAtOrder < 0 ||
              (expiresAtOrder == 0 && rowId <= after.rowId)) {
            continue;
          }
        }
        candidates.add(
          ExpiredPresenceLeaseCandidate(
            rowId: rowId,
            matchId: entry.key,
            lease: lease,
          ),
        );
      }
    }
    candidates.sort((first, second) {
      final expiresAtOrder = first.lease.expiresAt.compareTo(
        second.lease.expiresAt,
      );
      if (expiresAtOrder != 0) return expiresAtOrder;
      return first.rowId.compareTo(second.rowId);
    });
    final window = candidates
        .take(multiplayerPresenceLeasePageSize + 1)
        .toList();
    final page = window.take(multiplayerPresenceLeasePageSize).toList();
    final last = page.isEmpty ? null : page.last;
    return ExpiredPresenceLeasePage(
      candidates: page,
      nextCursor:
          window.length <= multiplayerPresenceLeasePageSize || last == null
          ? null
          : ExpiredPresenceLeaseCursor(
              expiresAt: last.lease.expiresAt,
              rowId: last.rowId,
            ),
    );
  }

  @override
  Future<void> upsertPresenceLease({
    required String matchId,
    required StoredMatchPresenceLease lease,
  }) async {
    final state = _states[matchId];
    if (state == null) throw StateError('Match not found: $matchId');
    _presenceRowId(matchId, lease.userIdentifier);
    _states[matchId] = state.copyWith(
      presenceLeases: {...state.presenceLeases, lease.userIdentifier: lease},
    );
  }

  @override
  Future<bool> renewPresenceLease({
    required String matchId,
    required String userIdentifier,
    required String connectionGeneration,
    required DateTime expiresAt,
    required DateTime updatedAt,
  }) async {
    final state = _states[matchId];
    final lease = state?.presenceLeases[userIdentifier];
    if (state == null ||
        lease == null ||
        lease.connectionGeneration != connectionGeneration) {
      return false;
    }
    _states[matchId] = state.copyWith(
      presenceLeases: {
        ...state.presenceLeases,
        userIdentifier: lease.copyWith(
          expiresAt: expiresAt.toUtc(),
          updatedAt: updatedAt.toUtc(),
        ),
      },
    );
    return true;
  }

  @override
  Future<void> deletePresenceLease({
    required String matchId,
    required String userIdentifier,
  }) async {
    final state = _states[matchId];
    if (state == null) throw StateError('Match not found: $matchId');
    _states[matchId] = state.copyWith(
      presenceLeases: {
        for (final entry in state.presenceLeases.entries)
          if (entry.key != userIdentifier) entry.key: entry.value,
      },
    );
    _presenceRowIds.remove(_presenceKey(matchId, userIdentifier));
  }

  @override
  Future<void> deletePresenceLeases(String matchId) async {
    final state = _states[matchId];
    if (state == null) throw StateError('Match not found: $matchId');
    _states[matchId] = state.copyWith(presenceLeases: const {});
    _presenceRowIds.removeWhere((key, _) => key.startsWith('$matchId\u0000'));
  }

  int _presenceRowId(String matchId, String userIdentifier) {
    return _presenceRowIds.putIfAbsent(
      _presenceKey(matchId, userIdentifier),
      () => _nextPresenceRowId++,
    );
  }

  String _presenceKey(String matchId, String userIdentifier) =>
      '$matchId\u0000$userIdentifier';
}

class _MemoryMatchStore extends _MemoryPresenceMatchStore {
  _MemoryMatchStore({
    this.operationalEvents = const NoopServerOperationalEventSink(),
  });

  @override
  final ServerOperationalEventSink operationalEvents;

  final Map<String, List<WireEvent>> _events = {};
  final Map<String, WireEvent> _eventsByClientMessageId = {};
  final List<RunningMatchCursor?> runningCursors = [];
  final List<List<String>> runningPages = [];

  @override
  Future<T> transaction<T>(
    Future<T> Function(MultiplayerMatchStore store) action,
  ) {
    return action(this);
  }

  @override
  Future<StoredMatchState> createState(StoredMatchState state) async {
    _replaceState(state);
    _events[state.match.id] = [];
    return state;
  }

  @override
  Future<StoredMatchState> saveState(StoredMatchState state) async {
    _replaceState(state);
    return state;
  }

  @override
  Future<StoredMatchState> appendEvent(
    StoredMatchState state,
    WireEvent event, {
    String? actorPlayerId,
    String? clientMessageId,
  }) async {
    _replaceState(state);
    _events.putIfAbsent(state.match.id, () => []).add(event);
    if (actorPlayerId != null && clientMessageId != null) {
      _eventsByClientMessageId[_clientMessageKey(
            state.match.id,
            actorPlayerId,
            clientMessageId,
          )] =
          event;
    }
    return state;
  }

  @override
  Future<WireEvent?> findEventByClientMessageId(
    String matchId, {
    required String actorPlayerId,
    required String clientMessageId,
  }) async {
    return _eventsByClientMessageId[_clientMessageKey(
      matchId,
      actorPlayerId,
      clientMessageId,
    )];
  }

  @override
  Future<StoredMatchState?> findState(
    String matchId, {
    bool lock = false,
  }) async {
    return _states[matchId];
  }

  @override
  Future<StoredMatchState?> findPrivateState(
    String inviteCode, {
    bool lock = false,
  }) async {
    final normalized = inviteCode.trim().toUpperCase();
    for (final state in _states.values) {
      if (state.match.inviteCode == normalized) return state;
    }
    return null;
  }

  @override
  Future<StoredMatchState?> findOpenQuickplayCandidate(
    CreateMatchRequest request,
  ) async {
    final candidates =
        [
          for (final state in _states.values)
            if (state.match.state == 'open' &&
                state.match.quickplay &&
                state.match.inviteCode == null &&
                state.match.mapName == request.mapName)
              state,
        ]..sort((first, second) {
          final createdAtOrder = first.match.createdAt.compareTo(
            second.match.createdAt,
          );
          if (createdAtOrder != 0) return createdAtOrder;
          return first.match.id.compareTo(second.match.id);
        });
    for (final state in candidates.take(
      multiplayerQuickplayCandidateScanLimit,
    )) {
      final match = state.match;
      if (match.players.length < match.maxPlayers) {
        return state;
      }
    }
    return null;
  }

  @override
  Future<List<WireMatch>> listVisibleMatches(
    String userIdentifier, {
    required DateTime nowUtc,
  }) async {
    final participantMatches = [
      for (final state in _states.values)
        if (_isActiveMatch(state.match) &&
            state.match.players.any(
              (player) => player.userId == userIdentifier,
            ))
          state.match,
    ]..sort(_compareTestMatchesNewestFirst);
    final publicLobbies = [
      for (final state in _states.values)
        if (_isDiscoverablePublicLobby(state, nowUtc: nowUtc)) state.match,
    ]..sort(_compareTestMatchesNewestFirst);
    final participantIds = {for (final match in participantMatches) match.id};
    final matchesById = <String, WireMatch>{};
    for (final match in [
      ...participantMatches.take(multiplayerVisibleParticipantMatchLimit),
      ...publicLobbies.take(multiplayerVisiblePublicLobbyLimit),
    ]) {
      matchesById.putIfAbsent(match.id, () => match);
    }
    final matches = matchesById.values.toList()
      ..sort((first, second) {
        final createdAtOrder = second.createdAt.compareTo(first.createdAt);
        if (createdAtOrder != 0) return createdAtOrder;
        final firstIsParticipant = participantIds.contains(first.id);
        final secondIsParticipant = participantIds.contains(second.id);
        if (firstIsParticipant != secondIsParticipant) {
          return firstIsParticipant ? -1 : 1;
        }
        return second.id.compareTo(first.id);
      });
    return matches;
  }

  @override
  Future<RunningMatchStatePage> listRunningStates({
    RunningMatchCursor? after,
  }) async {
    runningCursors.add(after);
    final candidates =
        [
          for (final state in _states.values)
            if (state.match.state == 'running' &&
                _isAfterRunningCursor(state.match, after))
              state,
        ]..sort((first, second) {
          final createdAtOrder = first.match.createdAt.compareTo(
            second.match.createdAt,
          );
          if (createdAtOrder != 0) return createdAtOrder;
          return first.match.id.compareTo(second.match.id);
        });
    final window = candidates
        .take(multiplayerRunningMatchPageSize + 1)
        .toList();
    final page = window.take(multiplayerRunningMatchPageSize).toList();
    runningPages.add([for (final state in page) state.match.id]);
    final last = page.isEmpty ? null : page.last.match;
    return RunningMatchStatePage(
      states: page,
      nextCursor:
          window.length <= multiplayerRunningMatchPageSize || last == null
          ? null
          : RunningMatchCursor(createdAt: last.createdAt, publicId: last.id),
    );
  }

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) async {
    final events = [
      for (final event in _events[matchId] ?? const <WireEvent>[])
        if (event.offset > afterOffset) event,
    ]..sort((first, second) => first.offset.compareTo(second.offset));
    return events.take(multiplayerEventPageSize).toList();
  }

  void _replaceState(StoredMatchState state) {
    final matchId = state.match.id;
    _presenceRowIds.removeWhere(
      (key, _) =>
          key.startsWith('$matchId\u0000') &&
          !state.presenceLeases.containsKey(key.substring(matchId.length + 1)),
    );
    for (final userIdentifier in state.presenceLeases.keys) {
      _presenceRowId(matchId, userIdentifier);
    }
    _states[matchId] = state;
  }

  bool _isDiscoverablePublicLobby(
    StoredMatchState state, {
    required DateTime nowUtc,
  }) {
    final match = state.match;
    if (match.state != 'open' || match.inviteCode != null || match.quickplay) {
      return false;
    }
    const rosterPolicy = LobbyRosterPolicy();
    final owners = match.players.where(
      (player) => player.userId == match.ownerUserId,
    );
    if (owners.length != 1 ||
        !rosterPolicy.isConnectedHuman(owners.single) ||
        rosterPolicy.humanMemberCount(match) >= match.maxPlayers) {
      return false;
    }
    final ownerLease = state.presenceLeases[match.ownerUserId];
    return ownerLease != null && !ownerLease.isExpiredAt(nowUtc);
  }
}
