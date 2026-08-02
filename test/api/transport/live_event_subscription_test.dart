import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/network_session_refresh_coordinator.dart';
import 'package:aonw/api/session/network_session_store.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/ports/multiplayer_session_gateway.dart';
import 'package:aonw/game/application/ports/network_connection.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/ports/network_session_authentication.dart';
import 'package:aonw/game/application/ports/network_session_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';

part 'live_event_subscription_fixture.dart';

void main() {
  group('ServerpodMultiplayerStreamConnector', () {
    test('creates lazily and closes exactly once when cancelled', () async {
      final upstream = StreamController<sp.MultiplayerServerMessage>();
      var connectionsCreated = 0;
      var closeCalls = 0;
      final connector = ServerpodMultiplayerStreamConnector(
        'https://api.example.test',
        connectionFactory:
            ({
              required matchId,
              required token,
              required afterOffset,
              required input,
            }) {
              connectionsCreated += 1;
              return (messages: upstream.stream, close: () => closeCalls += 1);
            },
      );

      final messages = connector.connect(
        matchId: 'match_1',
        token: AuthToken('jwt-token'),
        afterOffset: 0,
        input: const Stream<sp.MultiplayerClientMessage>.empty(),
      );
      expect(connectionsCreated, 0, reason: 'connect must stay lazy');

      final subscription = messages.listen((_) {});
      await _waitFor(() => connectionsCreated == 1);
      await subscription.cancel();
      await subscription.cancel();

      expect(closeCalls, 1);
      await upstream.close();
    });

    test('closes exactly once when the server stream completes', () async {
      final upstream = StreamController<sp.MultiplayerServerMessage>();
      var closeCalls = 0;
      final connector = ServerpodMultiplayerStreamConnector(
        'https://api.example.test',
        connectionFactory:
            ({
              required matchId,
              required token,
              required afterOffset,
              required input,
            }) {
              return (messages: upstream.stream, close: () => closeCalls += 1);
            },
      );
      final done = Completer<void>();
      final subscription = connector
          .connect(
            matchId: 'match_1',
            token: AuthToken('jwt-token'),
            afterOffset: 0,
            input: const Stream<sp.MultiplayerClientMessage>.empty(),
          )
          .listen((_) {}, onDone: done.complete);

      await upstream.close();
      await done.future;
      await subscription.cancel();

      expect(closeCalls, 1);
    });

    test('closes each superseded reconnect client exactly once', () async {
      final upstreams = <StreamController<sp.MultiplayerServerMessage>>[];
      final closeCalls = <int>[];
      final connector = ServerpodMultiplayerStreamConnector(
        'https://api.example.test',
        connectionFactory:
            ({
              required matchId,
              required token,
              required afterOffset,
              required input,
            }) {
              input.listen((_) {});
              final index = upstreams.length;
              upstreams.add(StreamController<sp.MultiplayerServerMessage>());
              closeCalls.add(0);
              return (
                messages: upstreams[index].stream,
                close: () => closeCalls[index] += 1,
              );
            },
      );
      final live = LiveEventSubscription(
        serverpodHost: 'https://api.example.test',
        connector: connector.connect,
      );
      final reconnecting = Completer<void>();
      final handle = await live.subscribe(
        matchId: 'match_1',
        token: AuthToken('jwt-token'),
        fromOffset: 0,
        reconnectDelays: const [Duration.zero],
        onEvent: (_) {},
        onSnapshotResync: (_) {},
        onReconnecting: reconnecting.complete,
      );
      await _waitFor(() => upstreams.length == 1);

      upstreams.single.addError(StateError('connection lost'));
      await reconnecting.future.timeout(const Duration(seconds: 1));
      await _waitFor(() => upstreams.length == 2);
      expect(closeCalls, [1, 0]);
      await upstreams.first.close();

      await handle.close();
      await handle.close();
      expect(closeCalls, [1, 1]);
      await upstreams.last.close();
    });
  });

  group('LiveEventSubscription', () {
    test('subscribes from offset and forwards live events', () async {
      final connector = _FakeServerpodStreamConnector();
      const codec = EventCodec();
      final live = LiveEventSubscription(
        serverpodHost: 'https://api.example.test',
        connector: connector.connect,
      );
      final received = Completer<LiveServerEvent>();

      final handle = await live.subscribe(
        matchId: 'match_1',
        token: AuthToken('jwt-token'),
        fromOffset: 7,
        onEvent: received.complete,
        onSnapshotResync: (_) {},
      );
      final connection = connector.connections.single
        ..add(
          _message(
            offset: 8,
            event: codec.toWire(
              matchId: 'match_1',
              offset: 8,
              timestamp: DateTime.utc(2026, 4, 26, 12),
              actorPlayerId: 'player_1',
              command: const MoveUnitCommand('u1', 1, 0),
              events: const [
                UnitMovedEvent(
                  unitId: 'u1',
                  fromCol: 0,
                  fromRow: 0,
                  toCol: 1,
                  toRow: 0,
                ),
              ],
            ),
          ),
        );

      final event = await received.future;

      expect(connection.matchId, 'match_1');
      expect(connection.token.value, 'jwt-token');
      expect(connection.afterOffset, 6);
      expect(event.wire.offset, 8);
      expect(event.events.single, isA<UnitMovedEvent>());
      await handle.close();
    });

    test('sends commands through the active two-way stream', () async {
      final connector = _FakeServerpodStreamConnector();
      const commandCodec = CommandCodec();
      const snapshotCodec = SnapshotCodec();
      final live = LiveEventSubscription(
        serverpodHost: 'https://api.example.test',
        connector: connector.connect,
      );
      final wire = commandCodec.toWire(
        matchId: 'match_1',
        tick: 11,
        turn: 3,
        actorPlayerId: 'player_1',
        command: const MoveUnitCommand('u1', 1, 0),
      );

      final handle = await live.subscribe(
        matchId: 'match_1',
        token: AuthToken('jwt-token'),
        fromOffset: 7,
        onEvent: (_) {},
        onSnapshotResync: (_) {},
      );
      final connection = connector.connections.single;
      final pendingAck = handle.sendCommand(
        afterOffset: 8,
        wire: wire,
        clientMessageId: 'command-session-1',
        timeout: const Duration(seconds: 1),
      );
      await _waitFor(() => connection.clientMessages.isNotEmpty);

      final sent = connection.clientMessages.single;
      expect(sent.lastSeenOffset, 8);
      expect(sent.requestSnapshot, isFalse);
      expect(sent.command, wire);
      expect(sent.clientMessageId, 'command-session-1');

      connection.add(
        _message(
          offset: 9,
          ack: WireCommandAck(
            matchId: 'match_1',
            accepted: true,
            offset: 9,
            snapshot: snapshotCodec.toWire(
              matchId: 'match_1',
              snapshot: _snapshot(9),
            ),
            movementExecutions: WireMovementExecutionList(const []),
          ),
        ),
      );
      final ack = await pendingAck;
      expect(ack.accepted, isTrue);
      expect(ack.offset, 9);
      await handle.close();
    });

    test('forwards snapshot resync messages', () async {
      final connector = _FakeServerpodStreamConnector();
      const snapshotCodec = SnapshotCodec();
      final live = LiveEventSubscription(
        serverpodHost: 'http://localhost:8080',
        connector: connector.connect,
      );
      final received = Completer<CanonicalGameSnapshot>();
      final snapshot = _snapshot(4);

      final handle = await live.subscribe(
        matchId: 'match_1',
        token: AuthToken('jwt-token'),
        fromOffset: 3,
        onEvent: (_) {},
        onSnapshotResync: received.complete,
      );
      connector.connections.single.add(
        _message(
          offset: 4,
          snapshot: snapshotCodec.toWire(
            matchId: 'match_1',
            snapshot: snapshot,
          ),
        ),
      );

      final restored = await received.future;

      expect(restored.save.id, 'save_1');
      expect(restored.eventLogOffset, 4);
      await handle.close();
    });

    test(
      'treats event messages with snapshots as one animated update',
      () async {
        final connector = _FakeServerpodStreamConnector();
        const eventCodec = EventCodec();
        const snapshotCodec = SnapshotCodec();
        final live = LiveEventSubscription(
          serverpodHost: 'http://localhost:8080',
          connector: connector.connect,
        );
        final received = Completer<LiveServerEvent>();
        var standaloneSnapshotResyncs = 0;
        final snapshot = _snapshot(4);

        final handle = await live.subscribe(
          matchId: 'match_1',
          token: AuthToken('jwt-token'),
          fromOffset: 3,
          onEvent: received.complete,
          onSnapshotResync: (_) => standaloneSnapshotResyncs += 1,
        );
        connector.connections.single.add(
          _message(
            offset: 4,
            snapshot: snapshotCodec.toWire(
              matchId: 'match_1',
              snapshot: snapshot,
            ),
            event: eventCodec.toWire(
              matchId: 'match_1',
              offset: 4,
              timestamp: DateTime.utc(2026, 4, 26, 12),
              actorPlayerId: 'player_1',
              command: const MoveUnitCommand('u1', 1, 0),
              events: const [
                UnitMovedEvent(
                  unitId: 'u1',
                  fromCol: 0,
                  fromRow: 0,
                  toCol: 1,
                  toRow: 0,
                ),
              ],
            ),
          ),
        );

        final event = await received.future;

        expect(standaloneSnapshotResyncs, 0);
        expect(event.snapshot?.eventLogOffset, 4);
        expect(event.events.single, isA<UnitMovedEvent>());
        await handle.close();
      },
    );

    test(
      'forwards lobby match messages without treating them as events',
      () async {
        final connector = _FakeServerpodStreamConnector();
        final live = LiveEventSubscription(
          serverpodHost: 'http://localhost:8080',
          connector: connector.connect,
        );
        final received = Completer<String>();

        final handle = await live.subscribe(
          matchId: 'match_1',
          token: AuthToken('jwt-token'),
          fromOffset: 0,
          onEvent: (_) => fail('match messages are not game events'),
          onSnapshotResync: (_) {},
          onMatch: (match) => received.complete(match.state),
        );
        connector.connections.single.add(
          _message(offset: 0, match: _wireMatch(state: 'open', players: 2)),
        );

        expect(await received.future, 'open');
        await handle.close();
      },
    );

    test(
      'reconnects from the last seen event offset after stream closes',
      () async {
        final reconnected = Completer<void>();
        final connector = _FakeServerpodStreamConnector(
          onConnect: (count) {
            if (count == 2 && !reconnected.isCompleted) {
              reconnected.complete();
            }
          },
        );
        const codec = EventCodec();
        final receivedOffsets = <int>[];
        final connectionStates = <String>[];
        final receivedSecond = Completer<void>();
        final live = LiveEventSubscription(
          serverpodHost: 'https://api.example.test',
          connector: connector.connect,
        );

        final handle = await live.subscribe(
          matchId: 'match_1',
          token: AuthToken('jwt-token'),
          fromOffset: 7,
          reconnectDelays: const [Duration.zero],
          onConnected: () => connectionStates.add('connected'),
          onReconnecting: () => connectionStates.add('reconnecting'),
          onEvent: (event) {
            receivedOffsets.add(event.wire.offset);
            if (event.wire.offset == 9 && !receivedSecond.isCompleted) {
              receivedSecond.complete();
            }
          },
          onSnapshotResync: (_) {},
        );
        connector.connections[0].add(
          _message(
            offset: 8,
            event: codec.toWire(
              matchId: 'match_1',
              offset: 8,
              timestamp: DateTime.utc(2026, 4, 26, 12),
              actorPlayerId: 'player_1',
              command: const MoveUnitCommand('u1', 1, 0),
              events: const [],
            ),
          ),
        );
        await Future<void>.delayed(Duration.zero);
        await connector.connections[0].close();
        await reconnected.future.timeout(const Duration(seconds: 1));
        connector.connections[1].add(
          _message(
            offset: 9,
            event: codec.toWire(
              matchId: 'match_1',
              offset: 9,
              timestamp: DateTime.utc(2026, 4, 26, 12, 1),
              actorPlayerId: 'player_1',
              command: const MoveUnitCommand('u1', 2, 0),
              events: const [],
            ),
          ),
        );

        await receivedSecond.future.timeout(const Duration(seconds: 1));

        expect(receivedOffsets, [8, 9]);
        expect(
          connector.connections.map((connection) => connection.afterOffset),
          [6, 8],
        );
        expect(connectionStates, ['connected', 'reconnecting', 'connected']);
        await handle.close();
      },
    );

    test('reconnect after expiry uses the refreshed JWT', () async {
      var now = DateTime.utc(2026, 7, 10, 12);
      NetworkSession? session = NetworkSession(
        userId: 'user_1',
        token: AuthToken(
          'jwt-before-expiry',
          expiresAt: DateTime.utc(2026, 7, 10, 12, 1),
        ),
        refreshToken: 'refresh-before-expiry',
        matchId: 'match_1',
        connectionState: NetworkConnectionState(
          status: NetworkConnectionStatus.connected,
          changedAt: now,
        ),
      );
      final store = _RefreshableSessionStore(
        const StoredNetworkSession(
          userId: 'user_1',
          refreshToken: 'refresh-before-expiry',
          displayName: 'Alice',
          matchId: 'match_1',
        ),
      );
      var refreshCalls = 0;
      final refreshCoordinator = NetworkSessionRefreshCoordinator(
        currentSession: () => session,
        setSession: (value) => session = value,
        sessionStore: store,
        refreshToken: ({required refreshToken}) async {
          refreshCalls += 1;
          expect(refreshToken, 'refresh-before-expiry');
          return NetworkSessionRefreshResult(
            token: AuthToken(
              'jwt-after-refresh',
              expiresAt: DateTime.utc(2026, 7, 10, 13),
            ),
            refreshToken: 'refresh-after-rotation',
          );
        },
        now: () => now,
      );
      final reconnected = Completer<void>();
      final connector = _FakeServerpodStreamConnector(
        onConnect: (count) {
          if (count == 2) reconnected.complete();
        },
      );
      final live = LiveEventSubscription(
        serverpodHost: 'https://api.example.test',
        connector: connector.connect,
      );

      final handle = await live.subscribe(
        matchId: 'match_1',
        token: session!.token,
        tokenReader: refreshCoordinator.currentToken,
        fromOffset: 0,
        reconnectDelays: const [Duration.zero],
        onEvent: (_) {},
        onSnapshotResync: (_) {},
      );
      expect(connector.connections.single.token.value, 'jwt-before-expiry');

      now = DateTime.utc(2026, 7, 10, 12, 2);
      await connector.connections.single.close();
      await reconnected.future.timeout(const Duration(seconds: 1));

      expect(
        connector.connections.map((connection) => connection.token.value),
        ['jwt-before-expiry', 'jwt-after-refresh'],
      );
      expect(refreshCalls, 1);
      expect(store.stored?.refreshToken, 'refresh-after-rotation');
      expect(session?.token.value, 'jwt-after-refresh');
      await handle.close();
    });

    test('refresh failure terminates reconnect without a retry loop', () async {
      var now = DateTime.utc(2026, 7, 10, 12);
      NetworkSession? session = NetworkSession(
        userId: 'user_1',
        token: AuthToken(
          'jwt-before-failure',
          expiresAt: DateTime.utc(2026, 7, 10, 12, 1),
        ),
        refreshToken: 'refresh-before-failure',
        matchId: 'match_1',
        connectionState: const NetworkConnectionState(
          status: NetworkConnectionStatus.connected,
        ),
      );
      final store = _RefreshableSessionStore(
        const StoredNetworkSession(
          userId: 'user_1',
          refreshToken: 'refresh-before-failure',
          displayName: 'Alice',
          matchId: 'match_1',
        ),
      );
      var refreshCalls = 0;
      final refreshCoordinator = NetworkSessionRefreshCoordinator(
        currentSession: () => session,
        setSession: (value) => session = value,
        sessionStore: store,
        refreshToken: ({required refreshToken}) async {
          refreshCalls += 1;
          throw const sp.ServerpodClientException('refresh unavailable', 503);
        },
        now: () => now,
      );
      final connector = _FakeServerpodStreamConnector();
      final terminalError = Completer<Object>();
      final live = LiveEventSubscription(
        serverpodHost: 'https://api.example.test',
        connector: connector.connect,
      );
      final handle = await live.subscribe(
        matchId: 'match_1',
        token: session!.token,
        tokenReader: refreshCoordinator.currentToken,
        fromOffset: 0,
        reconnectDelays: const [Duration.zero],
        onEvent: (_) {},
        onSnapshotResync: (_) {},
        onError: (error, _) {
          if (error is NetworkSessionAuthenticationException &&
              !terminalError.isCompleted) {
            terminalError.complete(error);
          }
        },
      );

      now = DateTime.utc(2026, 7, 10, 12, 2);
      await connector.connections.single.close();
      await terminalError.future.timeout(const Duration(seconds: 1));
      await Future<void>.delayed(Duration.zero);

      expect(refreshCalls, 1);
      expect(connector.connections, hasLength(1));
      expect(session, isNull);
      expect(store.stored, isNull);
      await handle.close();
    });
  });
}

