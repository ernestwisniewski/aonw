part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubResignationScenarios() {
  _registerRealtimeMatchHubResignationCharacterizationTests();

  test(
    'resignMatch keeps a running FFA alive until one player remains',
    () async {
      final mapCatalog = _FakeMapCatalog(_testMap());
      final endedAt = DateTime.utc(2026, 7, 12, 15);
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
        nowUtc: () => endedAt,
      );
      final store = _MemoryMatchStore();
      final match = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: CreateMatchRequest(
          name: 'FFA resign',
          mapName: 'verdantia',
          maxPlayers: 3,
          minPlayers: 3,
          private: false,
        ),
      );
      await _connectTestParticipant(
        hub: hub,
        store: store,
        userIdentifier: 'owner-user',
        matchId: match.id,
      );
      await hub.joinMatch(
        store: store,
        userIdentifier: 'guest-one',
        matchId: match.id,
      );
      await _connectTestParticipant(
        hub: hub,
        store: store,
        userIdentifier: 'guest-one',
        matchId: match.id,
      );
      await hub.joinMatch(
        store: store,
        userIdentifier: 'guest-two',
        matchId: match.id,
      );
      await _connectTestParticipant(
        hub: hub,
        store: store,
        userIdentifier: 'guest-two',
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
      final ownerInput = StreamController<MultiplayerClientMessage>();
      final ownerStream = hub
          .connect(
            store: store,
            userIdentifier: 'owner-user',
            matchId: started.id,
            afterOffset: 0,
            input: ownerInput.stream,
          )
          .asBroadcastStream();
      await ownerStream.first;
      final lifecycleUpdates = ownerStream
          .where((message) => message.match != null)
          .take(2)
          .toList();

      final afterFirstResign = await hub.resignMatch(
        store: store,
        userIdentifier: 'guest-one',
        matchId: started.id,
      );
      final running = (await store.findState(started.id))!;
      final firstGuest = running.match.players.firstWhere(
        (player) => player.userId == 'guest-one',
      );
      final runningSave = GameSave.fromJson(running.snapshot.save);
      final runningState = CanonicalGameSnapshotCodec.decodeDomainState(
        running.snapshot.state,
      );

      expect(afterFirstResign.state, 'running');
      expect(afterFirstResign.endedAt, isNull);
      expect(firstGuest.connectionState, WirePlayerConnectionState.offline);
      expect(runningSave.playerStates[firstGuest.id], PlayerTurnState.finished);
      expect(runningState.kickedPlayerIds, contains(firstGuest.id));

      final afterSecondResign = await hub.resignMatch(
        store: store,
        userIdentifier: 'guest-two',
        matchId: started.id,
      );

      expect(afterSecondResign.state, 'finished');
      expect(afterSecondResign.endedAt, endedAt);
      expect(afterSecondResign.outcomeCondition, 'resignation');
      expect(afterSecondResign.winnerPlayerId, started.players.first.id);
      expect(
        (await store.findState(started.id))!.snapshot.state['phase'],
        'finished',
      );
      final updates = await lifecycleUpdates;
      expect(updates, hasLength(2));
      expect(updates.last.snapshot?.state['phase'], 'finished');
      expect(
        updates.last.snapshot!.state,
        isNot(contains('resignedUserIdentifier')),
      );
      expect(updates.last.toJson().toString(), isNot(contains('guest-two')));

      await ownerInput.close();
    },
  );

  test(
    'resignMatch ignores eliminated FFA seats when choosing the winner',
    () async {
      final mapCatalog = _FakeMapCatalog(_testMap());
      final endedAt = DateTime.utc(2026, 7, 12, 15, 30);
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
        nowUtc: () => endedAt,
      );
      final store = _MemoryMatchStore();
      const suffix = 'alive-contenders';
      final started = await _startRunningFfaMatchInStore(
        hub: hub,
        store: store,
        suffix: suffix,
        mapCatalog: mapCatalog,
      );
      final canonical = (await store.findState(started.id))!.match;
      final eliminated = canonical.players.firstWhere(
        (player) => player.userId == 'owner-user-$suffix',
      );
      final resigning = canonical.players.firstWhere(
        (player) => player.userId == 'guest-one-$suffix',
      );
      final surviving = canonical.players.firstWhere(
        (player) => player.userId == 'guest-two-$suffix',
      );
      await _eliminatePlayersInStoredMatch(
        store: store,
        matchId: started.id,
        playerIds: {eliminated.id},
      );

      final resigned = await hub.resignMatch(
        store: store,
        userIdentifier: resigning.userId,
        matchId: started.id,
      );

      expect(resigned.state, 'finished');
      expect(resigned.endedAt, endedAt);
      expect(resigned.outcomeCondition, 'resignation');
      expect(resigned.winnerPlayerId, surviving.id);
      expect(resigned.winnerPlayerId, isNot(eliminated.id));
    },
  );

  test(
    'resignMatch abandons an FFA when no living contender remains',
    () async {
      final mapCatalog = _FakeMapCatalog(_testMap());
      final endedAt = DateTime.utc(2026, 7, 12, 15, 45);
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
        nowUtc: () => endedAt,
      );
      final store = _MemoryMatchStore();
      const suffix = 'no-alive-contenders';
      final started = await _startRunningFfaMatchInStore(
        hub: hub,
        store: store,
        suffix: suffix,
        mapCatalog: mapCatalog,
      );
      final canonical = (await store.findState(started.id))!.match;
      final resigning = canonical.players.firstWhere(
        (player) => player.userId == 'guest-two-$suffix',
      );
      await _eliminatePlayersInStoredMatch(
        store: store,
        matchId: started.id,
        playerIds: {
          for (final player in canonical.players)
            if (player.id != resigning.id) player.id,
        },
      );

      final resigned = await hub.resignMatch(
        store: store,
        userIdentifier: resigning.userId,
        matchId: started.id,
      );
      final stored = (await store.findState(started.id))!;

      expect(resigned.state, 'abandoned');
      expect(resigned.endedAt, endedAt);
      expect(resigned.outcomeCondition, isNull);
      expect(resigned.winnerPlayerId, isNull);
      expect(stored.snapshot.state['phase'], 'abandoned');
      expect(
        stored.snapshot.state['reason'],
        'no_alive_players_after_resignation',
      );
    },
  );

  test('resigning an open lobby abandons it without a game outcome', () async {
    final endedAt = DateTime.utc(2026, 7, 12, 16);
    final hub = RealtimeMatchHub(nowUtc: () => endedAt);
    final store = _MemoryMatchStore();
    final open = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Cancelled lobby',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );

    final resigned = await hub.resignMatch(
      store: store,
      userIdentifier: 'owner-user',
      matchId: open.id,
    );

    expect(resigned.state, 'abandoned');
    expect(resigned.endedAt, endedAt);
    expect(resigned.outcomeCondition, isNull);
    expect(resigned.winnerPlayerId, isNull);
  });

  test('only the owner can abandon an open lobby by resigning', () async {
    final hub = RealtimeMatchHub();
    final store = _MemoryMatchStore();
    final open = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Protected lobby',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'owner-user',
      matchId: open.id,
    );
    await hub.joinMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: open.id,
    );

    await expectLater(
      hub.resignMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: open.id,
      ),
      throwsA(_multiplayerError('not_match_owner')),
    );

    final stored = (await store.findState(open.id))!.match;
    expect(stored.state, 'open');
    expect(stored.players, hasLength(2));
    expect(stored.endedAt, isNull);
  });
}
