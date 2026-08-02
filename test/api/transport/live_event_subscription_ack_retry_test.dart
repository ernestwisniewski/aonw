import 'dart:async';

import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/transport/live_event_subscription.dart';
import 'package:aonw/game/application/ports/auth_token.dart';
import 'package:aonw/game/application/ports/live_multiplayer_events.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(LiveEventSubscription.resetLocalCommandEchoGuardForTesting);

  test(
    'reconnect snapshot precedes retry and suppresses the caller backlog echo',
    () async {
      final reconnected = Completer<void>();
      final resynced = Completer<CanonicalGameSnapshot>();
      final received = <LiveServerEvent>[];
      final connector = _FakeConnector(
        onConnect: (count) {
          if (count == 2) reconnected.complete();
        },
      );
      final live = LiveEventSubscription(
        serverpodHost: 'https://api.example.test',
        connector: connector.connect,
      );
      const wire = WireCommand(
        matchId: 'match_1',
        tick: 11,
        turn: 3,
        actorPlayerId: 'player_1',
        command: {'type': 'SubmitTurn', 'playerId': 'player_1'},
      );
      final handle = await live.subscribe(
        matchId: 'match_1',
        token: AuthToken('jwt-token'),
        fromOffset: 7,
        reconnectDelays: const [Duration.zero],
        onEvent: received.add,
        onSnapshotResync: resynced.complete,
      );
      final first = handle.sendCommand(
        afterOffset: 8,
        wire: wire,
        clientMessageId: 'command-session-1',
      );
      await _waitFor(
        () => connector.connections.first.clientMessages.isNotEmpty,
      );

      await connector.connections.first.close();
      await expectLater(first, throwsA(isA<TimeoutException>()));
      await reconnected.future.timeout(const Duration(seconds: 1));
      final reconnect = connector.connections[1];
      const snapshotCodec = SnapshotCodec();
      reconnect.add(
        _message(
          offset: 9,
          snapshot: snapshotCodec.toWire(
            matchId: 'match_1',
            snapshot: GameSnapshotFactory.create(
              save: _save(),
              eventLogOffset: 9,
            ),
          ),
        ),
      );
      expect((await resynced.future).eventLogOffset, 9);

      final plan = _movementExecutions();
      const eventCodec = EventCodec();
      final echo = eventCodec
          .toWire(
            matchId: 'match_1',
            offset: 9,
            timestamp: DateTime.utc(2026, 7, 25, 12),
            actorPlayerId: 'player_1',
            tick: 11,
            turn: 3,
            command: const SubmitTurnCommand('player_1'),
            events: const [],
          )
          .copyWith(movementExecutions: plan);
      reconnect.add(_message(offset: 9, event: echo));
      await Future<void>.delayed(Duration.zero);
      expect(received, isEmpty);

      final retry = handle.sendCommand(
        afterOffset: 8,
        wire: wire,
        clientMessageId: 'command-session-1',
      );
      await _waitFor(() => reconnect.clientMessages.isNotEmpty);
      reconnect.add(_message(offset: 9, ack: _ack(movementExecutions: plan)));
      final ack = await retry;
      reconnect.add(
        _message(offset: 10, event: echo.copyWith(offset: 10, tick: 12)),
      );
      await _waitFor(() => received.length == 1);

      expect(ack.movementExecutions, plan);
      expect(
        connector.connections.map(
          (value) => value.clientMessages.single.clientMessageId,
        ),
        ['command-session-1', 'command-session-1'],
      );
      expect(
        connector.connections.map(
          (value) => value.clientMessages.single.command,
        ),
        [same(wire), same(wire)],
      );
      expect(received.single.wire.tick, 12);
      expect(received.single.wire.movementExecutions, plan);
      await handle.close();
    },
  );

  test('maps live wire movement to one owned domain list', () async {
    final connector = _FakeConnector();
    final received = Completer<LiveServerEvent>();
    final live = LiveEventSubscription(
      serverpodHost: 'https://api.example.test',
      connector: connector.connect,
    );
    final handle = await live.subscribe(
      matchId: 'match_1',
      token: AuthToken('jwt-token'),
      fromOffset: 0,
      onEvent: received.complete,
      onSnapshotResync: (_) {},
    );
    final plan = _movementExecutions();
    final wire = const EventCodec()
        .toWire(
          matchId: 'match_1',
          offset: 1,
          timestamp: DateTime.utc(2026, 7, 25, 12),
          events: const [],
        )
        .copyWith(movementExecutions: plan);

    connector.connections.single.add(_message(offset: 1, event: wire));
    final event = await received.future;

    expect(
      event.movementExecutions,
      everyElement(isA<MovementCommandExecution>()),
    );
    expect(
      event.movementExecutions.map((execution) {
        final step = execution.steps.single;
        return (
          execution.unitId,
          execution.fromCol,
          execution.fromRow,
          step.col,
          step.row,
          step.enterCost,
          step.cumulativeCost,
        );
      }),
      const [
        ('unit_a', 0, 0, 1, 0, 7, 7),
        ('unit_b', 0, 1, 1, 1, 11, 11),
        ('unit_a', 1, 0, 2, 0, 13, 20),
      ],
    );
    expect(event.movementExecutions.clear, throwsUnsupportedError);
    await handle.close();
  });
}

