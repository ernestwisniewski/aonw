import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart';
import 'package:test/test.dart';

void main() {
  test('round-trips authoritative movement in an event message', () {
    final message = MultiplayerServerMessage(
      serverMessageId: 'message_1',
      matchId: 'match_1',
      offset: 4,
      event: WireEvent(
        matchId: 'match_1',
        offset: 4,
        timestamp: DateTime.utc(2026, 7, 25, 18),
        movementExecutions: _movementExecutions(),
      ),
    );

    final restored = MultiplayerServerMessage.fromJson(message.toJson());
    final movement = restored.event!.movementExecutions!.values.single;

    expect(restored.serverMessageId, 'message_1');
    expect(movement.unitId, 'unit_1');
    expect((movement.fromCol, movement.fromRow), (0, 0));
    expect(
      [
        for (final step in movement.steps)
          (step.col, step.row, step.enterCost, step.cumulativeCost),
      ],
      const [(1, 0, 1, 1), (2, 0, 1, 2)],
    );
    expect(
      (restored.event!.toJson()['movementExecutions']! as List).single,
      isNot(contains('_serverAudiencePlayerIds')),
    );
  });

  test('round-trips authoritative movement in an ACK message', () {
    final message = MultiplayerServerMessage(
      serverMessageId: 'message_2',
      matchId: 'match_1',
      offset: 4,
      ack: WireCommandAck(
        matchId: 'match_1',
        accepted: true,
        offset: 4,
        snapshot: const WireSnapshot(
          matchId: 'match_1',
          offset: 4,
          save: {'id': 'match_1'},
          state: {'units': <Object>[]},
        ),
        movementExecutions: _movementExecutions(),
      ),
    );

    final restored = MultiplayerServerMessage.fromJson(message.toJson());
    final movements = restored.ack!.movementExecutions!;

    expect(restored.serverMessageId, 'message_2');
    expect(movements.values.single.steps.last.cumulativeCost, 2);
    expect(movements, _movementExecutions());
    expect(
      (restored.ack!.toJson()['movementExecutions']! as List).single,
      isNot(contains('_serverAudiencePlayerIds')),
    );
  });
}

WireMovementExecutionList _movementExecutions() {
  return WireMovementExecutionList([
    WireMovementExecution(
      unitId: 'unit_1',
      fromCol: 0,
      fromRow: 0,
      steps: const [
        WireMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        WireMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
      ],
    ),
  ]);
}
