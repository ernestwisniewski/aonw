part of '../realtime_match_hub_test.dart';

void _registerRealtimeMatchHubTimeoutActorTests() {
  group('RealtimeMatchHub timeout actor selection', () {
    test('prefers a submitted player over an earlier fallback', () async {
      final fixture = await _createTimeoutActorFixture('submitted-first');

      final observation = await fixture.run(
        state: fixture.state.copyWith(
          submittedPlayerIds: {fixture.highPlayerId},
        ),
      );

      _expectAcceptedTimeoutActor(observation, fixture.highPlayerId);
    });

    test('chooses the first submitted player in Wire order', () async {
      final fixture = await _createTimeoutActorFixture('submitted-lexical');

      final observation = await fixture.run(
        match: fixture.match.copyWith(
          players: [fixture.highWirePlayer, fixture.lowWirePlayer],
        ),
        save: fixture.save.copyWith(
          players: [fixture.highDomainPlayer, fixture.lowDomainPlayer],
        ),
        state: fixture.state.copyWith(
          participants: [fixture.highDomainPlayer, fixture.lowDomainPlayer],
          submittedPlayerIds: {fixture.lowPlayerId, fixture.highPlayerId},
        ),
      );

      _expectAcceptedTimeoutActor(observation, fixture.highPlayerId);
    });

    test('chooses the first fallback player in Wire order', () async {
      final fixture = await _createTimeoutActorFixture('fallback-lexical');

      final observation = await fixture.run(
        match: fixture.match.copyWith(
          players: [fixture.highWirePlayer, fixture.lowWirePlayer],
        ),
        save: fixture.save.copyWith(
          players: [fixture.highDomainPlayer, fixture.lowDomainPlayer],
        ),
        state: fixture.state.copyWith(
          participants: [fixture.highDomainPlayer, fixture.lowDomainPlayer],
        ),
      );

      _expectAcceptedTimeoutActor(observation, fixture.highPlayerId);
    });

    test('skips a kicked submitted player', () async {
      final fixture = await _createTimeoutActorFixture('kicked-submitted');

      final observation = await fixture.run(
        state: fixture.state.copyWith(
          submittedPlayerIds: {fixture.highPlayerId},
          kickedPlayerIds: {fixture.highPlayerId},
        ),
      );

      _expectAcceptedTimeoutActor(observation, fixture.lowPlayerId);
    });

    test('skips a kicked lexical fallback player', () async {
      final fixture = await _createTimeoutActorFixture('kicked-fallback');

      final observation = await fixture.run(
        state: fixture.state.copyWith(kickedPlayerIds: {fixture.lowPlayerId}),
      );

      _expectAcceptedTimeoutActor(observation, fixture.highPlayerId);
    });

    test('honors a canonical submitted participant', () async {
      final fixture = await _createTimeoutActorFixture('wire-phantom');
      const phantomId = '000-wire-only';
      final phantomWirePlayer = fixture.lowWirePlayer.copyWith(
        id: phantomId,
        userId: 'wire-only-user',
        name: 'Wire only',
      );
      final phantomDomainPlayer = fixture.lowDomainPlayer.copyWith(
        id: phantomId,
        name: 'Wire only',
      );

      final observation = await fixture.run(
        match: fixture.match.copyWith(
          players: [phantomWirePlayer, ...fixture.match.players],
          maxPlayers: fixture.match.maxPlayers + 1,
        ),
        save: fixture.save.copyWith(
          players: [phantomDomainPlayer, ...fixture.save.players],
          playerStates: {
            ...fixture.save.playerStates,
            phantomId: PlayerTurnState.active,
          },
        ),
        state: fixture.state.copyWith(
          participants: [phantomDomainPlayer, ...fixture.state.participants],
          submittedPlayerIds: const {phantomId},
        ),
      );

      _expectAcceptedTimeoutActor(observation, phantomId);
    });

    test('rejects a save-only participant outside Wire', () async {
      final fixture = await _createTimeoutActorFixture('save-phantom');
      const phantomId = '000-save-only';

      final failure = await fixture.runExpectingRosterFailure(
        save: fixture.save.copyWith(
          players: [
            fixture.lowDomainPlayer.copyWith(id: phantomId, name: 'Save only'),
            ...fixture.save.players,
          ],
          playerStates: {
            ...fixture.save.playerStates,
            phantomId: PlayerTurnState.active,
          },
        ),
      );

      _expectRosterFailure(failure);
    });

    test('honors a canonical persistent-state participant', () async {
      final fixture = await _createTimeoutActorFixture('state-phantom');
      const phantomId = '000-state-only';
      final phantomWirePlayer = fixture.lowWirePlayer.copyWith(
        id: phantomId,
        userId: 'state-only-user',
        name: 'State only',
      );
      final phantomDomainPlayer = fixture.lowDomainPlayer.copyWith(
        id: phantomId,
        name: 'State only',
      );

      final observation = await fixture.run(
        match: fixture.match.copyWith(
          players: [phantomWirePlayer, ...fixture.match.players],
          maxPlayers: fixture.match.maxPlayers + 1,
        ),
        save: fixture.save.copyWith(
          players: [phantomDomainPlayer, ...fixture.save.players],
          playerStates: {
            ...fixture.save.playerStates,
            phantomId: PlayerTurnState.active,
          },
        ),
        state: fixture.state.copyWith(
          participants: [phantomDomainPlayer, ...fixture.state.participants],
          playerGold: {...fixture.state.playerGold, phantomId: 999},
          submittedPlayerIds: const {phantomId},
        ),
      );

      _expectAcceptedTimeoutActor(observation, phantomId);
    });

    test('canonicalizes a participant missing its sparse turn state', () async {
      final fixture = await _createTimeoutActorFixture('save-player-only');

      final observation = await fixture.run(
        save: fixture.save.copyWith(
          playerStates: {
            for (final entry in fixture.save.playerStates.entries)
              if (entry.key != fixture.highPlayerId) entry.key: entry.value,
          },
        ),
        state: fixture.state.copyWith(
          submittedPlayerIds: {fixture.highPlayerId},
        ),
      );

      _expectAcceptedTimeoutActor(observation, fixture.highPlayerId);
    });

    test('rejects a roster present only in save.playerStates', () async {
      final fixture = await _createTimeoutActorFixture('player-state-only');

      final failure = await fixture.runExpectingRosterFailure(
        save: fixture.save.copyWith(players: const []),
      );

      _expectRosterFailure(failure);
    });

    test('rejects a Wire roster absent from the snapshot', () async {
      final fixture = await _createTimeoutActorFixture('no-candidate');

      final failure = await fixture.runExpectingRosterFailure(
        match: fixture.match.copyWith(
          players: [
            fixture.lowWirePlayer.copyWith(
              id: 'wire-only-low',
              userId: 'wire-only-low-user',
            ),
            fixture.highWirePlayer.copyWith(
              id: 'wire-only-high',
              userId: 'wire-only-high-user',
            ),
          ],
        ),
      );

      _expectRosterFailure(failure);
    });

    test('rejects a roster split across snapshot sources', () async {
      final fixture = await _createTimeoutActorFixture('inconsistent-active');

      final failure = await fixture.runExpectingRosterFailure(
        save: fixture.save.copyWith(
          players: [fixture.highDomainPlayer],
          playerStates: {fixture.lowPlayerId: PlayerTurnState.active},
        ),
      );

      _expectRosterFailure(failure);
    });
  });
}

