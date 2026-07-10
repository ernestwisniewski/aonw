import 'dart:async';

import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/invite_code_generator.dart';
import 'package:aonw_server/src/multiplayer/match_broadcaster.dart';
import 'package:aonw_server/src/multiplayer/match_connection_registry.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_endpoint.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:test/test.dart';

void main() {
  test(
    'quickplay preserves requested civilizations for lobby players',
    () async {
      final hub = RealtimeMatchHub();
      final store = _MemoryMatchStore();

      final waiting = await hub.quickplay(
        store: store,
        userIdentifier: 'owner-user',
        request: CreateMatchRequest(
          name: 'Quickplay',
          mapName: 'test_map',
          maxPlayers: 3,
          minPlayers: 2,
          private: false,
          countryId: PlayerCountry.japan.name,
        ),
      );
      expect(waiting.players.single.country, PlayerCountry.japan);
      expect(waiting.maxPlayers, 4);
      expect(waiting.minPlayers, 2);
      expect(waiting.quickplay, isTrue);
      expect(waiting.autoStartAt, isNull);

      final joined = await hub.quickplay(
        store: store,
        userIdentifier: 'guest-user',
        request: CreateMatchRequest(
          name: 'Quickplay',
          mapName: 'test_map',
          maxPlayers: 3,
          minPlayers: 2,
          private: false,
          countryId: PlayerCountry.france.name,
        ),
      );

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
    },
  );

  test(
    'quickplay starts after two players and a 30 second countdown',
    () async {
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
          mapName: 'test_map',
          maxPlayers: 2,
          minPlayers: 2,
          private: false,
          countryId: PlayerCountry.japan.name,
        ),
      );

      expect(waiting.state, 'open');
      expect(waiting.maxPlayers, 4);
      expect(waiting.minPlayers, 2);
      expect(waiting.autoStartAt, isNull);

      final countingDown = await hub.quickplay(
        store: store,
        userIdentifier: 'guest-user',
        request: CreateMatchRequest(
          name: 'Ignored',
          mapName: 'test_map',
          maxPlayers: 2,
          minPlayers: 2,
          private: false,
          countryId: PlayerCountry.france.name,
        ),
      );

      expect(countingDown.state, 'open');
      expect(countingDown.autoStartAt, DateTime.utc(2026, 6, 12, 9, 0, 30));

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
      expect(started.mapName, isNot('test_map'));
      expect(
        MapPlayerCapacityRules.official.map((profile) => profile.mapName),
        contains(started.mapName),
      );
      final save = GameSave.fromJson(state!.snapshot.save);
      expect(save.mapName, started.mapName);
      expect(save.players, hasLength(2));
    },
  );

  test('quickplay updates a returning player civilization selection', () async {
    final now = DateTime.utc(2026, 6, 12, 9);
    final hub = RealtimeMatchHub(nowUtc: () => now);
    final store = _MemoryMatchStore();

    final first = await hub.quickplay(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Quickplay',
        mapName: 'test_map',
        maxPlayers: 4,
        minPlayers: 2,
        private: false,
        countryId: PlayerCountry.poland.name,
      ),
    );
    expect(first.players.single.country, PlayerCountry.poland);

    final updated = await hub.quickplay(
      store: store,
      userIdentifier: 'owner-user',
      displayName: 'Owner Renamed',
      request: CreateMatchRequest(
        name: 'Quickplay',
        mapName: 'test_map',
        maxPlayers: 4,
        minPlayers: 2,
        private: false,
        countryId: PlayerCountry.china.name,
      ),
    );

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
        mapName: 'test_map',
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
        mapName: 'test_map',
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

    Future<WireMatch> quickplay(String user, PlayerCountry country) {
      return hub.quickplay(
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

  test('startMatch persists a full initial game snapshot', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();
    final match = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Test match',
        mapName: 'test_map',
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
    final gameState = PersistentGameState.fromJson(state.snapshot.state);

    expect(started.state, 'running');
    expect(started.turn, 1);
    expect(save.id, match.id);
    expect(save.gameMode, GameMode.multiplayer);
    expect(save.turn, 1);
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
  });

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
          mapName: 'test_map',
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
    final canonicalState = PersistentGameState.fromJson(stored.snapshot.state);
    final stateWithCanaries = canonicalState.copyWith(
      playerGold: {owner.id: 111, guest.id: 999},
    );
    await fixture.store.saveState(
      stored.copyWith(
        snapshot: stored.snapshot.copyWith(state: stateWithCanaries.toJson()),
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
    expect(PersistentGameState.fromJson(initial.snapshot!.state).playerGold, {
      guest.id: 999,
    });

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
    expect(PersistentGameState.fromJson(requested.snapshot!.state).playerGold, {
      guest.id: 999,
    });
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

  test('returns a generic error for malformed snapshot projections', () async {
    final fixture = await _startRunningMatch('malformed-projection');
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
        mapName: 'test_map',
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
        mapName: 'test_map',
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
        mapName: 'test_map',
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
        mapName: 'test_map',
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

    expect(visible.map((match) => match.id), [publicLobby.id, running.id]);
    expect(
      privateOwnerVisible.map((match) => match.id),
      contains(privateLobby.id),
    );
    expect(visible.map((match) => match.id), isNot(contains(privateLobby.id)));
    expect(visible.map((match) => match.id), isNot(contains(finishedOpen.id)));
  });

  test(
    'leaveMatch keeps a running match resumable while another player is active',
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
          name: 'Abandoned match',
          mapName: 'test_map',
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

      await hub.leaveMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: started.id,
      );

      final state = await store.findState(started.id);
      expect(state!.match.state, 'running');
      expect(state.snapshot.state['phase'], isNot('abandoned'));
      expect(
        state.match.players
            .firstWhere((player) => player.userId == 'guest-user')
            .connectionState,
        WirePlayerConnectionState.offline,
      );
      expect(
        state.match.players
            .firstWhere((player) => player.userId == 'owner-user')
            .connectionState,
        WirePlayerConnectionState.connected,
      );

      final resumed = await hub.loadMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: started.id,
        snapshotFactory: InitialMultiplayerSnapshotFactory(
          mapCatalog: mapCatalog,
        ),
      );
      expect(resumed.state, 'running');
      expect(resumed.id, started.id);
    },
  );

  test(
    'leaveMatch abandons a running match with no active players left',
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
          name: 'Abandoned match',
          mapName: 'test_map',
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
      final running = (await store.findState(started.id))!;
      await store.saveState(
        running.copyWith(
          match: running.match.copyWith(
            players: [
              for (final player in running.match.players)
                player.userId == 'owner-user'
                    ? player.copyWith(
                        connectionState: WirePlayerConnectionState.offline,
                      )
                    : player,
            ],
          ),
        ),
      );

      await hub.leaveMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: started.id,
      );

      final state = await store.findState(started.id);
      expect(state!.match.state, 'abandoned');
      expect(state.match.autoStartAt, isNull);
      expect(state.snapshot.state['phase'], 'abandoned');
      expect(state.snapshot.state['reason'], 'player_left');
      expect(state.snapshot.state['leftUserIdentifier'], 'guest-user');
    },
  );

  test('emits no lifecycle update when transaction commit fails', () async {
    final hub = RealtimeMatchHub();
    final store = _CommitFailingMatchStore();
    final match = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-lifecycle-commit-failure',
      request: CreateMatchRequest(
        name: 'Lifecycle commit failure',
        mapName: 'test_map',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    final input = StreamController<MultiplayerClientMessage>();
    final initial = Completer<void>();
    final messages = <MultiplayerServerMessage>[];
    var recordMessages = false;
    final subscription = hub
        .connect(
          store: store,
          userIdentifier: match.ownerUserId,
          matchId: match.id,
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
    await expectLater(
      hub.resignMatch(
        store: store,
        userIdentifier: match.ownerUserId,
        matchId: match.id,
      ),
      throwsA(isA<StateError>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(messages.where((message) => message.match != null), isEmpty);
    expect((await store.findState(match.id))!.match.state, 'open');

    await subscription.cancel();
    await input.close();
  });

  test('advanceTimedOutTurns finalizes a stored partial turn', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    var now = DateTime.utc(2026, 6, 30, 12);
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(
        mapCatalog: mapCatalog,
        turnTimeout: const Duration(seconds: 10),
      ),
      nowUtc: () => now,
    );
    final store = _MemoryMatchStore();
    final match = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Timeout match',
        mapName: 'test_map',
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
    final running = (await store.findState(started.id))!;
    final ownerPlayerId = running.match.players
        .firstWhere((player) => player.userId == 'owner-user')
        .id;
    final guestPlayerId = running.match.players
        .firstWhere((player) => player.userId == 'guest-user')
        .id;
    final save = GameSave.fromJson(running.snapshot.save);
    final persistentState = PersistentGameState.fromJson(
      running.snapshot.state,
    );
    await store.saveState(
      running.copyWith(
        snapshot: running.snapshot.copyWith(
          save: save
              .copyWith(
                playerStates: {
                  ...save.playerStates,
                  ownerPlayerId: PlayerTurnState.finished,
                },
              )
              .toJson(),
          state: persistentState
              .copyWith(
                playerGold: {ownerPlayerId: 111, guestPlayerId: 999},
                runtimeState: persistentState.runtimeState.copyWith(
                  submittedPlayerIds: {ownerPlayerId},
                  turnStartedAt: now,
                ),
              )
              .toJson(),
        ),
      ),
    );

    final input = StreamController<MultiplayerClientMessage>();
    final stream = hub
        .connect(
          store: store,
          userIdentifier: 'guest-user',
          matchId: started.id,
          afterOffset: 0,
          input: input.stream,
        )
        .asBroadcastStream();
    await stream.first;
    final timeoutUpdate = stream.firstWhere((message) => message.event != null);

    now = now.add(const Duration(seconds: 11));
    await hub.advanceTimedOutTurns(store: store);
    final projectedUpdate = await timeoutUpdate;

    final updated = (await store.findState(started.id))!;
    final updatedSave = GameSave.fromJson(updated.snapshot.save);
    final events = await store.listEvents(started.id, 0);
    expect(updatedSave.turn, 2);
    expect(events, hasLength(1));
    expect(
      events.single.events
          .map(GameEventSerializer.fromJson)
          .whereType<PlayerTimedOutEvent>(),
      hasLength(1),
    );
    expect(projectedUpdate.event?.events, isEmpty);
    expect(
      PersistentGameState.fromJson(projectedUpdate.snapshot!.state).playerGold,
      {guestPlayerId: 999},
    );

    await input.close();
  });

  test(
    'advanceTimedOutTurns finalizes a stored turn with no submissions',
    () async {
      final mapCatalog = _FakeMapCatalog(_testMap());
      var now = DateTime.utc(2026, 6, 30, 13);
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(
          mapCatalog: mapCatalog,
          turnTimeout: const Duration(seconds: 10),
        ),
        nowUtc: () => now,
      );
      final store = _MemoryMatchStore();
      final started = await _startRunningMatchInStore(
        hub: hub,
        store: store,
        suffix: 'timeout-empty',
        mapCatalog: mapCatalog,
      );
      final running = (await store.findState(started.id))!;
      final persistentState = PersistentGameState.fromJson(
        running.snapshot.state,
      );
      await store.saveState(
        running.copyWith(
          snapshot: running.snapshot.copyWith(
            state: persistentState
                .copyWith(
                  runtimeState: persistentState.runtimeState.copyWith(
                    submittedPlayerIds: const {},
                    turnStartedAt: now,
                  ),
                )
                .toJson(),
          ),
        ),
      );

      now = now.add(const Duration(seconds: 11));
      await hub.advanceTimedOutTurns(store: store);

      final updated = (await store.findState(started.id))!;
      final updatedSave = GameSave.fromJson(updated.snapshot.save);
      final updatedState = PersistentGameState.fromJson(updated.snapshot.state);
      final events = await store.listEvents(started.id, 0);
      final timedOutEvents = events.single.events
          .map(GameEventSerializer.fromJson)
          .whereType<PlayerTimedOutEvent>()
          .toList();

      expect(updatedSave.turn, 2);
      expect(timedOutEvents.map((event) => event.playerId).toSet(), {
        for (final player in started.players) player.id,
      });
      expect(updatedState.runtimeState.timeoutStreaksByPlayerId, {
        for (final player in started.players) player.id: 1,
      });
    },
  );

  test('emits no timeout event when transaction commit fails', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    var now = DateTime.utc(2026, 6, 30, 13, 30);
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(
        mapCatalog: mapCatalog,
        turnTimeout: const Duration(seconds: 10),
      ),
      nowUtc: () => now,
    );
    final store = _CommitFailingMatchStore();
    final started = await _startRunningMatchInStore(
      hub: hub,
      store: store,
      suffix: 'timeout-commit-failure',
      mapCatalog: mapCatalog,
    );
    final running = (await store.findState(started.id))!;
    final persistentState = PersistentGameState.fromJson(
      running.snapshot.state,
    );
    await store.saveState(
      running.copyWith(
        snapshot: running.snapshot.copyWith(
          state: persistentState
              .copyWith(
                runtimeState: persistentState.runtimeState.copyWith(
                  submittedPlayerIds: const {},
                  turnStartedAt: now,
                ),
              )
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
    final mapCatalog = _FakeMapCatalog(_testMap());
    var now = DateTime.utc(2026, 6, 30, 14);
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(
        mapCatalog: mapCatalog,
        turnTimeout: const Duration(seconds: 10),
      ),
      nowUtc: () => now,
    );
    final store = _FindStateFailingMatchStore();
    final failing = await _startRunningMatchInStore(
      hub: hub,
      store: store,
      suffix: 'timeout-failing',
      mapCatalog: mapCatalog,
    );
    final healthy = await _startRunningMatchInStore(
      hub: hub,
      store: store,
      suffix: 'timeout-healthy',
      mapCatalog: mapCatalog,
    );
    for (final match in [failing, healthy]) {
      final running = (await store.findState(match.id))!;
      final persistentState = PersistentGameState.fromJson(
        running.snapshot.state,
      );
      await store.saveState(
        running.copyWith(
          snapshot: running.snapshot.copyWith(
            state: persistentState
                .copyWith(
                  runtimeState: persistentState.runtimeState.copyWith(
                    submittedPlayerIds: const {},
                    turnStartedAt: now,
                  ),
                )
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
      final mapCatalog = _FakeMapCatalog(_testMap());
      var now = DateTime.utc(2026, 6, 30, 15);
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(
          mapCatalog: mapCatalog,
          turnTimeout: const Duration(seconds: 10),
        ),
        nowUtc: () => now,
      );
      final store = _MemoryMatchStore();
      final stale = await _startRunningMatchInStore(
        hub: hub,
        store: store,
        suffix: 'timeout-stale-protocol',
        mapCatalog: mapCatalog,
      );
      final healthy = await _startRunningMatchInStore(
        hub: hub,
        store: store,
        suffix: 'timeout-current-protocol',
        mapCatalog: mapCatalog,
      );
      for (final match in [stale, healthy]) {
        final running = (await store.findState(match.id))!;
        final persistentState = PersistentGameState.fromJson(
          running.snapshot.state,
        );
        await store.saveState(
          running.copyWith(
            snapshot: running.snapshot.copyWith(
              v: match.id == stale.id ? kProtocolVersion - 1 : null,
              state: persistentState
                  .copyWith(
                    runtimeState: persistentState.runtimeState.copyWith(
                      submittedPlayerIds: const {},
                      turnStartedAt: now,
                    ),
                  )
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

  test(
    'resignMatch keeps a running FFA alive until one player remains',
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
          name: 'FFA resign',
          mapName: 'test_map',
          maxPlayers: 3,
          minPlayers: 3,
          private: false,
        ),
      );
      await hub.joinMatch(
        store: store,
        userIdentifier: 'guest-one',
        matchId: match.id,
      );
      await hub.joinMatch(
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
      final runningState = PersistentGameState.fromJson(running.snapshot.state);

      expect(afterFirstResign.state, 'running');
      expect(firstGuest.connectionState, WirePlayerConnectionState.offline);
      expect(runningSave.playerStates[firstGuest.id], PlayerTurnState.finished);
      expect(
        runningState.runtimeState.kickedPlayerIds,
        contains(firstGuest.id),
      );

      final afterSecondResign = await hub.resignMatch(
        store: store,
        userIdentifier: 'guest-two',
        matchId: started.id,
      );

      expect(afterSecondResign.state, 'finished');
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
    'keeps a running match resumable when stream clients disconnect',
    () async {
      final mapCatalog = _FakeMapCatalog(_testMap());
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
      );
      final store = _MemoryMatchStore();
      final openMatch = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: CreateMatchRequest(
          name: 'Presence match',
          mapName: 'test_map',
          maxPlayers: 2,
          minPlayers: 2,
          private: false,
        ),
      );
      final joined = await hub.joinMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: openMatch.id,
      );
      final match = await hub.startMatch(
        store: store,
        userIdentifier: 'owner-user',
        matchId: joined.id,
        snapshotFactory: InitialMultiplayerSnapshotFactory(
          mapCatalog: mapCatalog,
        ),
      );
      final owner = match.players.first;
      final guest = match.players.last;

      final ownerInput = StreamController<MultiplayerClientMessage>();
      final ownerInitial = Completer<void>();
      final guestOffline = Completer<WireMatch>();
      final guestConnectedAgain = Completer<WireMatch>();
      final ownerSubscription = hub
          .connect(
            store: store,
            userIdentifier: owner.userId,
            matchId: match.id,
            afterOffset: 0,
            input: ownerInput.stream,
          )
          .listen((message) {
            if (message.snapshot != null && !ownerInitial.isCompleted) {
              ownerInitial.complete();
            }
            final match = message.match;
            if (match == null) return;
            final guestPlayer = match.players.firstWhere(
              (player) => player.userId == guest.userId,
            );
            if (guestPlayer.connectionState ==
                    WirePlayerConnectionState.offline &&
                !guestOffline.isCompleted) {
              guestOffline.complete(match);
              return;
            }
            if (guestOffline.isCompleted &&
                guestPlayer.connectionState ==
                    WirePlayerConnectionState.connected &&
                !guestConnectedAgain.isCompleted) {
              guestConnectedAgain.complete(match);
            }
          });
      await ownerInitial.future.timeout(const Duration(seconds: 1));

      Future<StreamSubscription<MultiplayerServerMessage>> connectGuest(
        StreamController<MultiplayerClientMessage> input,
      ) async {
        final initial = Completer<void>();
        final subscription = hub
            .connect(
              store: store,
              userIdentifier: 'guest-user',
              matchId: match.id,
              afterOffset: 0,
              input: input.stream,
            )
            .listen((message) {
              if (message.snapshot != null && !initial.isCompleted) {
                initial.complete();
              }
            });
        await initial.future.timeout(const Duration(seconds: 1));
        return subscription;
      }

      final guestInputA = StreamController<MultiplayerClientMessage>();
      final guestInputB = StreamController<MultiplayerClientMessage>();
      final guestSubscriptionA = await connectGuest(guestInputA);
      final guestSubscriptionB = await connectGuest(guestInputB);

      await guestSubscriptionA.cancel();
      await guestInputA.close();
      final stillConnected = (await store.findState(
        match.id,
      ))!.match.players.firstWhere((player) => player.id == guest.id);
      expect(
        stillConnected.connectionState,
        WirePlayerConnectionState.connected,
      );

      await guestSubscriptionB.cancel();
      await guestInputB.close();
      final offlineMatch = await guestOffline.future.timeout(
        const Duration(seconds: 1),
      );
      expect(
        offlineMatch.players
            .firstWhere((player) => player.userId == guest.userId)
            .connectionState,
        WirePlayerConnectionState.offline,
      );

      final guestInputC = StreamController<MultiplayerClientMessage>();
      final guestSubscriptionC = await connectGuest(guestInputC);
      final connectedMatch = await guestConnectedAgain.future.timeout(
        const Duration(seconds: 1),
      );
      expect(
        connectedMatch.players
            .firstWhere((player) => player.userId == guest.userId)
            .connectionState,
        WirePlayerConnectionState.connected,
      );

      await guestSubscriptionC.cancel();
      await guestInputC.close();
      await ownerSubscription.cancel();
      await ownerInput.close();

      final disconnected = (await store.findState(match.id))!;
      expect(disconnected.match.state, 'running');
      expect(disconnected.snapshot.state['phase'], isNot('abandoned'));
      expect(
        disconnected.match.players.map((player) => player.connectionState),
        everyElement(WirePlayerConnectionState.offline),
      );

      final resumed = await hub.loadMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: match.id,
        snapshotFactory: InitialMultiplayerSnapshotFactory(
          mapCatalog: mapCatalog,
        ),
      );
      expect(resumed.state, 'running');
    },
  );

  test('rejects a forged connection authorization before emitting', () async {
    final fixture = await _startRunningMatch('forged-authorization');
    final stored = (await fixture.store.findState(fixture.match.id))!;
    final victim = stored.match.players.last;
    final registry = MatchConnectionRegistry();
    final broadcaster = MatchBroadcaster(registry);
    final input = StreamController<MultiplayerClientMessage>();
    final messages = <MultiplayerServerMessage>[];
    final error = Completer<Object>();
    final done = Completer<void>();

    final subscription = registry
        .connect(
          store: fixture.store,
          userIdentifier: 'owner-user-forged-authorization',
          matchId: fixture.match.id,
          afterOffset: 0,
          input: input.stream,
          authorize:
              ({
                required MultiplayerMatchStore store,
                required String matchId,
                required String userIdentifier,
              }) async => MatchConnectionAuthorization(
                state: stored,
                participant: victim,
              ),
          updateConnectionState:
              ({
                required MultiplayerMatchStore store,
                required String matchId,
                required String userIdentifier,
                required WirePlayerConnectionState connectionState,
              }) async => stored,
          handleClientMessage:
              ({
                required MultiplayerMatchStore store,
                required String matchId,
                required String userIdentifier,
                required MultiplayerClientMessage message,
                required MatchMessageTarget caller,
              }) async {},
          createMessage: broadcaster.message,
        )
        .listen(
          messages.add,
          onError: (Object value) {
            if (!error.isCompleted) error.complete(value);
          },
          onDone: done.complete,
        );

    await done.future.timeout(const Duration(seconds: 1));
    expect(await error.future, _multiplayerError('authorization_mismatch'));
    expect(messages, isEmpty);

    await subscription.cancel();
    unawaited(input.close());
  });

  test('projects rejected command acknowledgements for the caller', () async {
    final fixture = await _startRunningMatch('rejected-ack');
    final owner = fixture.match.players.first;
    final guest = fixture.match.players.last;
    final stored = (await fixture.store.findState(fixture.match.id))!;
    final canonicalState = PersistentGameState.fromJson(stored.snapshot.state);
    await fixture.store.saveState(
      stored.copyWith(
        snapshot: stored.snapshot.copyWith(
          state: canonicalState
              .copyWith(playerGold: {owner.id: 111, guest.id: 999})
              .toJson(),
        ),
      ),
    );
    final input = StreamController<MultiplayerClientMessage>();
    final stream = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: 'owner-user-rejected-ack',
          matchId: fixture.match.id,
          afterOffset: 0,
          input: input.stream,
        )
        .asBroadcastStream();
    await stream.first;
    final acknowledgement = stream.firstWhere((message) => message.ack != null);

    input.add(
      MultiplayerClientMessage(
        clientMessageId: 'forged-actor-command',
        lastSeenOffset: 0,
        requestSnapshot: false,
        command: WireCommand(
          matchId: fixture.match.id,
          tick: 1,
          turn: 1,
          actorPlayerId: guest.id,
          command: GameCommandSerializer.toJson(SubmitTurnCommand(guest.id)),
        ),
      ),
    );
    final ack = (await acknowledgement).ack!;

    expect(ack.accepted, isFalse);
    expect(ack.events, isEmpty);
    expect(PersistentGameState.fromJson(ack.snapshot.state).playerGold, {
      owner.id: 111,
    });
    expect(await fixture.store.listEvents(fixture.match.id, 0), isEmpty);

    await input.close();
  });

  test('moves units through the authoritative server reducer', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();
    final openMatch = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Test match',
        mapName: 'myranth',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    final joined = await hub.joinMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: openMatch.id,
    );
    final match = await hub.startMatch(
      store: store,
      userIdentifier: 'owner-user',
      matchId: joined.id,
      snapshotFactory: InitialMultiplayerSnapshotFactory(
        mapCatalog: mapCatalog,
      ),
    );
    final owner = match.players.first;
    final initialState = PersistentGameState.fromJson(
      (await store.findState(match.id))!.snapshot.state,
    );
    final ownerUnit = initialState.units.firstWhere(
      (unit) => unit.ownerPlayerId == owner.id,
    );
    final occupied = {
      for (final unit in initialState.units) '${unit.col}:${unit.row}',
    };
    final target = _testMap().tiles.firstWhere(
      (tile) =>
          !occupied.contains('${tile.col}:${tile.row}') &&
          (tile.col - ownerUnit.col).abs() <= 1 &&
          (tile.row - ownerUnit.row).abs() <= 1 &&
          (tile.col != ownerUnit.col || tile.row != ownerUnit.row),
    );

    final ownerInput = StreamController<MultiplayerClientMessage>();
    final ownerStream = hub
        .connect(
          store: store,
          userIdentifier: owner.userId,
          matchId: match.id,
          afterOffset: 0,
          input: ownerInput.stream,
        )
        .asBroadcastStream();

    expect((await ownerStream.first).snapshot?.offset, 0);

    final ownerAck = ownerStream.firstWhere((message) => message.ack != null);

    ownerInput.add(
      MultiplayerClientMessage(
        clientMessageId: 'client-1',
        lastSeenOffset: 0,
        requestSnapshot: false,
        command: WireCommand(
          matchId: match.id,
          tick: 1,
          turn: 1,
          actorPlayerId: owner.id,
          command: GameCommandSerializer.toJson(
            MoveUnitCommand(ownerUnit.id, target.col, target.row),
          ),
        ),
      ),
    );

    final ackMessage = await ownerAck;
    final nextState = PersistentGameState.fromJson(
      ackMessage.ack!.snapshot.state,
    );
    final moved = nextState.units.firstWhere((unit) => unit.id == ownerUnit.id);

    expect(ackMessage.ack?.accepted, isTrue);
    expect(moved.col, target.col);
    expect(moved.row, target.row);
    expect(ackMessage.ack?.events, isEmpty);

    await ownerInput.close();
  });

  test('routes diplomacy commands through the authoritative hub', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();
    final openMatch = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Diplomacy match',
        mapName: 'test_map',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    final joined = await hub.joinMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: openMatch.id,
    );
    final match = await hub.startMatch(
      store: store,
      userIdentifier: 'owner-user',
      matchId: joined.id,
      snapshotFactory: InitialMultiplayerSnapshotFactory(
        mapCatalog: mapCatalog,
      ),
    );
    final owner = match.players.first;
    final guest = match.players.last;

    final stored = (await store.findState(match.id))!;
    final baseState = PersistentGameState.fromJson(stored.snapshot.state);
    final patchedState = baseState.copyWith(
      playerGold: {owner.id: 20, guest.id: 0},
      runtimeState: baseState.runtimeState.copyWith(
        diplomacy: DiplomacyState.empty.addContact(owner.id, guest.id),
      ),
    );
    await store.saveState(
      stored.copyWith(
        snapshot: stored.snapshot.copyWith(state: patchedState.toJson()),
      ),
    );

    final ownerInput = StreamController<MultiplayerClientMessage>();
    final secondOwnerInput = StreamController<MultiplayerClientMessage>();
    final guestInput = StreamController<MultiplayerClientMessage>();
    final ownerStream = hub
        .connect(
          store: store,
          userIdentifier: owner.userId,
          matchId: match.id,
          afterOffset: 0,
          input: ownerInput.stream,
        )
        .asBroadcastStream();
    final guestStream = hub
        .connect(
          store: store,
          userIdentifier: 'guest-user',
          matchId: match.id,
          afterOffset: 0,
          input: guestInput.stream,
        )
        .asBroadcastStream();
    final secondOwnerStream = hub
        .connect(
          store: store,
          userIdentifier: owner.userId,
          matchId: match.id,
          afterOffset: 0,
          input: secondOwnerInput.stream,
        )
        .asBroadcastStream();

    expect((await ownerStream.first).snapshot?.offset, 0);
    expect((await guestStream.first).snapshot?.offset, 0);
    expect((await secondOwnerStream.first).snapshot?.offset, 0);

    final ownerAck = ownerStream.firstWhere((message) => message.ack != null);
    final guestEvent = guestStream.firstWhere(
      (message) => message.event != null,
    );
    final secondOwnerEvent = secondOwnerStream.firstWhere(
      (message) => message.event != null,
    );

    ownerInput.add(
      MultiplayerClientMessage(
        clientMessageId: 'client-diplomacy-1',
        lastSeenOffset: 0,
        requestSnapshot: false,
        command: WireCommand(
          matchId: match.id,
          tick: 1,
          turn: 1,
          actorPlayerId: owner.id,
          command: GameCommandSerializer.toJson(
            SendGoldGiftCommand(
              playerId: owner.id,
              targetPlayerId: guest.id,
              amount: 10,
            ),
          ),
        ),
      ),
    );

    final ackMessage = await ownerAck;
    final eventMessage = await guestEvent;
    final secondOwnerEventMessage = await secondOwnerEvent;
    final nextState = PersistentGameState.fromJson(
      ackMessage.ack!.snapshot.state,
    );

    expect(ackMessage.ack?.accepted, isTrue);
    expect(nextState.playerGold[owner.id], 10);
    expect(nextState.playerGold, isNot(contains(guest.id)));
    expect(
      nextState.runtimeState.diplomacy.relationScoreBetween(owner.id, guest.id),
      2,
    );
    expect(ackMessage.ack?.events, isEmpty);
    expect(eventMessage.event?.command, isNull);
    expect(eventMessage.event?.events, isEmpty);
    expect(secondOwnerEventMessage.event?.actorPlayerId, owner.id);
    expect(secondOwnerEventMessage.event?.command, isNotNull);
    expect(secondOwnerEventMessage.event?.events, isEmpty);
    expect(
      PersistentGameState.fromJson(eventMessage.snapshot!.state).playerGold,
      {guest.id: 10},
    );

    await ownerInput.close();
    await secondOwnerInput.close();
    await guestInput.close();
  });

  test('broadcasts accepted commands with one authoritative offset', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();
    final openMatch = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Test match',
        mapName: 'test_map',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    final joined = await hub.joinMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: openMatch.id,
    );
    final match = await hub.startMatch(
      store: store,
      userIdentifier: 'owner-user',
      matchId: joined.id,
      snapshotFactory: InitialMultiplayerSnapshotFactory(
        mapCatalog: mapCatalog,
      ),
    );
    final owner = match.players.first;

    final ownerInput = StreamController<MultiplayerClientMessage>();
    final guestInput = StreamController<MultiplayerClientMessage>();
    final ownerStream = hub
        .connect(
          store: store,
          userIdentifier: owner.userId,
          matchId: match.id,
          afterOffset: 0,
          input: ownerInput.stream,
        )
        .asBroadcastStream();
    final guestStream = hub
        .connect(
          store: store,
          userIdentifier: 'guest-user',
          matchId: match.id,
          afterOffset: 0,
          input: guestInput.stream,
        )
        .asBroadcastStream();

    expect((await ownerStream.first).snapshot?.offset, 0);
    expect((await guestStream.first).snapshot?.offset, 0);

    final ownerAck = ownerStream.firstWhere((message) => message.ack != null);
    final ownerAckMessages = <MultiplayerServerMessage>[];
    final guestEventMessages = <MultiplayerServerMessage>[];
    final ownerAckSubscription = ownerStream
        .where((message) => message.ack != null)
        .listen(ownerAckMessages.add);
    final guestEventSubscription = guestStream
        .where((message) => message.event != null)
        .listen(guestEventMessages.add);
    final ownerBroadcastEvent = ownerStream
        .firstWhere((message) => message.event != null)
        .timeout(const Duration(milliseconds: 100));
    final guestEvent = guestStream.firstWhere(
      (message) => message.event != null,
    );

    ownerInput.add(
      MultiplayerClientMessage(
        clientMessageId: 'client-1',
        lastSeenOffset: 0,
        requestSnapshot: false,
        command: WireCommand(
          matchId: match.id,
          tick: 1,
          turn: 1,
          actorPlayerId: owner.id,
          command: GameCommandSerializer.toJson(SubmitTurnCommand(owner.id)),
        ),
      ),
    );

    final ackMessage = await ownerAck;
    final eventMessage = await guestEvent;

    expect(ackMessage.ack?.accepted, isTrue);
    expect(ackMessage.offset, eventMessage.offset);
    expect(ackMessage.ack?.offset, eventMessage.event?.offset);
    expect(eventMessage.event?.actorPlayerId, isNull);
    expect(eventMessage.event?.command, isNull);
    expect(eventMessage.event?.events, isEmpty);
    expect(ownerAckMessages, [same(ackMessage)]);
    expect(guestEventMessages, [same(eventMessage)]);
    expect((await store.findState(match.id))!.offset, ackMessage.offset);
    await expectLater(ownerBroadcastEvent, throwsA(isA<TimeoutException>()));

    final reconnectInput = StreamController<MultiplayerClientMessage>();
    final reconnectStream = hub
        .connect(
          store: store,
          userIdentifier: 'guest-user',
          matchId: match.id,
          afterOffset: 0,
          input: reconnectInput.stream,
        )
        .asBroadcastStream();
    expect((await reconnectStream.first).snapshot?.offset, eventMessage.offset);
    await expectLater(
      reconnectStream
          .firstWhere((message) => message.event != null)
          .timeout(const Duration(milliseconds: 50)),
      throwsA(isA<TimeoutException>()),
    );

    await ownerAckSubscription.cancel();
    await guestEventSubscription.cancel();
    await ownerInput.close();
    await guestInput.close();
    await reconnectInput.close();
  });

  test('emits no command messages when transaction commit fails', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _CommitFailingMatchStore();
    final match = await _startRunningMatchInStore(
      hub: hub,
      store: store,
      suffix: 'command-commit-failure',
      mapCatalog: mapCatalog,
    );
    final owner = match.players.first;
    final guestInput = StreamController<MultiplayerClientMessage>();
    final ownerInput = StreamController<MultiplayerClientMessage>();
    final guestInitial = Completer<void>();
    final ownerInitial = Completer<void>();
    final ownerError = Completer<Object>();
    final guestMessages = <MultiplayerServerMessage>[];
    final callerMessages = <MultiplayerServerMessage>[];
    final guestSubscription = hub
        .connect(
          store: store,
          userIdentifier: 'guest-user-command-commit-failure',
          matchId: match.id,
          afterOffset: 0,
          input: guestInput.stream,
        )
        .listen((message) {
          if (message.snapshot != null && !guestInitial.isCompleted) {
            guestInitial.complete();
          } else {
            guestMessages.add(message);
          }
        });
    final ownerSubscription = hub
        .connect(
          store: store,
          userIdentifier: owner.userId,
          matchId: match.id,
          afterOffset: 0,
          input: ownerInput.stream,
        )
        .listen(
          (message) {
            if (message.snapshot != null && !ownerInitial.isCompleted) {
              ownerInitial.complete();
            } else {
              callerMessages.add(message);
            }
          },
          onError: (Object error) {
            if (!ownerError.isCompleted) ownerError.complete(error);
          },
        );
    await Future.wait([
      guestInitial.future,
      ownerInitial.future,
    ]).timeout(const Duration(seconds: 1));

    store.failNextCommit();
    ownerInput.add(
      MultiplayerClientMessage(
        clientMessageId: 'client-commit-failure',
        lastSeenOffset: 0,
        requestSnapshot: false,
        command: WireCommand(
          matchId: match.id,
          tick: 1,
          turn: 1,
          actorPlayerId: owner.id,
          command: GameCommandSerializer.toJson(SubmitTurnCommand(owner.id)),
        ),
      ),
    );
    expect(
      await ownerError.future.timeout(const Duration(seconds: 1)),
      isA<StateError>(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(callerMessages, isEmpty);
    expect(guestMessages.where((message) => message.event != null), isEmpty);
    expect((await store.findState(match.id))!.offset, 0);
    expect(await store.listEvents(match.id, 0), isEmpty);

    await guestSubscription.cancel();
    await ownerSubscription.cancel();
    await guestInput.close();
    await ownerInput.close();
  });

  test(
    'reconnects an offline client to the latest authoritative snapshot',
    () async {
      final mapCatalog = _FakeMapCatalog(_testMap());
      final hub = RealtimeMatchHub(
        commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
      );
      final store = _MemoryMatchStore();
      final openMatch = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: CreateMatchRequest(
          name: 'Reconnect smoke',
          mapName: 'test_map',
          maxPlayers: 2,
          minPlayers: 2,
          private: false,
        ),
      );
      final joined = await hub.joinMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: openMatch.id,
      );
      final match = await hub.startMatch(
        store: store,
        userIdentifier: 'owner-user',
        matchId: joined.id,
        snapshotFactory: InitialMultiplayerSnapshotFactory(
          mapCatalog: mapCatalog,
        ),
      );
      final owner = match.players.first;
      final guest = match.players.last;

      final guestInitialInput = StreamController<MultiplayerClientMessage>();
      final guestInitialStream = hub
          .connect(
            store: store,
            userIdentifier: 'guest-user',
            matchId: match.id,
            afterOffset: 0,
            input: guestInitialInput.stream,
          )
          .asBroadcastStream();
      final guestInitial = await guestInitialStream.first;
      expect(guestInitial.snapshot?.offset, 0);
      await guestInitialInput.close();

      final ownerInput = StreamController<MultiplayerClientMessage>();
      final ownerStream = hub
          .connect(
            store: store,
            userIdentifier: owner.userId,
            matchId: match.id,
            afterOffset: 0,
            input: ownerInput.stream,
          )
          .asBroadcastStream();
      expect((await ownerStream.first).snapshot?.offset, 0);
      final ownerAck = ownerStream.firstWhere((message) => message.ack != null);
      ownerInput.add(
        MultiplayerClientMessage(
          clientMessageId: 'owner-submit-1',
          lastSeenOffset: 0,
          requestSnapshot: false,
          command: WireCommand(
            matchId: match.id,
            tick: 1,
            turn: 1,
            actorPlayerId: owner.id,
            command: GameCommandSerializer.toJson(SubmitTurnCommand(owner.id)),
          ),
        ),
      );

      final ackMessage = await ownerAck;
      expect(ackMessage.ack?.accepted, isTrue);

      final authoritative = await store.findState(match.id);
      final reconnectInput = StreamController<MultiplayerClientMessage>();
      final reconnectStream = hub
          .connect(
            store: store,
            userIdentifier: 'guest-user',
            matchId: match.id,
            afterOffset: guestInitial.offset,
            input: reconnectInput.stream,
          )
          .asBroadcastStream();
      final reconnectMessage = await reconnectStream.first;

      expect(reconnectMessage.offset, ackMessage.offset);
      expect(
        reconnectMessage.snapshot?.toJson(),
        isNot(authoritative!.snapshot.toJson()),
      );
      expect(
        PersistentGameState.fromJson(
          reconnectMessage.snapshot!.state,
        ).playerGold.keys,
        everyElement(guest.id),
      );
      await expectLater(
        reconnectStream
            .firstWhere((message) => message.event != null)
            .timeout(const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );

      await ownerInput.close();
      await reconnectInput.close();
    },
  );

  test('acknowledges retried client messages without applying twice', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();
    final openMatch = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Retry smoke',
        mapName: 'test_map',
        maxPlayers: 2,
        minPlayers: 2,
        private: false,
      ),
    );
    final joined = await hub.joinMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: openMatch.id,
    );
    final match = await hub.startMatch(
      store: store,
      userIdentifier: 'owner-user',
      matchId: joined.id,
      snapshotFactory: InitialMultiplayerSnapshotFactory(
        mapCatalog: mapCatalog,
      ),
    );
    final owner = match.players.first;
    final guest = match.players.last;
    final stored = (await store.findState(match.id))!;
    final canonicalState = PersistentGameState.fromJson(stored.snapshot.state);
    await store.saveState(
      stored.copyWith(
        snapshot: stored.snapshot.copyWith(
          state: canonicalState
              .copyWith(playerGold: {owner.id: 111, guest.id: 999})
              .toJson(),
        ),
      ),
    );
    final ownerInput = StreamController<MultiplayerClientMessage>();
    final ownerStream = hub
        .connect(
          store: store,
          userIdentifier: owner.userId,
          matchId: match.id,
          afterOffset: 0,
          input: ownerInput.stream,
        )
        .asBroadcastStream();
    expect((await ownerStream.first).snapshot?.offset, 0);

    final acks = ownerStream
        .where((message) => message.ack != null)
        .take(2)
        .toList();
    final retryMessage = MultiplayerClientMessage(
      clientMessageId: 'owner-submit-retry',
      lastSeenOffset: 0,
      requestSnapshot: false,
      command: WireCommand(
        matchId: match.id,
        tick: 1,
        turn: 1,
        actorPlayerId: owner.id,
        command: GameCommandSerializer.toJson(SubmitTurnCommand(owner.id)),
      ),
    );
    ownerInput.add(retryMessage);
    ownerInput.add(retryMessage);

    final ackMessages = await acks;

    expect(ackMessages.map((message) => message.ack?.accepted), [true, true]);
    expect(ackMessages.map((message) => message.ack?.offset).toSet(), {1});
    for (final message in ackMessages) {
      expect(message.ack!.events, isEmpty);
      expect(
        PersistentGameState.fromJson(
          message.ack!.snapshot.state,
        ).playerGold.keys,
        [owner.id],
      );
    }
    expect(await store.listEvents(match.id, 0), hasLength(1));
    expect((await store.findState(match.id))!.offset, 1);

    await ownerInput.close();
  });

  test('deduplicates retry bursts under duplicate delivery patterns', () async {
    for (final duplicateCount in [2, 3, 5, 8]) {
      final fixture = await _startRunningMatch('retry-burst-$duplicateCount');
      final owner = fixture.match.players.first;
      final ownerInput = StreamController<MultiplayerClientMessage>();
      final ownerStream = fixture.hub
          .connect(
            store: fixture.store,
            userIdentifier: owner.userId,
            matchId: fixture.match.id,
            afterOffset: 0,
            input: ownerInput.stream,
          )
          .asBroadcastStream();
      expect((await ownerStream.first).snapshot?.offset, 0);

      final acks = ownerStream
          .where((message) => message.ack != null)
          .take(duplicateCount)
          .toList();
      final retryMessage = MultiplayerClientMessage(
        clientMessageId: 'owner-submit-retry-burst-$duplicateCount',
        lastSeenOffset: 0,
        requestSnapshot: false,
        command: WireCommand(
          matchId: fixture.match.id,
          tick: 1,
          turn: 1,
          actorPlayerId: owner.id,
          command: GameCommandSerializer.toJson(SubmitTurnCommand(owner.id)),
        ),
      );

      for (var i = 0; i < duplicateCount; i++) {
        ownerInput.add(retryMessage);
      }

      final ackMessages = await acks.timeout(const Duration(seconds: 1));

      expect(
        ackMessages.map((message) => message.ack?.accepted),
        everyElement(isTrue),
      );
      expect(ackMessages.map((message) => message.ack?.offset).toSet(), {1});
      expect(
        ackMessages.map((message) => message.ack?.events).toSet(),
        hasLength(1),
      );
      expect(await fixture.store.listEvents(fixture.match.id, 0), hasLength(1));
      expect((await fixture.store.findState(fixture.match.id))!.offset, 1);

      await ownerInput.close();
    }
  });

  test(
    'throws typed multiplayer exceptions for rejected lobby actions',
    () async {
      final hub = RealtimeMatchHub();
      final store = _MemoryMatchStore();
      final match = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: CreateMatchRequest(
          name: 'Tiny match',
          mapName: 'test_map',
          maxPlayers: 2,
          minPlayers: 2,
          private: false,
        ),
      );
      await hub.joinMatch(
        store: store,
        userIdentifier: 'filler-user',
        matchId: match.id,
      );

      await expectLater(
        hub.joinMatch(
          store: store,
          userIdentifier: 'guest-user',
          matchId: match.id,
        ),
        throwsA(_multiplayerError('match_full')),
      );
      await expectLater(
        hub.joinPrivateMatch(
          store: store,
          userIdentifier: 'guest-user',
          inviteCode: 'missing',
        ),
        throwsA(_multiplayerError('private_match_not_found')),
      );
      await expectLater(
        hub.startMatch(
          store: store,
          userIdentifier: 'guest-user',
          matchId: match.id,
        ),
        throwsA(_multiplayerError('not_match_owner')),
      );
      await expectLater(
        hub.loadMatch(
          store: store,
          userIdentifier: 'owner-user',
          matchId: 'missing-match',
        ),
        throwsA(_multiplayerError('match_not_found')),
      );
      await expectLater(
        hub.loadMatch(
          store: store,
          userIdentifier: 'stranger-user',
          matchId: match.id,
        ),
        throwsA(_multiplayerError('not_match_player')),
      );
    },
  );

  test('rejects joins for private and non-open matches', () async {
    final mapCatalog = _FakeMapCatalog(_testMap());
    final hub = RealtimeMatchHub(
      commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
    );
    final store = _MemoryMatchStore();
    final publicMatch = await hub.createMatch(
      store: store,
      userIdentifier: 'public-owner',
      request: CreateMatchRequest(
        name: 'Public lobby',
        mapName: 'test_map',
        maxPlayers: 3,
        minPlayers: 2,
        private: false,
      ),
    );
    await hub.joinMatch(
      store: store,
      userIdentifier: 'public-guest',
      matchId: publicMatch.id,
    );
    final runningPublic = await hub.startMatch(
      store: store,
      userIdentifier: 'public-owner',
      matchId: publicMatch.id,
      snapshotFactory: InitialMultiplayerSnapshotFactory(
        mapCatalog: mapCatalog,
      ),
    );

    await expectLater(
      hub.joinMatch(
        store: store,
        userIdentifier: 'late-public-guest',
        matchId: runningPublic.id,
      ),
      throwsA(_multiplayerError('match_not_open')),
    );

    final privateMatch = await hub.createMatch(
      store: store,
      userIdentifier: 'private-owner',
      request: CreateMatchRequest(
        name: 'Private lobby',
        mapName: 'test_map',
        maxPlayers: 3,
        minPlayers: 2,
        private: true,
      ),
    );
    await expectLater(
      hub.joinMatch(
        store: store,
        userIdentifier: 'public-id-guest',
        matchId: privateMatch.id,
      ),
      throwsA(_multiplayerError('match_not_found')),
    );
    await hub.joinPrivateMatch(
      store: store,
      userIdentifier: 'private-guest',
      inviteCode: privateMatch.inviteCode!,
    );
    final runningPrivate = await hub.startMatch(
      store: store,
      userIdentifier: 'private-owner',
      matchId: privateMatch.id,
      snapshotFactory: InitialMultiplayerSnapshotFactory(
        mapCatalog: mapCatalog,
      ),
    );

    await expectLater(
      hub.joinPrivateMatch(
        store: store,
        userIdentifier: 'late-private-guest',
        inviteCode: runningPrivate.inviteCode!,
      ),
      throwsA(_multiplayerError('match_not_open')),
    );
  });

  test('private match creation retries an existing invite code', () async {
    const firstCode = 'ABCDEFGHJKLMN';
    const secondCode = 'PQRSTUVWXYZ23';
    final inviteCodeGenerator = _SequenceInviteCodeGenerator([
      firstCode,
      firstCode,
      secondCode,
    ]);
    final hub = RealtimeMatchHub(inviteCodeGenerator: inviteCodeGenerator);
    final store = _MemoryMatchStore();
    final request = CreateMatchRequest(
      name: 'Private lobby',
      mapName: 'test_map',
      maxPlayers: 3,
      minPlayers: 2,
      private: true,
    );

    final first = await hub.createMatch(
      store: store,
      userIdentifier: 'first-owner',
      request: request,
    );
    final second = await hub.createMatch(
      store: store,
      userIdentifier: 'second-owner',
      request: request,
    );

    expect(first.inviteCode, firstCode);
    expect(second.inviteCode, secondCode);
    expect(inviteCodeGenerator.calls, 3);
  });

  test('private match creation retries a concurrent code conflict', () async {
    const firstCode = 'ABCDEFGHJKLMN';
    const secondCode = 'PQRSTUVWXYZ23';
    final inviteCodeGenerator = _SequenceInviteCodeGenerator([
      firstCode,
      secondCode,
    ]);
    final hub = RealtimeMatchHub(inviteCodeGenerator: inviteCodeGenerator);
    final store = _CreateConflictOnceMatchStore();

    final match = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Private lobby',
        mapName: 'test_map',
        maxPlayers: 3,
        minPlayers: 2,
        private: true,
      ),
    );

    expect(match.inviteCode, secondCode);
    expect(inviteCodeGenerator.calls, 2);
  });

  test(
    'private match creation fails after bounded collision retries',
    () async {
      const inviteCode = 'ABCDEFGHJKLMN';
      final inviteCodeGenerator = _SequenceInviteCodeGenerator([inviteCode]);
      final hub = RealtimeMatchHub(inviteCodeGenerator: inviteCodeGenerator);
      final store = _MemoryMatchStore();
      final request = CreateMatchRequest(
        name: 'Private lobby',
        mapName: 'test_map',
        maxPlayers: 3,
        minPlayers: 2,
        private: true,
      );
      await hub.createMatch(
        store: store,
        userIdentifier: 'first-owner',
        request: request,
      );

      await expectLater(
        hub.createMatch(
          store: store,
          userIdentifier: 'second-owner',
          request: request,
        ),
        throwsA(_multiplayerError('invite_code_unavailable')),
      );
      expect(inviteCodeGenerator.calls, 17);
    },
  );
}

