import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/player_match_movement_audience.dart';
import 'package:aonw_server/src/multiplayer/player_match_view_projector.dart';
import 'package:test/test.dart';

const _playerA = 'player-a';
const _playerB = 'player-b';
const _observer = 'player-observer';
const _recipient = MatchRecipient(
  userIdentifier: 'observer-user',
  playerId: _observer,
);

typedef _Point = ({int col, int row});

void main() {
  group('PlayerMatchMovementAudience annotation', () {
    test('preserves authoritative empty input', () {
      final state = _state(a: (col: 0, row: 0), b: (col: 0, row: 1));

      expect(
        PlayerMatchMovementAudience.annotateForStorage(
          executions: const [],
          participantPlayerIds: const [_playerA, _playerB],
          previousUnits: state.units,
          nextUnits: state.units,
          previousFog: state.fogOfWar,
          nextFog: state.fogOfWar,
        ).isEmpty,
        isTrue,
      );
    });

    test('owners receive complete chains with empty fog', () {
      final canonical = _annotate(
        executions: _orderedExecutions(),
        previous: _state(a: (col: 0, row: 0), b: (col: 0, row: 1)),
        next: _state(a: (col: 3, row: 0), b: (col: 1, row: 1)),
      );

      expect(_projectSnapshots(canonical, _playerA), [
        'unit-a:0,0->1,0;audience=public',
        'unit-a:1,0->2,0|3,0;audience=public',
      ]);
      expect(_projectSnapshots(canonical, _playerB), [
        'unit-b:0,1->1,1;audience=public',
      ]);
      expect(_projectSnapshots(canonical, _observer), isEmpty);
    });

    test('observer requires every coordinate in both fog snapshots', () {
      final allCoordinates = _hexes(const [
        (col: 0, row: 0),
        (col: 1, row: 0),
        (col: 2, row: 0),
        (col: 3, row: 0),
        (col: 0, row: 1),
        (col: 1, row: 1),
      ]);
      final withoutHiddenIntermediate = {...allCoordinates}
        ..remove(const HexCoordinate(col: 2, row: 0));
      final visibilityPairs = [
        (previous: allCoordinates, next: withoutHiddenIntermediate),
        (previous: withoutHiddenIntermediate, next: allCoordinates),
      ];

      for (final visibility in visibilityPairs) {
        final canonical = _annotate(
          executions: _orderedExecutions(),
          previous: _state(
            a: (col: 0, row: 0),
            b: (col: 0, row: 1),
            observerVisible: visibility.previous,
          ),
          next: _state(
            a: (col: 3, row: 0),
            b: (col: 1, row: 1),
            observerVisible: visibility.next,
          ),
        );

        expect(canonical.values.map(_wireExecutionSnapshot), [
          'unit-a:0,0->1,0;audience=player-a',
          'unit-b:0,1->1,1;audience=player-b,player-observer',
          'unit-a:1,0->2,0|3,0;audience=player-a',
        ]);
        expect(_projectSnapshots(canonical, _observer), [
          'unit-b:0,1->1,1;audience=public',
        ]);
      }
    });

    test('preserves global order and one audience for split unit chains', () {
      final visible = _hexes(const [
        (col: 0, row: 0),
        (col: 1, row: 0),
        (col: 2, row: 0),
        (col: 3, row: 0),
        (col: 0, row: 1),
        (col: 1, row: 1),
      ]);
      final canonical = _annotate(
        executions: _orderedExecutions(),
        previous: _state(
          a: (col: 0, row: 0),
          b: (col: 0, row: 1),
          observerVisible: visible,
        ),
        next: _state(
          a: (col: 3, row: 0),
          b: (col: 1, row: 1),
          observerVisible: visible,
        ),
      );

      expect(canonical.values.map(_wireExecutionSnapshot), [
        'unit-a:0,0->1,0;audience=player-a,player-observer',
        'unit-b:0,1->1,1;audience=player-b,player-observer',
        'unit-a:1,0->2,0|3,0;audience=player-a,player-observer',
      ]);
      expect(_projectSnapshots(canonical, _observer), [
        'unit-a:0,0->1,0;audience=public',
        'unit-b:0,1->1,1;audience=public',
        'unit-a:1,0->2,0|3,0;audience=public',
      ]);
    });

    test('drops a broken or unknown unit chain but retains other order', () {
      final brokenA2 = _execution(
        unitId: 'unit-a',
        from: (col: 2, row: 0),
        steps: const [(col: 3, row: 0)],
      );
      final unknown = _execution(
        unitId: 'unknown',
        from: (col: 4, row: 0),
        steps: const [(col: 5, row: 0)],
      );
      final ordered = _orderedExecutions();

      final canonical = _annotate(
        executions: [ordered[0], ordered[1], brokenA2, unknown],
        previous: _state(a: (col: 0, row: 0), b: (col: 0, row: 1)),
        next: _state(a: (col: 3, row: 0), b: (col: 1, row: 1)),
      );

      expect(canonical.values.map(_wireExecutionSnapshot), [
        'unit-b:0,1->1,1;audience=player-b',
      ]);
    });

    test('fails closed on duplicate, transferred, or mismatched units', () {
      final previous = _state(a: (col: 0, row: 0), b: (col: 0, row: 1));
      final next = _state(a: (col: 3, row: 0), b: (col: 1, row: 1));
      final invalidTransitions = [
        (
          previous: previous.copyWith(
            units: [
              ...previous.units,
              _unit(
                id: 'unit-a',
                ownerPlayerId: _playerA,
                at: (col: 0, row: 0),
              ),
            ],
          ),
          next: next,
        ),
        (
          previous: previous,
          next: next.copyWith(
            units: [
              _unit(
                id: 'unit-a',
                ownerPlayerId: _playerB,
                at: (col: 3, row: 0),
              ),
              next.units.byId('unit-b')!,
            ],
          ),
        ),
        (
          previous: previous,
          next: next.copyWith(
            units: [
              _unit(
                id: 'unit-a',
                ownerPlayerId: _playerA,
                at: (col: 2, row: 0),
              ),
              next.units.byId('unit-b')!,
            ],
          ),
        ),
      ];

      for (final transition in invalidTransitions) {
        final canonical = _annotate(
          executions: _orderedExecutions(),
          previous: transition.previous,
          next: transition.next,
        );
        expect(canonical.values.map(_wireExecutionSnapshot), [
          'unit-b:0,1->1,1;audience=player-b',
        ]);
      }
    });
  });

  group('PlayerMatchMovementAudience projection', () {
    test('strips metadata while preserving recipient order', () {
      final canonical = WireMovementExecutionList([
        _wire(_orderedExecutions()[0], audience: const [_playerA, _observer]),
        _wire(_orderedExecutions()[1], audience: const [_playerB, _observer]),
        _wire(_orderedExecutions()[2], audience: const [_playerA, _observer]),
      ]);

      final projected = PlayerMatchMovementAudience.projectForRecipient(
        canonical,
        recipientPlayerId: _observer,
      );

      expect(projected.values.map(_wireExecutionSnapshot), [
        'unit-a:0,0->1,0;audience=public',
        'unit-b:0,1->1,1;audience=public',
        'unit-a:1,0->2,0|3,0;audience=public',
      ]);
      expect(projected.toJson().toString(), isNot(contains('_serverAudience')));
    });

    test('suppresses a complete chain with missing or mismatched metadata', () {
      final ordered = _orderedExecutions();
      final variants = [
        WireMovementExecutionList([
          _wire(ordered[0], audience: const [_playerA, _observer]),
          _wire(ordered[1], audience: const [_playerB, _observer]),
          _wire(ordered[2]),
        ]),
        WireMovementExecutionList([
          _wire(ordered[0], audience: const [_playerA, _observer]),
          _wire(ordered[1], audience: const [_playerB, _observer]),
          _wire(ordered[2], audience: const [_playerA]),
        ]),
      ];

      for (final canonical in variants) {
        expect(_projectSnapshots(canonical, _observer), [
          'unit-b:0,1->1,1;audience=public',
        ]);
      }
    });

    test('strict wire decoding rejects invalid audience metadata', () {
      final base = _wire(
        _orderedExecutions().first,
        audience: const [_playerA],
      ).toJson();

      for (final invalidAudience in [
        <Object?>[],
        [_playerA, _playerA],
        [_playerA, 7],
      ]) {
        expect(
          () => WireMovementExecutionList.fromJson([
            {...base, '_serverAudiencePlayerIds': invalidAudience},
          ]),
          throwsArgumentError,
        );
      }
    });

    test('event and ack projection preserve empty and visible movement', () {
      const projector = PlayerMatchViewProjector();
      final emptyMovements = WireMovementExecutionList(const []);
      final emptyEvent = _event(movementExecutions: emptyMovements);
      const snapshot = WireSnapshot(
        matchId: 'match-1',
        offset: 1,
        save: {},
        state: {},
      );
      final emptyAck = WireCommandAck(
        matchId: 'match-1',
        accepted: true,
        offset: 1,
        snapshot: snapshot,
        movementExecutions: emptyMovements,
      );
      final visibleCanonical = WireMovementExecutionList([
        _wire(
          _orderedExecutions().first,
          audience: const [_playerA, _observer],
        ),
      ]);
      final visibleEvent = projector.eventFor(
        _event(movementExecutions: visibleCanonical),
        _recipient,
      );
      final visibleAck = projector.ackFor(
        emptyAck.copyWith(movementExecutions: visibleCanonical),
        _recipient,
      );

      expect(
        projector.eventFor(emptyEvent, _recipient).movementExecutions.isEmpty,
        isTrue,
      );
      expect(
        projector.ackFor(emptyAck, _recipient).movementExecutions.isEmpty,
        isTrue,
      );
      for (final movements in [
        visibleEvent.movementExecutions,
        visibleAck.movementExecutions,
      ]) {
        expect(movements.values.map(_wireExecutionSnapshot), [
          'unit-a:0,0->1,0;audience=public',
        ]);
        expect(
          movements.toJson().toString(),
          isNot(contains('_serverAudience')),
        );
      }
    });
  });
}