Future<_TimeoutActorFixture> _createTimeoutActorFixture(String suffix) async {
  final mapCatalog = _FakeMapCatalog(_testMap());
  final reducer = _CapturingTimeoutActorReducer(
    mapCatalog: mapCatalog,
    turnTimeout: const Duration(seconds: 10),
  );
  final now = DateTime.utc(2026, 7, 21, 12);
  final hub = RealtimeMatchHub(commandReducer: reducer, nowUtc: () => now);
  final store = _MemoryMatchStore();
  final started = await _startRunningMatchInStore(
    hub: hub,
    store: store,
    suffix: 'timeout-actor-$suffix',
    mapCatalog: mapCatalog,
  );
  final stored = (await store.findState(started.id))!;
  final save = GameSave.fromJson(stored.snapshot.save);
  final state = CanonicalGameSnapshotCodec.decodeDomainState(
    stored.snapshot.state,
  );
  final wirePlayers = [...stored.match.players]
    ..sort((left, right) => left.id.compareTo(right.id));
  final domainPlayersById = {
    for (final player in save.players) player.id: player,
  };
  expect(wirePlayers, hasLength(2));
  expect(domainPlayersById.keys, containsAll(wirePlayers.map((p) => p.id)));

  return _TimeoutActorFixture(
    hub: hub,
    store: store,
    reducer: reducer,
    stored: stored,
    save: save,
    state: state,
    lowWirePlayer: wirePlayers.first,
    highWirePlayer: wirePlayers.last,
    lowDomainPlayer: domainPlayersById[wirePlayers.first.id]!,
    highDomainPlayer: domainPlayersById[wirePlayers.last.id]!,
    turnStartedAt: now.subtract(const Duration(seconds: 11)),
  );
}

final class _TimeoutActorFixture {
  const _TimeoutActorFixture({
    required this.hub,
    required this.store,
    required this.reducer,
    required this.stored,
    required this.save,
    required this.state,
    required this.lowWirePlayer,
    required this.highWirePlayer,
    required this.lowDomainPlayer,
    required this.highDomainPlayer,
    required this.turnStartedAt,
  });

