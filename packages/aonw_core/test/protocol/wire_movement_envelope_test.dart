import 'package:aonw_core/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('WireEvent movement executions contract', () {
    test('rejects a missing key', () {
      expect(() => WireEvent.fromJson(_wireEventJson()), throwsArgumentError);
    });

    test('rejects explicit null', () {
      expect(
        () => WireEvent.fromJson({
          ..._wireEventJson(),
          'movementExecutions': null,
        }),
        throwsArgumentError,
      );
    });

    test('preserves an explicit authoritative empty list', () {
      final event = WireEvent.fromJson({
        ..._wireEventJson(),
        'movementExecutions': <Object>[],
      });

      expect(event.movementExecutions.isEmpty, isTrue);
      expect(event.toJson(), containsPair('movementExecutions', <Object>[]));
    });

    test('round-trips one execution with full structural equality', () {
      final json = {
        ..._wireEventJson(),
        'movementExecutions': _movementExecutionJson(),
      };

      final event = WireEvent.fromJson(json);
      final restored = WireEvent.fromJson(event.toJson());

      expect(event.movementExecutions, _movementExecutions());
      expect(event.toJson(), json);
      expect(restored, event);
    });

    test('rejects a non-list movement payload', () {
      expect(
        () => WireEvent.fromJson({
          ..._wireEventJson(),
          'movementExecutions': {'unitId': 'unit_1'},
        }),
        throwsArgumentError,
      );
    });
  });

  group('WireCommandAck movement executions contract', () {
    test('requires a non-empty client message correlation id', () {
      for (final clientMessageId in <String?>[null, '']) {
        expect(
          () => WireCommandAck.fromJson({
            ..._wireCommandAckJson(),
            'clientMessageId': clientMessageId,
            'movementExecutions': <Object>[],
          }),
          throwsArgumentError,
        );
      }
    });

    test('rejects a missing key', () {
      expect(
        () => WireCommandAck.fromJson(_wireCommandAckJson()),
        throwsArgumentError,
      );
    });

    test('rejects explicit null', () {
      expect(
        () => WireCommandAck.fromJson({
          ..._wireCommandAckJson(),
          'movementExecutions': null,
        }),
        throwsArgumentError,
      );
    });

    test('preserves an explicit authoritative empty list', () {
      final ack = WireCommandAck.fromJson({
        ..._wireCommandAckJson(),
        'movementExecutions': <Object>[],
      });

      expect(ack.movementExecutions.isEmpty, isTrue);
      expect(ack.toJson(), containsPair('movementExecutions', <Object>[]));
    });

    test('round-trips one execution and its exact JSON', () {
      final json = {
        ..._wireCommandAckJson(),
        'movementExecutions': _movementExecutionJson(),
      };

      final ack = WireCommandAck.fromJson(json);
      final restored = WireCommandAck.fromJson(ack.toJson());

      expect(ack.movementExecutions, _movementExecutions());
      expect(restored.movementExecutions, ack.movementExecutions);
      expect(ack.toJson(), json);
      expect(restored.toJson(), json);
    });

    test('rejects a non-list movement payload', () {
      expect(
        () => WireCommandAck.fromJson({
          ..._wireCommandAckJson(),
          'movementExecutions': {'unitId': 'unit_1'},
        }),
        throwsArgumentError,
      );
    });
  });

  test('envelopes return fresh nested movement JSON', () {
    final event = WireEvent.fromJson({
      ..._wireEventJson(),
      'movementExecutions': _movementExecutionJson(),
    });
    final ack = WireCommandAck.fromJson({
      ..._wireCommandAckJson(),
      'movementExecutions': _movementExecutionJson(),
    });
    final eventExecution =
        (event.toJson()['movementExecutions']! as List<dynamic>).single
            as Map<String, dynamic>;
    final ackExecution =
        (ack.toJson()['movementExecutions']! as List<dynamic>).single
            as Map<String, dynamic>;

    (eventExecution['steps']! as List<dynamic>).clear();
    (ackExecution['_serverAudiencePlayerIds']! as List<dynamic>).add(
      'player_9',
    );

    expect(event.movementExecutions, _movementExecutions());
    expect(ack.movementExecutions, _movementExecutions());
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
        WireMovementStep(col: 2, row: 0, enterCost: 2, cumulativeCost: 3),
      ],
      serverAudiencePlayerIds: const ['player_1', 'player_2'],
    ),
  ]);
}

List<Map<String, dynamic>> _movementExecutionJson() {
  return [
    {
      'unitId': 'unit_1',
      'fromCol': 0,
      'fromRow': 0,
      'steps': [
        {'col': 1, 'row': 0, 'enterCost': 1, 'cumulativeCost': 1},
        {'col': 2, 'row': 0, 'enterCost': 2, 'cumulativeCost': 3},
      ],
      '_serverAudiencePlayerIds': ['player_1', 'player_2'],
    },
  ];
}

Map<String, dynamic> _wireEventJson() {
  return {
    'v': kSnapshotEventVersion,
    'matchId': 'match_1',
    'offset': 9,
    'timestamp': '2026-04-27T12:01:00.000Z',
    'actorPlayerId': 'player_1',
    'tick': 4,
    'turn': 7,
    'command': {'type': 'SubmitTurnCommand'},
    'events': [
      {'type': 'TurnEndedEvent'},
    ],
  };
}

Map<String, dynamic> _wireCommandAckJson() {
  return {
    'v': kProtocolVersion,
    'matchId': 'match_1',
    'clientMessageId': 'command_1',
    'accepted': true,
    'offset': 9,
    'snapshot': {
      'v': kSnapshotEventVersion,
      'matchId': 'match_1',
      'offset': 9,
      'save': {'id': 'match_1'},
      'state': {'units': <Object>[]},
    },
    'events': [
      {'type': 'TurnEndedEvent'},
    ],
  };
}