TypeMatcher<MultiplayerException> _multiplayerError(String code) {
  return isA<MultiplayerException>().having(
    (error) => error.code,
    'code',
    code,
  );
}

Future<_RunningMatchFixture> _startRunningMatch(String suffix) async {
  final mapCatalog = _FakeMapCatalog(_testMap());
  final hub = RealtimeMatchHub(
    commandReducer: ServerCommandReducer(mapCatalog: mapCatalog),
  );
  final store = _MemoryMatchStore();
  final openMatch = await hub.createMatch(
    store: store,
    userIdentifier: 'owner-user-$suffix',
    request: CreateMatchRequest(
      name: 'Retry burst $suffix',
      mapName: 'test_map',
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

Future<WireMatch> _startRunningMatchInStore({
  required RealtimeMatchHub hub,
  required _MemoryMatchStore store,
  required String suffix,
  required _FakeMapCatalog mapCatalog,
}) async {
  final openMatch = await hub.createMatch(
    store: store,
    userIdentifier: 'owner-user-$suffix',
    request: CreateMatchRequest(
      name: 'Running match $suffix',
      mapName: 'test_map',
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
  return hub.startMatch(
    store: store,
    userIdentifier: 'owner-user-$suffix',
    matchId: joined.id,
    snapshotFactory: InitialMultiplayerSnapshotFactory(mapCatalog: mapCatalog),
  );
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
  final Map<String, StoredMatchState> _states = {};
  final Map<String, List<WireEvent>> _events = {};
  final Map<String, WireEvent> _eventsByClientMessageId = {};

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
    CreateMatchRequest _,
  ) async {
    for (final state in _states.values) {
      final match = state.match;
      if (match.state == 'open' &&
          match.quickplay &&
          match.inviteCode == null &&
          match.players.length < match.maxPlayers) {
        return state;
      }
    }
    return null;
  }

  @override
  Future<List<WireMatch>> listVisibleMatches(String userIdentifier) async {
    return [
      for (final state in _states.values)
        if (_isVisibleToUser(state.match, userIdentifier)) state.match,
    ];
  }

  @override
  Future<List<StoredMatchState>> listRunningStates() async {
    return [
      for (final state in _states.values)
        if (state.match.state == 'running') state,
    ];
  }

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) async {
    return [
      for (final event in _events[matchId] ?? const <WireEvent>[])
        if (event.offset > afterOffset) event,
    ];
  }
}

final class _CreateConflictOnceMatchStore extends _MemoryMatchStore {
  var _conflictPending = true;

  @override
  Future<StoredMatchState> createState(StoredMatchState state) {
    if (_conflictPending && state.match.inviteCode != null) {
      _conflictPending = false;
      throw const InviteCodeConflictException();
    }
    return super.createState(state);
  }
}

final class _SequenceInviteCodeGenerator implements InviteCodeGenerator {
  _SequenceInviteCodeGenerator(this._codes);

  final List<String> _codes;
  var calls = 0;

  @override
  String generate() {
    final code = _codes[calls.clamp(0, _codes.length - 1)];
    calls += 1;
    return code;
  }
}

String _clientMessageKey(
  String matchId,
  String actorPlayerId,
  String clientMessageId,
) {
  return '$matchId:$actorPlayerId:$clientMessageId';
}

bool _isVisibleToUser(WireMatch match, String userIdentifier) {
  final active = match.state == 'open' || match.state == 'running';
  if (!active) return false;
  final participant = match.players.any(
    (player) => player.userId == userIdentifier,
  );
  return participant || (match.state == 'open' && match.inviteCode == null);
}

class _FakeMapCatalog implements MultiplayerMapCatalog {
  const _FakeMapCatalog(this.mapData);

  final MapData mapData;

  @override
  Future<MapData> loadAssetMap(String mapName) async => mapData;
}

MapData _testMap() {
  return MapData(
    cols: 6,
    rows: 6,
    tiles: [
      for (var col = 0; col < 6; col++)
        for (var row = 0; row < 6; row++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 1,
          ),
    ],
  );
}
