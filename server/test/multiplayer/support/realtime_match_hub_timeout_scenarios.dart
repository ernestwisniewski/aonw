part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubTimeoutScenarios() {
  _registerRealtimeMatchHubTimeoutActorTests();

  test('advanceTimedOutTurns finalizes a stored partial turn', () async {
    final fixture = await _partialTurnTimeoutFixture();

    final input = StreamController<MultiplayerClientMessage>();
    final stream = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: 'guest-user',
          matchId: fixture.started.id,
          afterOffset: 0,
          input: input.stream,
        )
        .asBroadcastStream();
    await stream.first;
    final timeoutUpdate = stream.firstWhere((message) => message.event != null);

    fixture.advanceClock();
    await fixture.hub.advanceTimedOutTurns(store: fixture.store);
    final projectedUpdate = await timeoutUpdate;

    final updated = (await fixture.store.findState(fixture.started.id))!;
    final updatedSave = GameSave.fromJson(updated.snapshot.save);
    final events = await fixture.store.listEvents(fixture.started.id, 0);
    expect(updatedSave.turn, 2);
    expect(updated.match.state, 'finished');
    expect(updated.match.endedAt, fixture.now());
    expect(updated.match.outcomeCondition, 'conquest');
    expect(updated.match.winnerPlayerId, fixture.ownerPlayerId);
    expect(projectedUpdate.match?.state, 'finished');
    expect(events, hasLength(1));
    expect(events.single.turn, fixture.running.match.turn);
    expect(projectedUpdate.event?.turn, fixture.running.match.turn);
    expect(
      events.single.events
          .map(GameEventSerializer.fromJson)
          .whereType<PlayerTimedOutEvent>(),
      hasLength(1),
    );
    expect(
      projectedUpdate.event!.events.map(GameEventSerializer.fromJson).toList(),
      unorderedEquals([
        isA<PlayerTimedOutEvent>(),
        isA<AllPlayersSubmittedEvent>(),
        isA<TurnEndedEvent>(),
      ]),
    );
    expect(
      CanonicalGameSnapshotCodec.decodeDomainState(
        projectedUpdate.snapshot!.state,
      ).playerGold,
      {fixture.guestPlayerId: 999},
    );

    await input.close();
  });

  test(
    'advanceTimedOutTurns finalizes a stored turn with no submissions',
    () async {
      final mapCatalog = TestMapCatalog(testMap());
      var now = DateTime.utc(2026, 6, 30, 13);
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(
          mapCatalog: mapCatalog,
          turnTimeout: const Duration(seconds: 10),
        ),
        nowUtc: () => now,
      );
      final store = TestMatchStore();
      final started = await startRunningTestMatch(
        hub: hub,
        store: store,
        suffix: 'timeout-empty',
        mapCatalog: mapCatalog,
      );
      final running = (await store.findState(started.id))!;
      final persistentState = CanonicalGameSnapshotCodec.decodeDomainState(
        running.snapshot.state,
      );
      await store.saveState(
        running.copyWith(
          snapshot: running.snapshot.copyWith(
            state: persistentState
                .copyWith(submittedPlayerIds: const {}, turnStartedAt: now)
                .toJson(),
          ),
        ),
      );

      now = now.add(const Duration(seconds: 11));
      await hub.advanceTimedOutTurns(store: store);

      final updated = (await store.findState(started.id))!;
      final updatedSave = GameSave.fromJson(updated.snapshot.save);
      final updatedState = CanonicalGameSnapshotCodec.decodeDomainState(
        updated.snapshot.state,
      );
      final events = await store.listEvents(started.id, 0);
      final timedOutEvents = events.single.events
          .map(GameEventSerializer.fromJson)
          .whereType<PlayerTimedOutEvent>()
          .toList();

      expect(updatedSave.turn, 2);
      expect(timedOutEvents.map((event) => event.playerId).toSet(), {
        for (final player in started.players) player.id,
      });
      expect(updatedState.timeoutStreaksByPlayerId, {
        for (final player in started.players) player.id: 1,
      });
    },
  );

  test('emits no timeout event when transaction commit fails', () async {
    final mapCatalog = TestMapCatalog(testMap());
    var now = DateTime.utc(2026, 6, 30, 13, 30);
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(
        mapCatalog: mapCatalog,
        turnTimeout: const Duration(seconds: 10),
      ),
      nowUtc: () => now,
    );
    final store = _CommitFailingMatchStore();
    final started = await startRunningTestMatch(
      hub: hub,
      store: store,
      suffix: 'timeout-commit-failure',
      mapCatalog: mapCatalog,
    );
    final running = (await store.findState(started.id))!;
    final persistentState = CanonicalGameSnapshotCodec.decodeDomainState(
      running.snapshot.state,
    );
    await store.saveState(
      running.copyWith(
        snapshot: running.snapshot.copyWith(
          state: persistentState
              .copyWith(submittedPlayerIds: const {}, turnStartedAt: now)
              .toJson(),
        ),
      ),
    );

    final input = StreamController<MultiplayerClientMessage>();
    final initial = Completer<void>();
    final messages = <MultiplayerServerMessage>[];
    var recordMessages = false;
    final subscription = hub
        .connect(
          store: store,
          userIdentifier: started.ownerUserId,
          matchId: started.id,
          afterOffset: 0,
          input: input.stream,
        )
        .listen((message) {
          if (message.snapshot != null && !initial.isCompleted) {
            initial.complete();
          } else if (recordMessages) {
            messages.add(message);
          }
        });
    await initial.future.timeout(const Duration(seconds: 1));

    recordMessages = true;
    store.failNextCommit();
    now = now.add(const Duration(seconds: 11));
    await hub.advanceTimedOutTurns(store: store);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(messages.where((message) => message.event != null), isEmpty);
    expect(
      GameSave.fromJson(
        (await store.findState(started.id))!.snapshot.save,
      ).turn,
      1,
    );
    expect(await store.listEvents(started.id, 0), isEmpty);

    await subscription.cancel();
    await input.close();
  });

  test('advanceTimedOutTurns continues after a match sweep failure', () async {
    final mapCatalog = TestMapCatalog(testMap());
    var now = DateTime.utc(2026, 6, 30, 14);
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(
        mapCatalog: mapCatalog,
        turnTimeout: const Duration(seconds: 10),
      ),
      nowUtc: () => now,
    );
    final store = _FindStateFailingMatchStore();
    final failing = await startRunningTestMatch(
      hub: hub,
      store: store,
      suffix: 'timeout-failing',
      mapCatalog: mapCatalog,
    );
    final healthy = await startRunningTestMatch(
      hub: hub,
      store: store,
      suffix: 'timeout-healthy',
      mapCatalog: mapCatalog,
    );
    for (final match in [failing, healthy]) {
      final running = (await store.findState(match.id))!;
      final persistentState = CanonicalGameSnapshotCodec.decodeDomainState(
        running.snapshot.state,
      );
      await store.saveState(
        running.copyWith(
          snapshot: running.snapshot.copyWith(
            state: persistentState
                .copyWith(submittedPlayerIds: const {}, turnStartedAt: now)
                .toJson(),
          ),
        ),
      );
    }
    store.failFindStateFor(failing.id);

    now = now.add(const Duration(seconds: 11));
    final failures = await hub.advanceTimedOutTurns(store: store);

    final failedState = (await store.findState(failing.id))!;
    final healthyState = (await store.findState(healthy.id))!;
    expect(failures, hasLength(1));
    expect(failures.single.matchId, failing.id);
    expect(
      failures.single.error,
      isA<StateError>().having(
        (error) => error.message,
        'message',
        'Injected findState failure for ${failing.id}',
      ),
    );
    expect(failures.single.stackTrace.toString(), isNotEmpty);
    expect(GameSave.fromJson(failedState.snapshot.save).turn, 1);
    expect(GameSave.fromJson(healthyState.snapshot.save).turn, 2);
  });

  test(
    'advanceTimedOutTurns skips snapshots from older protocol versions',
    () async {
      final mapCatalog = TestMapCatalog(testMap());
      var now = DateTime.utc(2026, 6, 30, 15);
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(
          mapCatalog: mapCatalog,
          turnTimeout: const Duration(seconds: 10),
        ),
        nowUtc: () => now,
      );
      final store = TestMatchStore();
      final stale = await startRunningTestMatch(
        hub: hub,
        store: store,
        suffix: 'timeout-stale-protocol',
        mapCatalog: mapCatalog,
      );
      final healthy = await startRunningTestMatch(
        hub: hub,
        store: store,
        suffix: 'timeout-current-protocol',
        mapCatalog: mapCatalog,
      );
      for (final match in [stale, healthy]) {
        final running = (await store.findState(match.id))!;
        final persistentState = CanonicalGameSnapshotCodec.decodeDomainState(
          running.snapshot.state,
        );
        await store.saveState(
          running.copyWith(
            snapshot: running.snapshot.copyWith(
              v: match.id == stale.id ? kLegacySnapshotEventVersion - 1 : null,
              state: persistentState
                  .copyWith(submittedPlayerIds: const {}, turnStartedAt: now)
                  .toJson(),
            ),
          ),
        );
      }

      now = now.add(const Duration(seconds: 11));
      await hub.advanceTimedOutTurns(store: store);

      final staleState = (await store.findState(stale.id))!;
      final healthyState = (await store.findState(healthy.id))!;
      expect(GameSave.fromJson(staleState.snapshot.save).turn, 1);
      expect(GameSave.fromJson(healthyState.snapshot.save).turn, 2);
    },
  );

  test('advanceTimedOutTurns rotates bounded running-match pages', () async {
    final hub = RealtimeMatchHub();
    final store = TestMatchStore();
    final createdAt = DateTime.utc(2126, 7, 11, 8);
    const matchCount = multiplayerRunningMatchPageSize + 2;
    for (var index = 0; index < matchCount; index += 1) {
      final id = 'rotation-${index.toString().padLeft(3, '0')}';
      store._states[id] = StoredMatchState(
        match: WireMatch(
          id: id,
          ownerUserId: 'rotation-owner',
          name: 'Rotation $index',
          mapName: 'verdantia',
          players: const [],
          maxPlayers: 2,
          minPlayers: 2,
          turn: 1,
          state: 'running',
          createdAt: createdAt,
        ),
        snapshot: WireSnapshot(
          v: kLegacySnapshotEventVersion - 1,
          matchId: id,
          offset: 0,
          save: const {},
          state: const {},
        ),
      );
    }

    await hub.advanceTimedOutTurns(store: store);
    await hub.advanceTimedOutTurns(store: store);
    await hub.advanceTimedOutTurns(store: store);

    expect(store.runningPages, hasLength(3));
    expect(store.runningPages[0], hasLength(multiplayerRunningMatchPageSize));
    expect(store.runningPages[0].first, 'rotation-000');
    expect(store.runningPages[0].last, 'rotation-063');
    expect(store.runningPages[1], ['rotation-064', 'rotation-065']);
    expect(store.runningPages[2], store.runningPages[0]);
    expect(store.runningCursors, [
      null,
      RunningMatchCursor(createdAt: createdAt, publicId: 'rotation-063'),
      null,
    ]);
  });

  test(
    'advanceTimedOutTurns wraps without an empty exactly-full page',
    () async {
      final hub = RealtimeMatchHub();
      final store = TestMatchStore();
      final createdAt = DateTime.utc(2126, 7, 11, 8);
      for (var index = 0; index < multiplayerRunningMatchPageSize; index++) {
        final id = 'exact-page-${index.toString().padLeft(3, '0')}';
        store._states[id] = StoredMatchState(
          match: WireMatch(
            id: id,
            ownerUserId: 'exact-page-owner',
            name: 'Exact page $index',
            mapName: 'verdantia',
            players: const [],
            maxPlayers: 2,
            minPlayers: 2,
            turn: 1,
            state: 'running',
            createdAt: createdAt,
          ),
          snapshot: WireSnapshot(
            v: kLegacySnapshotEventVersion - 1,
            matchId: id,
            offset: 0,
            save: const {},
            state: const {},
          ),
        );
      }

      await hub.advanceTimedOutTurns(store: store);
      await hub.advanceTimedOutTurns(store: store);

      expect(store.runningPages, hasLength(2));
      expect(store.runningPages[0], hasLength(multiplayerRunningMatchPageSize));
      expect(store.runningPages[1], store.runningPages[0]);
      expect(store.runningCursors, [null, null]);
    },
  );
}
