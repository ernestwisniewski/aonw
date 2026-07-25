import 'package:aonw_core/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('WireEvent movement executions compatibility', () {
    test('treats a missing key as legacy fallback', () {
      final event = WireEvent.fromJson(_wireEventJson());

      expect(event.movementExecutions, isNull);
      expect(event.toJson(), isNot(contains('movementExecutions')));
    });

    test('normalizes explicit null to an omitted key', () {
      final event = WireEvent.fromJson({
        ..._wireEventJson(),
        'movementExecutions': null,
      });

      expect(event.movementExecutions, isNull);
      expect(event.toJson(), isNot(contains('movementExecutions')));
    });

    test('preserves an explicit authoritative empty list', () {
      final event = WireEvent.fromJson({
        ..._wireEventJson(),
        'movementExecutions': <Object>[],
      });

      expect(event.movementExecutions, isNotNull);
      expect(event.movementExecutions!.isEmpty, isTrue);
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

    test('remains readable by the literal pre-movement v3 decoder', () {
      final json = {
        ..._wireEventJson(),
        'movementExecutions': _movementExecutionJson(),
      };

      expect(_decodePreMovementV3Event(json), _wireEventJson());
    });
  });

  group('WireCommandAck movement executions compatibility', () {
    test('treats a missing key as legacy fallback', () {
      final ack = WireCommandAck.fromJson(_wireCommandAckJson());

      expect(ack.movementExecutions, isNull);
      expect(ack.toJson(), isNot(contains('movementExecutions')));
    });

    test('normalizes explicit null to an omitted key', () {
      final ack = WireCommandAck.fromJson({
        ..._wireCommandAckJson(),
        'movementExecutions': null,
      });

      expect(ack.movementExecutions, isNull);
      expect(ack.toJson(), isNot(contains('movementExecutions')));
    });

    test('preserves an explicit authoritative empty list', () {
      final ack = WireCommandAck.fromJson({
        ..._wireCommandAckJson(),
        'movementExecutions': <Object>[],
      });

      expect(ack.movementExecutions, isNotNull);
      expect(ack.movementExecutions!.isEmpty, isTrue);
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

    test('remains readable by the literal pre-movement v3 decoder', () {
      final json = {
        ..._wireCommandAckJson(),
        'movementExecutions': _movementExecutionJson(),
      };

      expect(_decodePreMovementV3CommandAck(json), _wireCommandAckJson());
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
    'v': 3,
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
    'v': 3,
    'matchId': 'match_1',
    'accepted': true,
    'offset': 9,
    'snapshot': {
      'v': 3,
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

// Frozen compatibility fixtures for the v3 readers that predate movement
// executions. They intentionally select only old keys and never delegate to
// WireEvent.fromJson or WireCommandAck.fromJson.
Map<String, dynamic> _decodePreMovementV3Event(Map<String, dynamic> json) {
  final version = json['v'];
  if (version != 3) {
    throw ArgumentError.value(version, 'v', 'Expected protocol v3');
  }
  return {
    'v': version,
    'matchId': json['matchId'] as String,
    'offset': json['offset'] as int,
    'timestamp': json['timestamp'] as String,
    if (json['actorPlayerId'] case final String actorPlayerId)
      'actorPlayerId': actorPlayerId,
    if (json['tick'] case final int tick) 'tick': tick,
    if (json['turn'] case final int turn) 'turn': turn,
    if (json['command'] case final Map<Object?, Object?> command)
      'command': Map<String, dynamic>.from(command),
    'events': (json['events'] as List<Object?>)
        .map(
          (event) => Map<String, dynamic>.from(event! as Map<Object?, Object?>),
        )
        .toList(),
  };
}

Map<String, dynamic> _decodePreMovementV3CommandAck(Map<String, dynamic> json) {
  final version = json['v'];
  if (version != 3) {
    throw ArgumentError.value(version, 'v', 'Expected protocol v3');
  }
  return {
    'v': version,
    'matchId': json['matchId'] as String,
    'accepted': json['accepted'] as bool,
    'offset': json['offset'] as int,
    'snapshot': Map<String, dynamic>.from(
      json['snapshot']! as Map<Object?, Object?>,
    ),
    'events': (json['events'] as List<Object?>)
        .map(
          (event) => Map<String, dynamic>.from(event! as Map<Object?, Object?>),
        )
        .toList(),
    if (json['reason'] case final String reason) 'reason': reason,
  };
}
