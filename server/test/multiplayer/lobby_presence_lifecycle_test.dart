import 'dart:async';

import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_endpoint.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store_limits.dart';
import 'package:aonw_server/src/observability/server_operational_event_sink.dart';
import 'package:test/test.dart';

part 'lobby_presence_expiry_edge_cases.dart';
part 'support/lobby_presence_lifecycle_test_support.dart';

void main() {
  _registerLobbyPresenceExpiryEdgeCases();

  test('broadcasts a public-lobby departure immediately', () async {
    final hub = RealtimeMatchHub();
    final store = _LobbyPresenceStore();
    final match = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: CreateMatchRequest(
        name: 'Live roster',
        mapName: 'verdantia',
        maxPlayers: 3,
        minPlayers: 2,
        private: false,
      ),
    );
    final input = StreamController<MultiplayerClientMessage>();
    final stream = hub
        .connect(
          store: store,
          userIdentifier: 'owner-user',
          matchId: match.id,
          afterOffset: 0,
          input: input.stream,
        )
        .asBroadcastStream();
    await stream.first;
    await hub.joinMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: match.id,
    );
    final rosterUpdate = stream.firstWhere(
      (message) => message.match?.players.length == 1,
    );

    await hub.leaveMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: match.id,
    );

    expect(
      (await rosterUpdate.timeout(
        const Duration(seconds: 1),
      )).match!.players.map((player) => player.userId),
      ['owner-user'],
    );
    await input.close();
  });

  test(
    'broadcasts quickplay joins and retains players when owner leaves',
    () async {
      final hub = RealtimeMatchHub();
      final store = _LobbyPresenceStore();
      final waiting = await _quickplay(
        hub,
        store,
        user: 'owner-user',
        country: PlayerCountry.japan,
      );
      await _quickplay(
        hub,
        store,
        user: 'guest-user',
        country: PlayerCountry.france,
      );
      final input = StreamController<MultiplayerClientMessage>();
      final stream = hub
          .connect(
            store: store,
            userIdentifier: 'guest-user',
            matchId: waiting.id,
            afterOffset: 0,
            input: input.stream,
          )
          .asBroadcastStream();
      await stream.first;

      final thirdJoined = stream.firstWhere(
        (message) => message.match?.players.length == 3,
      );
      await _quickplay(
        hub,
        store,
        user: 'third-user',
        country: PlayerCountry.germany,
      );
      expect((await thirdJoined).match!.players, hasLength(3));

      final ownerLeft = stream.firstWhere(
        (message) =>
            message.match?.ownerUserId == 'guest-user' &&
            message.match?.players.length == 2,
      );
      await hub.leaveMatch(
        store: store,
        userIdentifier: 'owner-user',
        matchId: waiting.id,
      );
      final remaining = (await ownerLeft).match!;
      expect(remaining.state, 'open');
      expect(remaining.players, hasLength(2));
      expect(remaining.players.first.userId, 'guest-user');
      expect(
        remaining.players.map((player) => player.userId),
        isNot(contains('owner-user')),
      );
      await input.close();
    },
  );

  test(
    'guest reconnect grace preserves then expires an open-lobby seat',
    () async {
      var now = DateTime.utc(2026, 8, 8, 12);
      final hub = RealtimeMatchHub(nowUtc: () => now);
      final store = _LobbyPresenceStore();
      final match = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: _hostedRequest(),
      );
      final owner = await _connectParticipant(
        hub: hub,
        store: store,
        userIdentifier: 'owner-user',
        matchId: match.id,
      );
      await hub.joinMatch(
        store: store,
        userIdentifier: 'guest-user',
        matchId: match.id,
      );
      final guest = await _connectParticipant(
        hub: hub,
        store: store,
        userIdentifier: 'guest-user',
        matchId: match.id,
      );

      await guest.close();
      var stored = (await store.findState(match.id))!;
      expect(
        stored.match.players
            .singleWhere((player) => player.userId == 'guest-user')
            .connectionState,
        WirePlayerConnectionState.reconnecting,
      );

      now = now.add(const Duration(seconds: 9));
      expect(await hub.expireLobbyPresence(store: store), isEmpty);
      expect((await store.findState(match.id))!.match.players, hasLength(2));

      now = now.add(const Duration(seconds: 2));
      expect(await hub.expireLobbyPresence(store: store), isEmpty);
      stored = (await store.findState(match.id))!;
      expect(stored.match.state, 'open');
      expect(stored.match.players.map((player) => player.userId), [
        'owner-user',
      ]);
      expect(stored.presenceLeases, isNot(contains('guest-user')));
      await owner.close();
    },
  );

  test('late heartbeat cannot extend a reconnect grace lease', () async {
    final now = DateTime.utc(2026, 8, 8, 12, 30);
    final hub = RealtimeMatchHub(nowUtc: () => now);
    final store = _LobbyPresenceStore();
    final match = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: _hostedRequest(),
    );
    final owner = await _connectParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'owner-user',
      matchId: match.id,
    );
    final connected = (await store.findState(match.id))!;
    final connectedLease = connected.presenceLeases['owner-user']!;

    await owner.close();
    final disconnected = (await store.findState(match.id))!;
    final graceLease = disconnected.presenceLeases['owner-user']!;
    expect(
      disconnected.match.players.single.connectionState,
      WirePlayerConnectionState.reconnecting,
    );
    expect(
      graceLease.connectionGeneration,
      isNot(connectedLease.connectionGeneration),
    );
    expect(graceLease.expiresAt, now.add(const Duration(seconds: 10)));

    final renewed = await store.renewPresenceLease(
      matchId: match.id,
      userIdentifier: 'owner-user',
      connectionGeneration: connectedLease.connectionGeneration,
      expiresAt: now.add(const Duration(seconds: 30)),
      updatedAt: now,
    );

    expect(renewed, isFalse);
    final afterLateHeartbeat = (await store.findState(match.id))!;
    expect(
      afterLateHeartbeat.presenceLeases['owner-user']!.expiresAt,
      graceLease.expiresAt,
    );
    expect(
      afterLateHeartbeat.match.players.single.connectionState,
      WirePlayerConnectionState.reconnecting,
    );
    expect(afterLateHeartbeat.snapshot.toJson(), connected.snapshot.toJson());
  });

  test(
    'failed presence renewal closes the stream before handling input',
    () async {
      final hub = RealtimeMatchHub();
      final store = _LobbyPresenceStore();
      final match = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: _hostedRequest(),
      );
      final input = StreamController<MultiplayerClientMessage>();
      final initial = Completer<void>();
      final error = Completer<Object>();
      final done = Completer<void>();
      final messages = <MultiplayerServerMessage>[];
      final subscription = hub
          .connect(
            store: store,
            userIdentifier: 'owner-user',
            matchId: match.id,
            afterOffset: 0,
            input: input.stream,
          )
          .listen(
            (message) {
              messages.add(message);
              if (!initial.isCompleted) initial.complete();
            },
            onError: (Object value) {
              if (!error.isCompleted) error.complete(value);
            },
            onDone: done.complete,
          );
      await initial.future.timeout(const Duration(seconds: 1));
      await store.deletePresenceLease(
        matchId: match.id,
        userIdentifier: 'owner-user',
      );

      input.add(
        MultiplayerClientMessage(
          clientMessageId: 'stale-generation-heartbeat',
          lastSeenOffset: 0,
          requestSnapshot: true,
        ),
      );

      expect(
        await error.future.timeout(const Duration(seconds: 1)),
        isA<MultiplayerException>().having(
          (exception) => exception.code,
          'code',
          'not_match_player',
        ),
      );
      await done.future.timeout(const Duration(seconds: 1));
      expect(messages, hasLength(1));

      await subscription.cancel();
      await input.close();
    },
  );

  test('host expiry abandons a hosted lobby', () async {
    var now = DateTime.utc(2026, 8, 8, 13);
    final hub = RealtimeMatchHub(nowUtc: () => now);
    final store = _LobbyPresenceStore();
    final match = await hub.createMatch(
      store: store,
      userIdentifier: 'owner-user',
      request: _hostedRequest(),
    );
    final owner = await _connectParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'owner-user',
      matchId: match.id,
    );
    await hub.joinMatch(
      store: store,
      userIdentifier: 'guest-user',
      matchId: match.id,
    );
    final guest = await _connectParticipant(
      hub: hub,
      store: store,
      userIdentifier: 'guest-user',
      matchId: match.id,
    );

    await owner.close();

    now = now.add(const Duration(seconds: 11));
    expect(await hub.expireLobbyPresence(store: store), isEmpty);
    final abandoned = (await store.findState(match.id))!;
    expect(abandoned.match.state, 'abandoned');
    expect(abandoned.snapshot.state['reason'], 'owner_left');
    expect(abandoned.presenceLeases, isEmpty);
    await guest.close();
  });

  test(
    'initial lease cleans up a hosted lobby that never opens a stream',
    () async {
      var now = DateTime.utc(2026, 8, 8, 14);
      final hub = RealtimeMatchHub(nowUtc: () => now);
      final store = _LobbyPresenceStore();
      final match = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: _hostedRequest(),
      );

      expect(
        (await store.findState(match.id))!.match.players.single.connectionState,
        WirePlayerConnectionState.connecting,
      );
      now = now.add(const Duration(seconds: 21));
      expect(await hub.expireLobbyPresence(store: store), isEmpty);
      expect((await store.findState(match.id))!.match.state, 'abandoned');
    },
  );

  test(
    'heartbeat renews the durable lease without changing the roster',
    () async {
      var now = DateTime.utc(2026, 8, 8, 14, 30);
      final hub = RealtimeMatchHub(nowUtc: () => now);
      final store = _LobbyPresenceStore();
      final match = await hub.createMatch(
        store: store,
        userIdentifier: 'owner-user',
        request: _hostedRequest(),
      );
      final owner = await _connectParticipant(
        hub: hub,
        store: store,
        userIdentifier: 'owner-user',
        matchId: match.id,
      );
      final firstLease = (await store.findState(
        match.id,
      ))!.presenceLeases['owner-user']!;

      now = now.add(const Duration(seconds: 15));
      owner.input.add(
        MultiplayerClientMessage(
          clientMessageId: 'heartbeat-1',
          lastSeenOffset: 0,
          requestSnapshot: false,
        ),
      );
      await _waitUntil(() async {
        final lease = (await store.findState(
          match.id,
        ))!.presenceLeases['owner-user'];
        return lease?.updatedAt == now;
      });

      final renewed = (await store.findState(match.id))!;
      expect(renewed.match.players, hasLength(1));
      expect(renewed.snapshot.offset, 0);
      expect(
        renewed.presenceLeases['owner-user']!.expiresAt,
        now.add(const Duration(seconds: 30)),
      );
      expect(
        renewed.presenceLeases['owner-user']!.connectionGeneration,
        firstLease.connectionGeneration,
      );
      await owner.close();
    },
  );

  test(
    'quickplay disconnect cancels countdown and expiry frees the seat',
    () async {
      var now = DateTime.utc(2026, 8, 8, 15);
      final hub = RealtimeMatchHub(nowUtc: () => now);
      final store = _LobbyPresenceStore();
      final waiting = await _quickplay(
        hub,
        store,
        user: 'owner-user',
        country: PlayerCountry.japan,
      );
      await _quickplay(
        hub,
        store,
        user: 'guest-user',
        country: PlayerCountry.france,
      );
      final owner = await _connectParticipant(
        hub: hub,
        store: store,
        userIdentifier: 'owner-user',
        matchId: waiting.id,
      );
      final guest = await _connectParticipant(
        hub: hub,
        store: store,
        userIdentifier: 'guest-user',
        matchId: waiting.id,
      );
      expect((await store.findState(waiting.id))!.match.autoStartAt, isNotNull);

      await guest.close();
      expect((await store.findState(waiting.id))!.match.autoStartAt, isNull);
      now = now.add(const Duration(seconds: 11));
      expect(await hub.expireLobbyPresence(store: store), isEmpty);
      final remaining = (await store.findState(waiting.id))!;
      expect(remaining.match.state, 'open');
      expect(remaining.match.players.map((player) => player.userId), [
        'owner-user',
      ]);
      expect(remaining.match.autoStartAt, isNull);
      await owner.close();
    },
  );

  test('expires inactive running matches from older protocols', () async {
    var now = DateTime.utc(2026, 6, 30, 8);
    final hub = RealtimeMatchHub(
      matchInactivityTimeout: const Duration(hours: 1),
      nowUtc: () => now,
    );
    final store = _LobbyPresenceStore();
    await store.createState(
      StoredMatchState(
        match: WireMatch(
          id: 'inactive-match',
          ownerUserId: 'owner-user',
          name: 'Inactive match',
          mapName: 'verdantia',
          players: const [],
          maxPlayers: 2,
          minPlayers: 2,
          quickplay: false,
          turn: 1,
          state: 'running',
          createdAt: now,
        ),
        snapshot: WireSnapshot(
          v: kSnapshotEventVersion - 1,
          matchId: 'inactive-match',
          offset: 0,
          save: const {},
          state: {
            'phase': 'running',
            'lastHumanActivityAt': now.toIso8601String(),
          },
        ),
      ),
    );

    now = now.add(const Duration(hours: 1));
    expect(await hub.advanceTimedOutTurns(store: store), isEmpty);

    final abandoned = (await store.findState('inactive-match'))!;
    expect(abandoned.match.state, 'abandoned');
    expect(abandoned.match.endedAt, now);
    expect(abandoned.snapshot.state['reason'], 'all_players_inactive');
  });
}
