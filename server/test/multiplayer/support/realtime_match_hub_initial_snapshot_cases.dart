part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubInitialSnapshotTests() {
  _registerRealtimeMatchHubLifecycleRaceTests();
  test('startMatch persists a full initial game snapshot', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final startedAt = DateTime.utc(2026, 7, 28, 13, 14, 15);
    final hub = RealtimeMatchHub(
      nowUtc: () => startedAt,
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();
    final match = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Test match',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    await hub.joinMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: match.id,
    );

    final started = await hub.startMatch(
      store: store,
      userIdentifier: 'owner-user',
      matchId: match.id,
      snapshotFactory: InitialMultiplayerSnapshotFactory(
        mapCatalog: mapCatalog,
      ),
    );
    final state = await store.findState(match.id);
    final save = GameSave.fromJson(state!.snapshot.save);
    final gameState = CanonicalGameSnapshotCodec.decodeDomainState(
      state.snapshot.state,
    );
    final canonical = const LosslessMatchSnapshotDecoder()
        .decode(state.snapshot)
        .canonical;
    final rawRuntime = state.snapshot.state['lifecycle']! as Map;

    expect(started.state, 'running');
    expect(started.turn, 1);
    expect(save.id, match.id);
    expect(save.gameMode, GameMode.multiplayer);
    expect(save.turn, 1);
    expect(save.savedAt, startedAt);
    final playerIds = started.players.map((player) => player.id).toSet();
    expect(save.players.map((player) => player.id).toSet(), playerIds);
    expect(playerIds, hasLength(2));
    expect(playerIds, everyElement(isNot(contains('user'))));
    expect(gameState.units, hasLength(4));
    expect(
      gameState.units.map((unit) => unit.ownerPlayerId).toSet(),
      playerIds,
    );
    expect(gameState.fogOfWar.playerIds, containsAll(save.playerStates.keys));
    expect(rawRuntime, isNot(contains('turnStartedAt')));
    expect(canonical.domain.turnStartedAt, startedAt);
    expect(
      canonical.domain.participants.map((player) => player.id),
      started.players.map((player) => player.id),
    );
  });
}
