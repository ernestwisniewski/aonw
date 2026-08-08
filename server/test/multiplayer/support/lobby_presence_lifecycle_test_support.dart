part of '../lobby_presence_lifecycle_test.dart';

CreateMatchRequest _hostedRequest() => CreateMatchRequest(
  name: 'Presence lobby',
  mapName: 'verdantia',
  maxPlayers: 3,
  minPlayers: 2,
  private: false,
);

Future<_TestLobbyConnection> _connectParticipant({
  required RealtimeMatchHub hub,
  required MultiplayerMatchStore store,
  required String userIdentifier,
  required String matchId,
}) async {
  final input = StreamController<MultiplayerClientMessage>();
  final initial = Completer<void>();
  final done = Completer<void>();
  final subscription = hub
      .connect(
        store: store,
        userIdentifier: userIdentifier,
        matchId: matchId,
        afterOffset: 0,
        input: input.stream,
      )
      .listen(
        (_) {
          if (!initial.isCompleted) initial.complete();
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!initial.isCompleted) initial.completeError(error, stackTrace);
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
      );
  await initial.future.timeout(const Duration(seconds: 1));
  return _TestLobbyConnection(
    input: input,
    subscription: subscription,
    done: done,
  );
}

Future<void> _waitUntil(Future<bool> Function() predicate) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    if (await predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw TimeoutException('Timed out waiting for lobby state.');
}

final class _TestLobbyConnection {
  const _TestLobbyConnection({
    required this.input,
    required this.subscription,
    required this.done,
  });

  final StreamController<MultiplayerClientMessage> input;
  final StreamSubscription<MultiplayerServerMessage> subscription;
  final Completer<void> done;

  Future<void> close() async {
    await input.close();
    await done.future.timeout(const Duration(seconds: 1));
    await subscription.cancel();
  }
}

Future<WireMatch> _quickplay(
  RealtimeMatchHub hub,
  MultiplayerMatchStore store, {
  required String user,
  required PlayerCountry country,
}) {
  return hub.quickplay(
    store: store,
    userIdentifier: user,
    request: CreateMatchRequest(
      name: 'Quickplay',
      mapName: 'verdantia',
      maxPlayers: 4,
      minPlayers: 2,
      private: false,
      countryId: country.name,
    ),
  );
}

final class _LobbyPresenceStore implements MultiplayerMatchStore {
  final _states = <String, StoredMatchState>{};
  final _events = <String, List<WireEvent>>{};
  final _presenceRowIds = <String, int>{};
  var _nextPresenceRowId = 1;

  @override
  final operationalEvents = const NoopServerOperationalEventSink();

  @override
  Future<T> transaction<T>(
    Future<T> Function(MultiplayerMatchStore store) action,
  ) => action(this);

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
  Future<StoredMatchState?> findState(
    String matchId, {
    bool lock = false,
  }) async => _states[matchId];

  @override
  Future<StoredMatchState?> findOpenQuickplayCandidate(
    CreateMatchRequest request,
  ) async {
    for (final state in _states.values) {
      final match = state.match;
      if (match.state == 'open' &&
          match.quickplay &&
          match.players.length < match.maxPlayers) {
        return state;
      }
    }
    return null;
  }

  @override
  Future<RunningMatchStatePage> listRunningStates({
    RunningMatchCursor? after,
  }) async {
    return RunningMatchStatePage(
      states: _states.values.where((state) => state.match.state == 'running'),
      nextCursor: null,
    );
  }

  @override
  Future<StoredMatchState?> findPrivateState(
    String inviteCode, {
    bool lock = false,
  }) async => null;

  @override
  Future<List<WireMatch>> listVisibleMatches(
    String userIdentifier, {
    required DateTime nowUtc,
  }) async => [];

  @override
  Future<ExpiredPresenceLeasePage> listExpiredPresenceLeases({
    required DateTime nowUtc,
    ExpiredPresenceLeaseCursor? after,
  }) async {
    final candidates = <ExpiredPresenceLeaseCandidate>[];
    for (final entry in _states.entries) {
      for (final lease in entry.value.presenceLeases.values) {
        if (!lease.isExpiredAt(nowUtc)) continue;
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
    final state = _requireState(matchId);
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
    final state = _requireState(matchId);
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
    final state = _requireState(matchId);
    _states[matchId] = state.copyWith(presenceLeases: const {});
    _presenceRowIds.removeWhere((key, _) => key.startsWith('$matchId\u0000'));
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
    return state;
  }

  @override
  Future<WireEvent?> findEventByClientMessageId(
    String matchId, {
    required String actorPlayerId,
    required String clientMessageId,
  }) async => null;

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) async {
    return [
      for (final event in _events[matchId] ?? const <WireEvent>[])
        if (event.offset > afterOffset) event,
    ];
  }

  StoredMatchState _requireState(String matchId) {
    return _states[matchId] ?? (throw StateError('Match not found: $matchId'));
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

  int _presenceRowId(String matchId, String userIdentifier) {
    return _presenceRowIds.putIfAbsent(
      _presenceKey(matchId, userIdentifier),
      () => _nextPresenceRowId++,
    );
  }

  String _presenceKey(String matchId, String userIdentifier) =>
      '$matchId\u0000$userIdentifier';
}
