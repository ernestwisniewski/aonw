part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubQuickplayScenarios() {
  test('quickplay preserves requested civilizations', () async {
    final hub = RealtimeMatchHub();
    final store = _MemoryMatchStore();

    final waiting = await hub.quickplay(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Quickplay',
        mapName: 'verdantia',
        maxPlayers: 3,
        minPlayers: 2,
        private: false,
        countryId: PlayerCountry.japan.name,
      ),
    );
    await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'owner-user',
      matchId: waiting.id,
    );
    expect(waiting.players.single.country, PlayerCountry.japan);
    expect(waiting.maxPlayers, 4);
    expect(waiting.minPlayers, 2);
    expect(waiting.quickplay, isTrue);
    expect(waiting.autoStartAt, isNull);

    final joinedReservation = await hub.quickplay(
      store: store,
      userIdentifier: 'guest-user',
      request: CreateMatchRequest(
        name: 'Quickplay',
        mapName: 'verdantia',
        maxPlayers: 3,
        minPlayers: 2,
        private: false,
        countryId: PlayerCountry.france.name,
      ),
    );
    final guestConnection = await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'guest-user',
      matchId: joinedReservation.id,
    );
    final joined = guestConnection.initialMessage.match!;

    expect(joined.maxPlayers, 4);
    expect(joined.minPlayers, 2);
    expect(joined.autoStartAt, isNotNull);
    expect(joined.players.map((player) => player.country), [
      PlayerCountry.japan,
      PlayerCountry.france,
    ]);
    await expectLater(
      hub.joinMatch(
        store: store,
        userIdentifier: 'third-user',
        matchId: joined.id,
        countryId: PlayerCountry.japan.name,
      ),
      throwsA(_multiplayerError('country_unavailable')),
    );
  });

  test('quickplay uses one global queue regardless of requested map', () async {
    final hub = RealtimeMatchHub();
    final store = _MemoryMatchStore();

    final verdantia = await hub.quickplay(
      store: store,
      userIdentifier: 'verdantia-owner',
      request: CreateMatchRequest(
        name: 'Ignored',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'verdantia-owner',
      matchId: verdantia.id,
    );
    final myranth = await hub.quickplay(
      store: store,
      userIdentifier: 'myranth-owner',
      request: CreateMatchRequest(
        name: 'Ignored',
        mapName: 'myranth',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'myranth-owner',
      matchId: myranth.id,
    );

    expect(myranth.id, verdantia.id);
    expect(verdantia.mapName, 'verdantia');
    expect(myranth.mapName, MapPlayerCapacityRules.fullMultiplayerMapName);
    expect(verdantia.players, hasLength(1));
    expect(myranth.players, hasLength(2));
  });

  test('quickplay starts a 30 second countdown at two players', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    var now = DateTime.utc(2026, 6, 12, 9);
    final hub = RealtimeMatchHub(
      nowUtc: () => now,
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();

    final waiting = await hub.quickplay(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Ignored',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
        countryId: PlayerCountry.japan.name,
      ),
    );
    final ownerConnection = await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'owner-user',
      matchId: waiting.id,
    );

    expect(waiting.state, 'open');
    expect(waiting.maxPlayers, 4);
    expect(waiting.minPlayers, 2);
    expect(waiting.autoStartAt, isNull);

    final guestReservation = await hub.quickplay(
      store: store,
      userIdentifier: 'guest-user',
      request: CreateMatchRequest(
        name: 'Ignored',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
        countryId: PlayerCountry.france.name,
      ),
    );
    final guestConnection = await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'guest-user',
      matchId: guestReservation.id,
    );
    final countingDown = guestConnection.initialMessage.match!;

    expect(countingDown.state, 'open');
    expect(countingDown.autoStartAt, DateTime.utc(2026, 6, 12, 9, 0, 30));

    now = DateTime.utc(2026, 6, 12, 9, 0, 29);
    Future<void> renewPresence(
      _TestMatchConnection connection,
      String clientMessageId,
    ) async {
      final response = connection.stream.firstWhere(
        (message) => message.snapshot != null,
      );
      connection.input.add(
        MultiplayerClientMessage(
          clientMessageId: clientMessageId,
          lastSeenOffset: 0,
          requestSnapshot: true,
        ),
      );
      await response.timeout(const Duration(seconds: 1));
    }

    await Future.wait([
      renewPresence(ownerConnection, 'owner-countdown-heartbeat'),
      renewPresence(guestConnection, 'guest-countdown-heartbeat'),
    ]);
    now = DateTime.utc(2026, 6, 12, 9, 0, 31);
    final started = await hub.loadMatch(
      store: store,
      userIdentifier: 'owner-user',
      matchId: countingDown.id,
      snapshotFactory: InitialMultiplayerSnapshotFactory(
        mapCatalog: mapCatalog,
      ),
    );

    final state = await store.findState(started.id);
    expect(started.state, 'running');
    expect(started.turn, 1);
    expect(started.autoStartAt, isNull);
    expect(
      MapPlayerCapacityRules.official.map((profile) => profile.mapName),
      contains(started.mapName),
    );
    final save = GameSave.fromJson(state!.snapshot.save);
    expect(save.mapName, started.mapName);
    expect(save.players, hasLength(2));
  });

  test('quickplay updates a returning player civilization selection', () async {
    final now = DateTime.utc(2026, 6, 12, 9);
    final hub = RealtimeMatchHub(nowUtc: () => now);
    final store = _MemoryMatchStore();

    final first = await hub.quickplay(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Quickplay',
        mapName: 'verdantia',
        maxPlayers: 4,
        minPlayers: 2,
        private: false,
        countryId: PlayerCountry.poland.name,
      ),
    );
    await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'owner-user',
      matchId: first.id,
    );
    expect(first.players.single.country, PlayerCountry.poland);

    final updatedReservation = await hub.quickplay(
      store: store,
      userIdentifier: 'owner-user',
      displayName: 'Owner Renamed',
      request: CreateMatchRequest(
        name: 'Quickplay',
        mapName: 'verdantia',
        maxPlayers: 4,
        minPlayers: 2,
        private: false,
        countryId: PlayerCountry.china.name,
      ),
    );
    final updatedConnection = await _connectTestParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'owner-user',
      matchId: updatedReservation.id,
    );
    final updated = updatedConnection.initialMessage.match!;

    expect(updated.id, first.id);
    expect(updated.players, hasLength(1));
    expect(updated.players.single.country, PlayerCountry.china);
    expect(updated.players.single.name, 'Owner Renamed');
  });

  test('quickplay skips stale one-player simulator lobbies', () async {
    var now = DateTime.utc(2026, 6, 12, 9);
    final hub = RealtimeMatchHub(nowUtc: () => now);
    final store = _MemoryMatchStore();

    final stale = await hub.quickplay(
      store: store,
      userIdentifier: 'simulator-user',
      request: CreateMatchRequest(
        name: 'Quickplay',
        mapName: 'verdantia',
        maxPlayers: 4,
        minPlayers: 2,
        private: false,
        countryId: PlayerCountry.ukraine.name,
      ),
    );
    expect(stale.players.single.country, PlayerCountry.ukraine);

    now = now.add(const Duration(minutes: 2));
    final fresh = await hub.quickplay(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Quickplay',
        mapName: 'verdantia',
        maxPlayers: 4,
        minPlayers: 2,
        private: false,
        countryId: PlayerCountry.china.name,
      ),
    );

    expect(fresh.id, isNot(stale.id));
    expect(fresh.players, hasLength(1));
    expect(fresh.players.single.country, PlayerCountry.china);
    expect((await store.findState(stale.id))!.match.state, 'abandoned');
  });

  test('quickplay starts immediately when the fourth player joins', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      nowUtc: () => DateTime.utc(2026, 6, 12, 9),
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();

    Future<WireMatch> quickplay(String user, PlayerCountry country) async {
      final reservation = await hub.quickplay(
        store: store,
        userIdentifier: user,
        request: CreateMatchRequest(
          name: 'Quickplay',
          mapName: 'terenos',
          maxPlayers: 4,
          minPlayers: 2,
          private: false,
          countryId: country.name,
        ),
        snapshotFactory: InitialMultiplayerSnapshotFactory(
          mapCatalog: mapCatalog,
        ),
      );
      final connection = await _connectTestParticipant(
        hub: hub,
        store: store,
        userIdentifier: user,
        matchId: reservation.id,
      );
      return connection.initialMessage.match!;
    }

    await quickplay('owner-user', PlayerCountry.japan);
    await quickplay('guest-user', PlayerCountry.france);
    await quickplay('third-user', PlayerCountry.germany);
    final started = await quickplay('fourth-user', PlayerCountry.poland);

    final state = await store.findState(started.id);
    expect(started.state, 'running');
    expect(started.mapName, MapPlayerCapacityRules.fullMultiplayerMapName);
    expect(started.players, hasLength(4));
    expect(started.autoStartAt, isNull);
    final save = GameSave.fromJson(state!.snapshot.save);
    expect(save.mapName, MapPlayerCapacityRules.fullMultiplayerMapName);
    expect(save.players, hasLength(4));
  });

  test('quickplay does not scan past the bounded candidate window', () async {
    final now = DateTime.utc(2026, 7, 10, 12);
    final hub = RealtimeMatchHub(nowUtc: () => now);
    final store = _MemoryMatchStore();

    Future<WireMatch> createCandidate(int index, {required bool full}) async {
      final created = await hub.createMatch(
        store: store,
        userIdentifier: 'candidate-owner-$index',
        request: CreateMatchRequest(
          name: 'Candidate $index',
          mapName: 'verdantia',
          maxPlayers: 2,
          minPlayers: 2,
          private: false,
        ),
      );
      var state = (await store.findState(created.id))!;
      final owner = state.match.players.single;
      state = state.copyWith(
        match: state.match.copyWith(
          quickplay: true,
          createdAt: full
              ? DateTime.utc(2026, 7, 10).add(Duration(seconds: index))
              : now,
          players: full
              ? [
                  owner,
                  owner.copyWith(
                    id: 'full-player-$index',
                    userId: 'full-user-$index',
                    name: 'Full player $index',
                  ),
                ]
              : null,
        ),
      );
      await store.saveState(state);
      return state.match;
    }

    for (
      var index = 0;
      index < multiplayerQuickplayCandidateScanLimit;
      index += 1
    ) {
      await createCandidate(index, full: true);
    }
    final candidatePastWindow = await createCandidate(
      multiplayerQuickplayCandidateScanLimit,
      full: false,
    );

    final matched = await hub.quickplay(
      store: store,
      userIdentifier: 'bounded-candidate-user',
      request: CreateMatchRequest(
        name: 'Quickplay',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
        countryId: PlayerCountry.china.name,
      ),
    );

    expect(matched.id, isNot(candidatePastWindow.id));
    expect(matched.players.single.userId, 'bounded-candidate-user');
    final candidateState = (await store.findState(candidatePastWindow.id))!;
    expect(candidateState.match.state, 'open');
    expect(candidateState.match.players, hasLength(1));
  });

  test('quickplay caps stale candidate retirement per request', () async {
    var now = DateTime.utc(2026, 7, 1);
    final hub = RealtimeMatchHub(nowUtc: () => now);
    final store = _MemoryMatchStore();
    final staleIds = <String>[];
    const staleCount = multiplayerQuickplayCandidateRetirementLimit + 2;
    for (var index = 0; index < staleCount; index += 1) {
      final created = await hub.createMatch(
        store: store,
        userIdentifier: 'stale-owner-$index',
        request: CreateMatchRequest(
          name: 'Stale candidate $index',
          mapName: 'verdantia',
          maxPlayers: 2,
          minPlayers: 2,
          private: false,
        ),
      );
      var state = (await store.findState(created.id))!;
      state = state.copyWith(
        match: state.match.copyWith(
          quickplay: true,
          createdAt: DateTime.utc(2026, 7, 1).add(Duration(seconds: index)),
        ),
      );
      await store.saveState(state);
      staleIds.add(created.id);
    }

    now = DateTime.utc(2026, 7, 10, 12);
    final matched = await hub.quickplay(
      store: store,
      userIdentifier: 'fresh-after-retirement-budget',
      request: CreateMatchRequest(
        name: 'Quickplay',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
        countryId: PlayerCountry.china.name,
      ),
    );
    final staleStates = await Future.wait([
      for (final id in staleIds) store.findState(id),
    ]);

    expect(matched.id, isNot(isIn(staleIds)));
    expect(
      staleStates.where((state) => state!.match.state == 'abandoned'),
      hasLength(multiplayerQuickplayCandidateRetirementLimit),
    );
    expect(
      staleStates.where((state) => state!.match.state == 'open'),
      hasLength(2),
    );
  });
}