WireMovementExecutionList _annotate({
  required Iterable<MovementCommandExecution> executions,
  required PersistentGameState previous,
  required PersistentGameState next,
}) {
  return PlayerMatchMovementAudience.annotateForStorage(
    executions: executions,
    participantPlayerIds: const [_playerB, _observer, _playerA, _observer],
    previousUnits: previous.units,
    nextUnits: next.units,
    previousFog: previous.fogOfWar,
    nextFog: next.fogOfWar,
  );
}

List<MovementCommandExecution> _orderedExecutions() => [
  _execution(
    unitId: 'unit-a',
    from: (col: 0, row: 0),
    steps: const [(col: 1, row: 0)],
  ),
  _execution(
    unitId: 'unit-b',
    from: (col: 0, row: 1),
    steps: const [(col: 1, row: 1)],
  ),
  _execution(
    unitId: 'unit-a',
    from: (col: 1, row: 0),
    steps: const [(col: 2, row: 0), (col: 3, row: 0)],
  ),
];

MovementCommandExecution _execution({
  required String unitId,
  required _Point from,
  required List<_Point> steps,
}) {
  return MovementCommandExecution(
    unitId: unitId,
    fromCol: from.col,
    fromRow: from.row,
    steps: [
      for (var index = 0; index < steps.length; index++)
        UnitMovementStep(
          col: steps[index].col,
          row: steps[index].row,
          enterCost: 1,
          cumulativeCost: index + 1,
        ),
    ],
  );
}

