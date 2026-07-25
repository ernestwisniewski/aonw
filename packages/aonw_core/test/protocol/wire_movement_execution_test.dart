import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('wire movement execution JSON', () {
    test('round-trips exact step, execution, and list values', () {
      const step = WireMovementStep(
        col: 1,
        row: 2,
        enterCost: 3,
        cumulativeCost: 4,
      );
      final execution = _execution(
        serverAudiencePlayerIds: const ['player_1', 'player_2'],
      );
      final values = WireMovementExecutionList([execution]);

      expect(WireMovementStep.fromJson(_stepJson()), step);
      expect(step.toJson(), _stepJson());
      expect(
        WireMovementExecution.fromJson(_executionJson(withAudience: true)),
        execution,
      );
      expect(execution.toJson(), _executionJson(withAudience: true));
      expect(
        WireMovementExecutionList.fromJson([
          _executionJson(withAudience: true),
        ]),
        values,
      );
      expect(values.toJson(), [_executionJson(withAudience: true)]);
      expect(execution.toJson(includeServerMetadata: false), _executionJson());
    });

    test('rejects malformed scalar and nested collection types', () {
      for (final invalid in <Object?>[
        {..._stepJson(), 'col': '1'},
        {..._stepJson(), 'row': 2.0},
        {..._stepJson(), 'enterCost': true},
        {..._stepJson(), 'cumulativeCost': null},
      ]) {
        expect(
          () => WireMovementStep.fromJson(invalid! as Map<String, dynamic>),
          throwsArgumentError,
        );
      }

      for (final invalid in <Map<String, dynamic>>[
        {..._executionJson(), 'unitId': ''},
        {..._executionJson(), 'fromCol': '0'},
        {..._executionJson(), 'fromRow': false},
        {..._executionJson(), 'steps': 'not-a-list'},
        {..._executionJson(), 'steps': <Object>[]},
        {
          ..._executionJson(),
          'steps': [7],
        },
      ]) {
        expect(
          () => WireMovementExecution.fromJson(invalid),
          throwsArgumentError,
        );
      }

      for (final invalid in <Object?>[
        null,
        'not-a-list',
        <String, Object?>{},
        <Object?>[7],
      ]) {
        expect(
          () => WireMovementExecutionList.fromJson(invalid),
          throwsArgumentError,
        );
      }
    });

    test('requires canonical server audience metadata when present', () {
      expect(
        WireMovementExecution.fromJson(
          _executionJson(),
        ).serverAudiencePlayerIds,
        isNull,
      );

      for (final invalidAudience in <Object?>[
        null,
        <Object?>[],
        <Object?>[''],
        <Object?>['player_1', 'player_1'],
        <Object?>['player_2', 'player_1'],
        <Object?>['player_1', 2],
        'player_1',
      ]) {
        expect(
          () => WireMovementExecution.fromJson({
            ..._executionJson(),
            '_serverAudiencePlayerIds': invalidAudience,
          }),
          throwsArgumentError,
        );
      }
    });

    test('enforces value invariants at direct construction', () {
      expect(
        () => WireMovementExecution(
          unitId: '',
          fromCol: 0,
          fromRow: 0,
          steps: const [_step],
        ),
        throwsArgumentError,
      );
      expect(
        () => WireMovementExecution(
          unitId: 'unit_1',
          fromCol: 0,
          fromRow: 0,
          steps: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => _execution(serverAudiencePlayerIds: const []),
        throwsArgumentError,
      );
      expect(
        () =>
            _execution(serverAudiencePlayerIds: const ['player_2', 'player_1']),
        throwsArgumentError,
      );
    });
  });

  group('wire movement execution value semantics', () {
    test('uses structural equality and hashes every ordered field', () {
      final first = _execution(
        serverAudiencePlayerIds: const ['player_1', 'player_2'],
      );
      final equal = WireMovementExecution.fromJson(
        _executionJson(withAudience: true),
      );
      final metadataFree = _execution();
      final reordered = WireMovementExecution(
        unitId: 'unit_1',
        fromCol: 0,
        fromRow: 0,
        steps: const [
          WireMovementStep(col: 3, row: 4, enterCost: 5, cumulativeCost: 6),
          _step,
        ],
        serverAudiencePlayerIds: const ['player_1', 'player_2'],
      );

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(first, isNot(metadataFree));
      expect(first, isNot(reordered));

      final list = WireMovementExecutionList([first, metadataFree]);
      final equalList = WireMovementExecutionList([equal, _execution()]);
      expect(list, equalList);
      expect(list.hashCode, equalList.hashCode);
      expect(list, isNot(WireMovementExecutionList([metadataFree, first])));
    });

    test('maps domain executions field-for-field in both directions', () {
      final domain = MovementCommandExecution(
        unitId: 'unit_1',
        fromCol: 0,
        fromRow: 0,
        steps: const [
          UnitMovementStep(col: 1, row: 2, enterCost: 3, cumulativeCost: 4),
          UnitMovementStep(col: 3, row: 4, enterCost: 5, cumulativeCost: 6),
        ],
      );

      final wire = MovementExecutionWireMapper.encode(domain);
      final restored = MovementExecutionWireMapper.decode(wire);

      expect(wire, _execution());
      expect(wire.serverAudiencePlayerIds, isNull);
      expect(restored.unitId, domain.unitId);
      expect((restored.fromCol, restored.fromRow), (0, 0));
      expect(restored.steps, domain.steps);
      expect(MovementExecutionWireMapper.encode(restored), wire);
    });

    test('does not carry server audience metadata into the domain', () {
      final annotated = _execution(serverAudiencePlayerIds: const ['player_1']);

      final reencoded = MovementExecutionWireMapper.encode(
        MovementExecutionWireMapper.decode(annotated),
      );

      expect(reencoded.serverAudiencePlayerIds, isNull);
      expect(
        reencoded.toJson(),
        annotated.toJson(includeServerMetadata: false),
      );
    });
  });

  test('owns source lists and every JSON collection it returns', () {
    final sourceSteps = <WireMovementStep>[
      _step,
      const WireMovementStep(col: 3, row: 4, enterCost: 5, cumulativeCost: 6),
    ];
    final sourceAudience = <String>['player_1'];
    final execution = WireMovementExecution(
      unitId: 'unit_1',
      fromCol: 0,
      fromRow: 0,
      steps: sourceSteps,
      serverAudiencePlayerIds: sourceAudience,
    );
    final sourceExecutions = <WireMovementExecution>[execution];
    final values = WireMovementExecutionList(sourceExecutions);
    final expected = WireMovementExecutionList([
      _execution(serverAudiencePlayerIds: const ['player_1']),
    ]);

    sourceSteps.clear();
    sourceAudience
      ..clear()
      ..add('player_9');
    sourceExecutions.clear();
    expect(values, expected);

    values.toJson().clear();
    expect(values, expected);

    final executionJson = values.toJson().single;
    executionJson['unitId'] = 'mutated';
    expect(values, expected);

    (values.toJson().single['steps']! as List<dynamic>).clear();
    expect(values, expected);

    final stepJson =
        (values.toJson().single['steps']! as List<dynamic>).first
            as Map<String, dynamic>;
    stepJson['col'] = 99;
    expect(values, expected);

    (values.toJson().single['_serverAudiencePlayerIds']! as List<dynamic>)
      ..clear()
      ..add('player_9');
    expect(values, expected);
  });
}

const _step = WireMovementStep(col: 1, row: 2, enterCost: 3, cumulativeCost: 4);

Map<String, dynamic> _stepJson() => {
  'col': 1,
  'row': 2,
  'enterCost': 3,
  'cumulativeCost': 4,
};

WireMovementExecution _execution({Iterable<String>? serverAudiencePlayerIds}) {
  return WireMovementExecution(
    unitId: 'unit_1',
    fromCol: 0,
    fromRow: 0,
    steps: const [
      _step,
      WireMovementStep(col: 3, row: 4, enterCost: 5, cumulativeCost: 6),
    ],
    serverAudiencePlayerIds: serverAudiencePlayerIds,
  );
}

Map<String, dynamic> _executionJson({bool withAudience = false}) => {
  'unitId': 'unit_1',
  'fromCol': 0,
  'fromRow': 0,
  'steps': [
    _stepJson(),
    {'col': 3, 'row': 4, 'enterCost': 5, 'cumulativeCost': 6},
  ],
  if (withAudience) '_serverAudiencePlayerIds': ['player_1', 'player_2'],
};