sp.MultiplayerServerMessage _message({
  required int offset,
  WireMatch? match,
  WireSnapshot? snapshot,
  WireEvent? event,
  WireCommandAck? ack,
}) {
  return sp.MultiplayerServerMessage(
    serverMessageId: 'server-$offset',
    matchId: 'match_1',
    offset: offset,
    match: match,
    snapshot: snapshot,
    event: event,
    ack: ack,
  );
}

class _FakeServerpodStreamConnector {
  final void Function(int connectionCount)? onConnect;
  final connections = <_FakeServerpodStreamConnection>[];

  _FakeServerpodStreamConnector({this.onConnect});

  Stream<sp.MultiplayerServerMessage> connect({
    required String matchId,
    required AuthToken token,
    required int afterOffset,
    required Stream<sp.MultiplayerClientMessage> input,
  }) {
    final connection = _FakeServerpodStreamConnection(
      matchId: matchId,
      token: token,
      afterOffset: afterOffset,
      input: input,
    );
    connections.add(connection);
    onConnect?.call(connections.length);
    return connection.stream;
  }
}

class _FakeServerpodStreamConnection {
  final String matchId;
  final AuthToken token;
  final int afterOffset;
  final Stream<sp.MultiplayerClientMessage> input;
  final clientMessages = <sp.MultiplayerClientMessage>[];
  final _messages = StreamController<sp.MultiplayerServerMessage>();

