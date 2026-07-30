part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubLifecycleRaceTests() {
  group('RealtimeMatchHub lifecycle serialization', () {
    test(
      'abandon commits before a queued start can inspect the lobby',
      () async {
        final mapCatalog = _FakeMapCatalog(_testMap());
        final hub = RealtimeMatchHub(
          commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
        );
        final store = _LockAwareMemoryMatchStore();
        final lobby = await _createJoinedRaceLobby(
          hub,
          store,
          suffix: 'abandon-first',
        );
        const ownerUserId = 'owner-abandon-first';

        store.holdNextTransaction();
        final abandonment = _captureRace(
          hub.resignMatch(
            store: store,
            userIdentifier: ownerUserId,
            matchId: lobby.id,
          ),
        );
        await store.waitUntilHeld;
        final lateStart = _captureRace(
          hub.startMatch(
            store: store,
            userIdentifier: ownerUserId,
            matchId: lobby.id,
            snapshotFactory: InitialMultiplayerSnapshotFactory(
              mapCatalog: mapCatalog,
            ),
          ),
        );
        store.releaseHeldTransaction();
        final results = await Future.wait([abandonment, lateStart]);

        final abandoned = (await store.findState(lobby.id))!;
        _expectConsistentTerminalLifecycle(abandoned);
        expect(abandoned.match.state, 'abandoned');
        expect(abandoned.snapshot.state['reason'], 'player_resigned');
        expect(results.where((result) => result.error != null), hasLength(1));
      },
    );

    test(
      'terminal resignation commits before a queued reconnect mutation',
      () async {
        final mapCatalog = _FakeMapCatalog(_testMap());
        final now = DateTime.utc(2026, 7, 30, 15);
        final hub = RealtimeMatchHub(
          commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
          nowUtc: () => now,
        );
        final store = _LockAwareMemoryMatchStore();
        final running = await _startRunningFfaMatchInStore(
          hub: hub,
          store: store,
          suffix: 'resign-reconnect',
          mapCatalog: mapCatalog,
        );
        final canonical = (await store.findState(running.id))!.match;
        final eliminated = canonical.players.firstWhere(
          (player) => player.userId == 'owner-user-resign-reconnect',
        );
        final resigning = canonical.players.firstWhere(
          (player) => player.userId == 'guest-one-resign-reconnect',
        );
        final reconnecting = canonical.players.firstWhere(
          (player) => player.userId == 'guest-two-resign-reconnect',
        );
        await _eliminatePlayersInStoredMatch(
          store: store,
          matchId: running.id,
          playerIds: {eliminated.id},
        );

        store.holdNextTransaction();
        final resignation = _captureRace(
          hub.resignMatch(
            store: store,
            userIdentifier: resigning.userId,
            matchId: running.id,
          ),
        );
        await store.waitUntilHeld;

        final input = StreamController<MultiplayerClientMessage>();
        final reconnect = hub
            .connect(
              store: store,
              userIdentifier: reconnecting.userId,
              matchId: running.id,
              afterOffset: 0,
              input: input.stream,
            )
            .asBroadcastStream();
        store.releaseHeldTransaction();

        final resignationResult = await resignation;
        expect(resignationResult.error, isNull);
        final firstReconnectMessage = await reconnect.firstWhere(
          (message) => message.match != null,
        );

        final terminal = (await store.findState(running.id))!;
        _expectConsistentTerminalLifecycle(terminal);
        expect(terminal.match.state, 'finished');
        expect(terminal.match.outcomeCondition, 'resignation');
        expect(terminal.match.winnerPlayerId, reconnecting.id);
        expect(
          terminal.match.players
              .firstWhere((player) => player.id == resigning.id)
              .connectionState,
          WirePlayerConnectionState.offline,
        );
        expect(firstReconnectMessage.match!.state, 'finished');

        await input.close();
      },
    );

    test(
      'first terminal resignation cannot be overwritten by a queued resign',
      () async {
        final mapCatalog = _FakeMapCatalog(_testMap());
        final now = DateTime.utc(2026, 7, 30, 16);
        final hub = RealtimeMatchHub(
          commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
          nowUtc: () => now,
        );
        final store = _LockAwareMemoryMatchStore();
        final running = await _startRunningFfaMatchInStore(
          hub: hub,
          store: store,
          suffix: 'resign-writers',
          mapCatalog: mapCatalog,
        );
        final canonical = (await store.findState(running.id))!.match;
        final eliminated = canonical.players.firstWhere(
          (player) => player.userId == 'owner-user-resign-writers',
        );
        final firstResigning = canonical.players.firstWhere(
          (player) => player.userId == 'guest-one-resign-writers',
        );
        final queuedResigning = canonical.players.firstWhere(
          (player) => player.userId == 'guest-two-resign-writers',
        );
        await _eliminatePlayersInStoredMatch(
          store: store,
          matchId: running.id,
          playerIds: {eliminated.id},
        );

        store.holdNextTransaction();
        final first = _captureRace(
          hub.resignMatch(
            store: store,
            userIdentifier: firstResigning.userId,
            matchId: running.id,
          ),
        );
        await store.waitUntilHeld;
        final queued = _captureRace(
          hub.resignMatch(
            store: store,
            userIdentifier: queuedResigning.userId,
            matchId: running.id,
          ),
        );
        store.releaseHeldTransaction();
        final results = await Future.wait([first, queued]);

        expect(results.where((result) => result.error != null), isEmpty);
        final terminal = (await store.findState(running.id))!;
        _expectConsistentTerminalLifecycle(terminal);
        expect(terminal.match.state, 'finished');
        expect(terminal.match.outcomeCondition, 'resignation');
        expect(terminal.match.winnerPlayerId, queuedResigning.id);
        expect(
          terminal.snapshot.state['resignedUserIdentifier'],
          firstResigning.userId,
        );
        expect(
          terminal.match.players
              .firstWhere((player) => player.id == queuedResigning.id)
              .connectionState,
          WirePlayerConnectionState.connected,
        );
      },
    );
  });
}

