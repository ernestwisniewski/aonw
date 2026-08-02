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
  final joined = await hub.joinMatch(
    store: store,
    userIdentifier: 'guest-user-$suffix',
    matchId: openMatch.id,
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

class _FindStateFailingMatchStore extends _MemoryMatchStore {
  String? _failedMatchId;

  void failFindStateFor(String matchId) {
    _failedMatchId = matchId;
  }

  @override
  Future<StoredMatchState?> findState(
    String matchId, {
    bool lock = false,
  }) async {
    if (_failedMatchId == matchId) {
      _failedMatchId = null;
      throw StateError('Injected findState failure for $matchId');
    }
    return super.findState(matchId, lock: lock);
  }
}

class _CommitFailingMatchStore extends _MemoryMatchStore {
  var _failNextCommit = false;

  void failNextCommit() {
    _failNextCommit = true;
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(MultiplayerMatchStore store) action,
  ) async {
    final statesBefore = Map<String, StoredMatchState>.of(_states);
    final eventsBefore = {
      for (final entry in _events.entries) entry.key: [...entry.value],
    };
    final clientEventsBefore = Map<String, WireEvent>.of(
      _eventsByClientMessageId,
    );
    try {
      final result = await action(this);
      if (_failNextCommit) {
        _failNextCommit = false;
        throw StateError('Injected transaction commit failure');
      }
      return result;
    } catch (_) {
      _states
        ..clear()
        ..addAll(statesBefore);
      _events
        ..clear()
        ..addAll(eventsBefore);
      _eventsByClientMessageId
        ..clear()
        ..addAll(clientEventsBefore);
      rethrow;
    }
  }
}

class _MemoryMatchStore implements MultiplayerMatchStore {
  _MemoryMatchStore({
    this.operationalEvents = const NoopServerOperationalEventSink(),
  });

  @override
  final ServerOperationalEventSink operationalEvents;

  final Map<String, StoredMatchState> _states = {};
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
    _states[state.match.id] = state;
    _events[state.match.id] = [];
    return state;
  }

  @override
  Future<StoredMatchState> saveState(StoredMatchState state) async {
    _states[state.match.id] = state;
    return state;
  }

  @override
  Future<StoredMatchState> appendEvent(
    StoredMatchState state,
    WireEvent event, {
    String? actorPlayerId,
    String? clientMessageId,
  }) async {
    _states[state.match.id] = state;
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
  Future<List<WireMatch>> listVisibleMatches(String userIdentifier) async {
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
        if (state.match.state == 'open' && state.match.inviteCode == null)
          state.match,
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
}
