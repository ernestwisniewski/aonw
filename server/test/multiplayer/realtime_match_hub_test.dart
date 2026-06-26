import 'dart:async';

import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
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
    expect(save.players.map((player) => player.id), [
      'player-1-owner-user',
      'player-2-guest-user',
    ]);
    expect(gameState.units, hasLength(4));
    expect(gameState.units.map((unit) => unit.ownerPlayerId).toSet(), {
      'player-1-owner-user',
      'player-2-guest-user',
    });
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
      expect(
        resumed.players.map((player) => player.userId),
        containsAll(['owner-user', 'guest-user']),
      );
      expect(snapshot.matchId, started.id);
      expect(GameSave.fromJson(snapshot.save).gameMode, GameMode.multiplayer);
    },
  );

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

  test(
    'broadcasts participant connection state from stream lifecycle',
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
              userIdentifier: guest.userId,
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
      ))!.match.players.firstWhere((player) => player.userId == guest.userId);
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

      final abandoned = (await store.findState(match.id))!;
      expect(abandoned.match.state, 'abandoned');
      expect(abandoned.snapshot.state['phase'], 'abandoned');
      expect(abandoned.snapshot.state['reason'], 'all_players_offline');
    },
  );

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
    expect(ackMessage.ack?.events.single['type'], 'UnitMoved');

    await ownerInput.close();
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
    final guest = match.players.last;

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
          userIdentifier: guest.userId,
          matchId: match.id,
          afterOffset: 0,
          input: guestInput.stream,
        )
        .asBroadcastStream();

    expect((await ownerStream.first).snapshot?.offset, 0);
    expect((await guestStream.first).snapshot?.offset, 0);

    final ownerAck = ownerStream.firstWhere((message) => message.ack != null);
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
    expect(eventMessage.event?.command?['type'], 'SubmitTurn');
    await expectLater(ownerBroadcastEvent, throwsA(isA<TimeoutException>()));

    final reconnectInput = StreamController<MultiplayerClientMessage>();
    final reconnectStream = hub
        .connect(
          store: store,
          userIdentifier: guest.userId,
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

    await ownerInput.close();
    await guestInput.close();
    await reconnectInput.close();
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
            userIdentifier: guest.userId,
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
            userIdentifier: guest.userId,
            matchId: match.id,
            afterOffset: guestInitial.offset,
            input: reconnectInput.stream,
          )
          .asBroadcastStream();
      final reconnectMessage = await reconnectStream.first;

      expect(reconnectMessage.offset, ackMessage.offset);
      expect(
        reconnectMessage.snapshot?.toJson(),
        authoritative!.snapshot.toJson(),
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
          maxPlayers: 1,
          minPlayers: 1,
          private: false,
        ),
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
}

Matcher _multiplayerError(String code) {
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
  Future<List<StoredMatchState>> listVisibleMatchStates(
    String userIdentifier,
  ) async {
    return [
      for (final state in _states.values)
        if (_isVisibleToUser(state.match, userIdentifier)) state,
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