  final RealtimeMatchHub hub;
  final _MemoryMatchStore store;
  final _CapturingTimeoutActorReducer reducer;
  final StoredMatchState stored;
  final GameSave save;
  final DomainState state;
  final WirePlayer lowWirePlayer;
  final WirePlayer highWirePlayer;
  final Player lowDomainPlayer;
  final Player highDomainPlayer;
  final DateTime turnStartedAt;

  WireMatch get match => stored.match;
  String get lowPlayerId => lowWirePlayer.id;
  String get highPlayerId => highWirePlayer.id;

  Future<_TimeoutActorObservation> run({
    WireMatch? match,
    GameSave? save,
    DomainState? state,
  }) async {
    final arrangedState = state ?? this.state;
    final timedOutState = arrangedState.copyWith(turnStartedAt: turnStartedAt);
    final before = stored.copyWith(
      match: match ?? this.match,
      snapshot: stored.snapshot.copyWith(
        save: (save ?? this.save).toJson(),
        state: CanonicalGameSnapshotCodec.encodeDomainState(timedOutState),
      ),
    );
    await store.saveState(before);

    final failures = await hub.advanceTimedOutTurns(store: store);
    expect(failures, isEmpty);

    final after = (await store.findState(before.match.id))!;
    return _TimeoutActorObservation(
      before: before,
      after: after,
      actorPlayerIds: List.unmodifiable(reducer.actorPlayerIds),
      events: await store.listEvents(before.match.id, 0),
    );
  }

  Future<({Object error, StackTrace stackTrace})> runExpectingRosterFailure({
    WireMatch? match,
    GameSave? save,
    DomainState? state,
  }) async {
    final arrangedState = state ?? this.state;
    final timedOutState = arrangedState.copyWith(turnStartedAt: turnStartedAt);
    final before = stored.copyWith(
      match: match ?? this.match,
      snapshot: stored.snapshot.copyWith(
        save: (save ?? this.save).toJson(),
        state: CanonicalGameSnapshotCodec.encodeDomainState(timedOutState),
      ),
    );
    await store.saveState(before);

    final failures = await hub.advanceTimedOutTurns(store: store);

    expect(failures, hasLength(1));
    expect(failures.single.matchId, before.match.id);
    expect(reducer.actorPlayerIds, isEmpty);
    expect(await store.listEvents(before.match.id, 0), isEmpty);
    expect(
      (await store.findState(before.match.id))!.snapshot,
      same(before.snapshot),
    );
    return (
      error: failures.single.error,
      stackTrace: failures.single.stackTrace,
    );
  }
}

final class _TimeoutActorObservation {
  const _TimeoutActorObservation({
    required this.before,
    required this.after,
    required this.actorPlayerIds,
    required this.events,
  });

  final StoredMatchState before;
  final StoredMatchState after;
  final List<String> actorPlayerIds;
  final List<WireEvent> events;
}

final class _CapturingTimeoutActorReducer extends ServerCommandReducer {
  _CapturingTimeoutActorReducer({
    required super.mapCatalog,
    required super.turnTimeout,
  });

  final List<String> actorPlayerIds = [];

  @override
  Future<ServerCommandReduction> reduceTimedOutTurn({
    required WireMatch match,
    required CanonicalGameSnapshot snapshot,
    required String actorPlayerId,
    required DateTime now,
  }) {
    actorPlayerIds.add(actorPlayerId);
    return super.reduceTimedOutTurn(
      match: match,
      snapshot: snapshot,
      actorPlayerId: actorPlayerId,
      now: now,
    );
  }
}

void _expectRosterFailure(({Object error, StackTrace stackTrace}) failure) {
  expect(
    failure.error,
    isA<FormatException>().having(
      (error) => error.message,
      'message',
      'Running snapshot roster must exactly match authoritative players.',
    ),
  );
  expect(failure.stackTrace.toString(), isNotEmpty);
}

void _expectAcceptedTimeoutActor(
  _TimeoutActorObservation observation,
  String actorPlayerId,
) {
  expect(observation.actorPlayerIds, [actorPlayerId]);
  expect(
    GameSave.fromJson(observation.after.snapshot.save).turn,
    GameSave.fromJson(observation.before.snapshot.save).turn + 1,
  );
  expect(observation.events, hasLength(1));
  final event = observation.events.single;
  expect(event.actorPlayerId, actorPlayerId);
  final record = RecordedSystemCommand.fromJson(event.command!);
  expect(record.command, isA<FinalizeTimedOutTurn>());
  expect(
    (record.command as FinalizeTimedOutTurn).playerIds,
    contains(actorPlayerId),
  );
}