WireMovementExecution _wire(
  MovementCommandExecution execution, {
  List<String>? audience,
}) {
  final encoded = MovementExecutionWireMapper.encode(execution);
  return WireMovementExecution(
    unitId: encoded.unitId,
    fromCol: encoded.fromCol,
    fromRow: encoded.fromRow,
    steps: encoded.steps,
    serverAudiencePlayerIds: audience,
  );
}

PersistentGameState _state({
  required _Point a,
  required _Point b,
  Set<HexCoordinate> observerVisible = const {},
}) {
  return PersistentGameState(
    units: [
      _unit(id: 'unit-a', ownerPlayerId: _playerA, at: a),
      _unit(id: 'unit-b', ownerPlayerId: _playerB, at: b),
    ],
    fogOfWar: FogOfWarState(
      players: {
        _observer: PlayerFogOfWar(
          playerId: _observer,
          visibleHexes: observerVisible,
        ),
      },
    ),
  );
}

GameUnit _unit({
  required String id,
  required String ownerPlayerId,
  required _Point at,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.scout,
    name: id,
    col: at.col,
    row: at.row,
  );
}

Set<HexCoordinate> _hexes(Iterable<_Point> points) => {
  for (final point in points) HexCoordinate(col: point.col, row: point.row),
};

List<String> _projectSnapshots(
  WireMovementExecutionList canonical,
  String playerId,
) {
  return PlayerMatchMovementAudience.projectForRecipient(
    canonical,
    recipientPlayerId: playerId,
  ).values.map(_wireExecutionSnapshot).toList();
}

String _wireExecutionSnapshot(WireMovementExecution execution) {
  final path = execution.steps
      .map((step) => '${step.col},${step.row}')
      .join('|');
  final audience = execution.serverAudiencePlayerIds?.join(',') ?? 'public';
  return '${execution.unitId}:${execution.fromCol},${execution.fromRow}'
      '->$path;audience=$audience';
}

WireEvent _event({required WireMovementExecutionList movementExecutions}) {
  return WireEvent(
    matchId: 'match-1',
    offset: 1,
    timestamp: DateTime.utc(2026, 7, 25),
    movementExecutions: movementExecutions,
  );
}