  _FakeServerpodStreamConnection({
    required this.matchId,
    required this.token,
    required this.afterOffset,
    required this.input,
  }) {
    input.listen(clientMessages.add);
  }

  Stream<sp.MultiplayerServerMessage> get stream => _messages.stream;

  void add(sp.MultiplayerServerMessage message) {
    _messages.add(message);
  }

  Future<void> close() {
    return _messages.close();
  }
}

final class _RefreshableSessionStore extends NetworkSessionStore {
  StoredNetworkSession? stored;

  _RefreshableSessionStore(this.stored);

  @override
  Future<StoredNetworkSession?> load() async => stored;

  @override
  Future<void> saveCredentials({
    required String userId,
    required String refreshToken,
  }) async {
    final current = stored;
    stored = StoredNetworkSession(
      userId: userId,
      refreshToken: refreshToken,
      displayName: current?.displayName ?? 'Player',
      matchId: current?.matchId,
    );
  }

  @override
  Future<void> clear() async {
    stored = null;
  }
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 50; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not met in time.');
}

WireMatch _wireMatch({required String state, required int players}) {
  return WireMatch(
    id: 'match_1',
    ownerUserId: 'user_1',
    name: 'Duel',
    mapName: 'verdantia',
    players: [
      for (var i = 1; i <= players; i++)
        WirePlayer(
          id: 'player_$i',
          userId: 'user_$i',
          name: 'Player $i',
          colorValue: i,
          kind: WirePlayerKind.human,
          connectionState: WirePlayerConnectionState.connected,
          ready: false,
        ),
    ],
    maxPlayers: 4,
    minPlayers: 2,
    turn: 1,
    state: state,
    createdAt: DateTime.utc(2026, 4, 27, 12),
  );
}