Future<WireMatch> _createJoinedRaceLobby(
  RealtimeMatchHub hub,
  _MemoryMatchStore store, {
  required String suffix,
}) async {
  final created = await hub.createMatch(
    store: store,
    userIdentifier: 'owner-$suffix',
    request: CreateMatchRequest(
      name: 'Race $suffix',
      mapName: 'verdantia',
      maxPlayers: 2,
      minPlayers: 2,
      private: false,
    ),
  );
  return hub.joinMatch(
    store: store,
    userIdentifier: 'guest-$suffix',
    matchId: created.id,
  );
}

Future<({Object? value, Object? error})> _captureRace(Future<Object?> future) {
  return future.then(
    (value) => (value: value, error: null),
    onError: (Object error, StackTrace _) => (value: null, error: error),
  );
}

void _expectConsistentTerminalLifecycle(StoredMatchState state) {
  expect(state.match.endedAt, isNotNull);
  expect(state.match.autoStartAt, isNull);
  if (state.match.state == 'finished') {
    expect(state.match.outcomeCondition, isNotNull);
    expect(state.snapshot.state['phase'], 'finished');
  } else {
    expect(state.match.state, 'abandoned');
    expect(state.match.outcomeCondition, isNull);
    expect(state.match.winnerPlayerId, isNull);
    expect(state.snapshot.state['phase'], 'abandoned');
  }
}

final class _LockAwareMemoryMatchStore extends _MemoryMatchStore {
  Future<void> _transactionTail = Future<void>.value();
  Completer<void>? _heldTransaction;
  Completer<void>? _releaseTransaction;
  var _holdArmed = false;

  void holdNextTransaction() {
    _heldTransaction = Completer<void>();
    _releaseTransaction = Completer<void>();
    _holdArmed = true;
  }

  Future<void> get waitUntilHeld => _heldTransaction!.future;

  void releaseHeldTransaction() {
    _releaseTransaction!.complete();
    _releaseTransaction = null;
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(MultiplayerMatchStore store) action,
  ) {
    final result = _transactionTail.then((_) async {
      final held = _heldTransaction;
      final release = _releaseTransaction;
      if (_holdArmed && held != null && release != null) {
        _holdArmed = false;
        _heldTransaction = null;
        held.complete();
        await release.future;
      }
      return action(this);
    });
    _transactionTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}
