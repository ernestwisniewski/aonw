import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';

void main() {
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
        timeout: const Duration(seconds: 1),
      );
      await _waitFor(() => connection.clientMessages.isNotEmpty);

      final sent = connection.clientMessages.single;
      expect(sent.lastSeenOffset, 8);
      expect(sent.requestSnapshot, isFalse);
      expect(sent.command, wire);

      connection.add(
        _message(
          offset: 9,
          ack: WireCommandAck(
            matchId: 'match_1',
            accepted: true,
            offset: 9,
            snapshot: snapshotCodec.toWire(
              matchId: 'match_1',
              snapshot: SaveSnapshot(save: _save(), eventLogOffset: 9),
            ),
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
      final received = Completer<SaveSnapshot>();
      final snapshot = SaveSnapshot(save: _save(), eventLogOffset: 4);

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
        final snapshot = SaveSnapshot(save: _save(), eventLogOffset: 4);

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

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 50; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not met in time.');
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
    ],
  );
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
