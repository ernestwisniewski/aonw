part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubQueryProjectionsScenarios() {
  test(
    'loadMatch resumes a persisted running match for a participant',
    () async {
      final mapCatalog = _FakeMapCatalog(_testMap());
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
      );
      final store = _MemoryMatchStore();
      final match = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: CreateMatchRequest(
          name: 'Resume match',
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

      final resumed = await hub.loadMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: started.id,
        snapshotFactory: InitialMultiplayerSnapshotFactory(
          mapCatalog: mapCatalog,
        ),
      );
      final snapshot = await hub.loadSnapshot(
        store: store,
        userIdentifier: 'guest-user',
        matchId: started.id,
      );

      expect(resumed.id, started.id);
      expect(resumed.state, 'running');
      expect(resumed.turn, 1);
      expect(resumed.players.first.userId, resumed.players.first.id);
      expect(resumed.players.last.userId, 'guest-user');
      expect(resumed.toJson().toString(), isNot(contains('owner-user')));
      expect(snapshot.matchId, started.id);
      expect(GameSave.fromJson(snapshot.save).gameMode, GameMode.multiplayer);
    },
  );
  test('projects snapshot requests and event history per recipient', () async {
    final fixture = await _startRunningMatch('recipient-views');
    final owner = fixture.match.players.first;
    final guest = fixture.match.players.last;
    final stored = (await fixture.store.findState(fixture.match.id))!;
    final canonicalState = CanonicalGameSnapshotCodec.decodeDomainState(
      stored.snapshot.state,
    );
    final stateWithCanaries = canonicalState.copyWith(
      playerGold: {owner.id: 111, guest.id: 999},
    );
    await fixture.store.saveState(
      stored.copyWith(
        snapshot: stored.snapshot.copyWith(
          state: CanonicalGameSnapshotCodec.encodeDomainState(
            stateWithCanaries,
          ),
        ),
      ),
    );

    final input = StreamController<MultiplayerClientMessage>();
    final stream = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: 'guest-user-recipient-views',
          matchId: fixture.match.id,
          afterOffset: 0,
          input: input.stream,
        )
        .asBroadcastStream();
    final initial = await stream.first;
    expect(
      CanonicalGameSnapshotCodec.decodeDomainState(
        initial.snapshot!.state,
      ).playerGold,
      {guest.id: 999},
    );

    final requestedSnapshot = stream.firstWhere(
      (message) => message.snapshot != null,
    );
    input.add(
      MultiplayerClientMessage(
        clientMessageId: 'guest-snapshot-request',
        lastSeenOffset: 0,
        requestSnapshot: true,
      ),
    );
    final requested = await requestedSnapshot;
    expect(
      CanonicalGameSnapshotCodec.decodeDomainState(
        requested.snapshot!.state,
      ).playerGold,
      {guest.id: 999},
    );
    expect(requested.toJson().toString(), isNot(contains('owner-user')));

    final latest = (await fixture.store.findState(fixture.match.id))!;
    final event = WireEvent(
      matchId: fixture.match.id,
      offset: 1,
      timestamp: DateTime.utc(2026, 7, 10),
      actorPlayerId: owner.id,
      tick: 1,
      command: const {'type': 'owner-command', 'secret': 'owner-only'},
      events: const [
        {'type': 'resolution', 'secret': 'canonical-event-secret'},
      ],
      movementExecutions: WireMovementExecutionList(const []),
    );
    await fixture.store.appendEvent(
      latest.copyWith(snapshot: latest.snapshot.copyWith(offset: 1)),
      event,
      actorPlayerId: owner.id,
      clientMessageId: 'owner-event',
    );

    final ownerHistory = await fixture.hub.listEvents(
      store: fixture.store,
      userIdentifier: 'owner-user-recipient-views',
      matchId: fixture.match.id,
      afterOffset: 0,
    );
    final guestHistory = await fixture.hub.listEvents(
      store: fixture.store,
      userIdentifier: 'guest-user-recipient-views',
      matchId: fixture.match.id,
      afterOffset: 0,
    );
    expect(ownerHistory.single.command?['type'], 'owner-command');
    expect(ownerHistory.single.events, isEmpty);
    expect(guestHistory.single.actorPlayerId, isNull);
    expect(guestHistory.single.tick, isNull);
    expect(guestHistory.single.command, isNull);
    expect(guestHistory.single.events, isEmpty);
    expect(
      (await fixture.store.listEvents(fixture.match.id, 0)).single.events,
      isNotEmpty,
    );

    await input.close();
  });
  test(
    'returns stable bounded event pages after the requested offset',
    () async {
      final fixture = await _startRunningMatch('bounded-event-pages');
      final owner = fixture.match.players.first;
      var state = (await fixture.store.findState(fixture.match.id))!;
      const eventCount = multiplayerEventPageSize + 2;
      for (var offset = 1; offset <= eventCount; offset += 1) {
        state = state.copyWith(
          snapshot: state.snapshot.copyWith(offset: offset),
        );
        await fixture.store.appendEvent(
          state,
          WireEvent(
            matchId: fixture.match.id,
            offset: offset,
            timestamp: DateTime.utc(2026, 7, 10).add(Duration(seconds: offset)),
            actorPlayerId: owner.id,
            tick: offset,
            command: {'type': 'paged-command-$offset'},
            events: const [],
            movementExecutions: WireMovementExecutionList(const []),
          ),
          actorPlayerId: owner.id,
          clientMessageId: 'paged-command-$offset',
        );
      }

      final firstPage = await fixture.hub.listEvents(
        store: fixture.store,
        userIdentifier: owner.userId,
        matchId: fixture.match.id,
        afterOffset: 0,
      );
      final secondPage = await fixture.hub.listEvents(
        store: fixture.store,
        userIdentifier: owner.userId,
        matchId: fixture.match.id,
        afterOffset: firstPage.last.offset,
      );

      expect(firstPage, hasLength(multiplayerEventPageSize));
      expect(
        firstPage.map((event) => event.offset),
        orderedEquals(
          List.generate(multiplayerEventPageSize, (index) => index + 1),
        ),
      );
      expect(secondPage.map((event) => event.offset), [
        multiplayerEventPageSize + 1,
        multiplayerEventPageSize + 2,
      ]);
    },
  );
  test('returns a generic error for malformed snapshot projections', () async {
    final logs = <String>[];
    final fixture = await _startRunningMatch(
      'malformed-projection',
      operationalEvents: _recordingOperationalEvents(logs),
    );
    final stored = (await fixture.store.findState(fixture.match.id))!;
    await fixture.store.saveState(
      stored.copyWith(
        snapshot: stored.snapshot.copyWith(
          save: const {'secret': 'must-not-escape'},
        ),
      ),
    );

    await expectLater(
      fixture.hub.loadSnapshot(
        store: fixture.store,
        userIdentifier: 'owner-user-malformed-projection',
        matchId: fixture.match.id,
      ),
      throwsA(
        _multiplayerError('snapshot_projection_failed').having(
          (error) => error.message,
          'message',
          isNot(contains('must-not-escape')),
        ),
      ),
    );
    expect(
      logs,
      contains(
        startsWith(
          'event=multiplayer_projection_failed '
          'match_id=${fixture.match.id} surface=snapshot error_type=',
        ),
      ),
    );
    expect(logs.join(' '), isNot(contains('must-not-escape')));
  });
  test('listMatches returns public lobbies and own active matches', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();

    final publicLobby = await hub.createMatch(
      store: store,
      userIdentifier: 'public-owner',
      request: CreateMatchRequest(
        name: 'Public lobby',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    final privateLobby = await hub.createMatch(
      store: store,
      userIdentifier: 'private-owner',
      request: CreateMatchRequest(
        name: 'Private lobby',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: true,
      ),
    );
    final runningOpen = await hub.createMatch(
      store: store,
      userIdentifier: 'resume-owner',
      request: CreateMatchRequest(
        name: 'Running match',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    await hub.joinMatch(
      store: store,
      userIdentifier: 'viewer-user',
      matchId: runningOpen.id,
    );
    final running = await hub.startMatch(
      store: store,
      userIdentifier: 'resume-owner',
      matchId: runningOpen.id,
      snapshotFactory: InitialMultiplayerSnapshotFactory(
        mapCatalog: mapCatalog,
      ),
    );
    final finishedOpen = await hub.createMatch(
      store: store,
      userIdentifier: 'finished-owner',
      request: CreateMatchRequest(
        name: 'Finished match',
        mapName: 'verdantia',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    await hub.resignMatch(
      store: store,
      userIdentifier: 'finished-owner',
      matchId: finishedOpen.id,
    );

    final visible = await hub.listMatches(
      store: store,
      userIdentifier: 'viewer-user',
    );
    final privateOwnerVisible = await hub.listMatches(
      store: store,
      userIdentifier: 'private-owner',
    );

    expect(visible.map((match) => match.id), [running.id, publicLobby.id]);
    expect(
      privateOwnerVisible.map((match) => match.id),
      contains(privateLobby.id),
    );
    expect(visible.map((match) => match.id), isNot(contains(privateLobby.id)));
    expect(visible.map((match) => match.id), isNot(contains(finishedOpen.id)));
  });
  test(
    'listMatches bounds public discovery without starving participant matches',
    () async {
      final hub = RealtimeMatchHub();
      final store = _MemoryMatchStore();
      final baseTime = DateTime.utc(2026, 7, 10);
      const viewer = 'bounded-list-viewer';

      final privateMatch = await hub.createMatch(
        store: store,
        userIdentifier: viewer,
        request: CreateMatchRequest(
          name: 'Private resumable match',
          mapName: 'verdantia',
          maxPlayers: 2,
          minPlayers: 2,
          private: true,
        ),
      );
      var privateState = (await store.findState(privateMatch.id))!;
      privateState = privateState.copyWith(
        match: privateState.match.copyWith(createdAt: baseTime),
      );
      await store.saveState(privateState);

      final publicMatches = <WireMatch>[];
      const publicCount = multiplayerVisiblePublicLobbyLimit + 4;
      for (var index = 0; index < publicCount; index += 1) {
        final viewerOwnsMatch = index == 0 || index == publicCount - 1;
        final created = await hub.createMatch(
          store: store,
          userIdentifier: viewerOwnsMatch ? viewer : 'public-owner-$index',
          request: CreateMatchRequest(
            name: 'Public lobby $index',
            mapName: 'verdantia',
            maxPlayers: 2,
            minPlayers: 2,
            private: false,
          ),
        );
        var state = (await store.findState(created.id))!;
        state = state.copyWith(
          match: state.match.copyWith(
            createdAt: baseTime.add(Duration(seconds: index + 1)),
          ),
        );
        await store.saveState(state);
        publicMatches.add(state.match);
      }

      final visible = await hub.listMatches(
        store: store,
        userIdentifier: viewer,
      );
      final newestPublicIds = publicMatches.reversed
          .take(multiplayerVisiblePublicLobbyLimit)
          .map((match) => match.id)
          .toList();

      expect(visible, hasLength(multiplayerVisiblePublicLobbyLimit + 2));
      expect(visible.map((match) => match.id), [
        ...newestPublicIds,
        publicMatches.first.id,
        privateMatch.id,
      ]);
      expect(
        visible.map((match) => match.id).toSet(),
        hasLength(visible.length),
      );
    },
  );
}