WireMovementExecutionList _movementExecutions() {
  return WireMovementExecutionList([
    _wireExecution('unit_a', 0, 0, 1, 0, 7, 7),
    _wireExecution('unit_b', 0, 1, 1, 1, 11, 11),
    _wireExecution('unit_a', 1, 0, 2, 0, 13, 20),
  ]);
}

WireMovementExecution _wireExecution(
  String unitId,
  int fromCol,
  int fromRow,
  int toCol,
  int toRow,
  int enterCost,
  int cumulativeCost,
) {
  return WireMovementExecution(
    unitId: unitId,
    fromCol: fromCol,
    fromRow: fromRow,
    steps: [
      WireMovementStep(
        col: toCol,
        row: toRow,
        enterCost: enterCost,
        cumulativeCost: cumulativeCost,
      ),
    ],
  );
}

WireCommandAck _ack({required WireMovementExecutionList movementExecutions}) {
  const snapshotCodec = SnapshotCodec();
  return WireCommandAck(
    matchId: 'match_1',
    accepted: true,
    offset: 9,
    snapshot: snapshotCodec.toWire(
      matchId: 'match_1',
      snapshot: GameSnapshotFactory.create(save: _save(), eventLogOffset: 9),
    ),
    movementExecutions: movementExecutions,
  );
}

sp.MultiplayerServerMessage _message({
  required int offset,
  WireSnapshot? snapshot,
  WireEvent? event,
  WireCommandAck? ack,
}) {
  return sp.MultiplayerServerMessage(
    serverMessageId: 'server-$offset',
    matchId: 'match_1',
    offset: offset,
    snapshot: snapshot,
    event: event,
    ack: ack,
  );
}

final class _FakeConnector {
  _FakeConnector({this.onConnect});

  final void Function(int connectionCount)? onConnect;
  final connections = <_FakeConnection>[];

  Stream<sp.MultiplayerServerMessage> connect({
    required String matchId,
    required AuthToken token,
    required int afterOffset,
    required Stream<sp.MultiplayerClientMessage> input,
  }) {
    final connection = _FakeConnection(input);
    connections.add(connection);
    onConnect?.call(connections.length);
    return connection.stream;
  }
}

final class _FakeConnection {
  _FakeConnection(Stream<sp.MultiplayerClientMessage> input) {
    input.listen(clientMessages.add);
  }

  final clientMessages = <sp.MultiplayerClientMessage>[];
  final _messages = StreamController<sp.MultiplayerServerMessage>();

  Stream<sp.MultiplayerServerMessage> get stream => _messages.stream;

  void add(sp.MultiplayerServerMessage message) => _messages.add(message);

  Future<void> close() => _messages.close();
}

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 50; attempt += 1) {
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
    turn: 2,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4),
    ],
  );
}
