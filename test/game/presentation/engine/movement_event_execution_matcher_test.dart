import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovementEventExecutionMatcher', () {
    test('binds two sequential chains to separated exact events', () {
      final effects = _project(
        events: const [
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 0,
            fromRow: 0,
            toCol: 1,
            toRow: 0,
          ),
          CityFoundedEvent(cityId: 'city', ownerPlayerId: 'player_1'),
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 1,
            fromRow: 0,
            toCol: 2,
            toRow: 0,
          ),
        ],
        executions: _twoSteps,
      );

      expect(effects.whereType<AnimateUnitMoveEffect>().map(_snapshot), const [
        ('unit_a', 0, 0, 1, 0),
        ('unit_a', 1, 0, 2, 0),
      ]);
      final firstMove = effects.indexWhere(
        (effect) => effect is AnimateUnitMoveEffect && effect.fromCol == 0,
      );
      final city = effects.indexWhere(
        (effect) =>
            effect is SpawnParticleBurstEffect &&
            effect.kind == ParticleBurstKind.cityFounded,
      );
      final secondMove = effects.indexWhere(
        (effect) => effect is AnimateUnitMoveEffect && effect.fromCol == 1,
      );
      expect(firstMove, lessThan(city));
      expect(city, lessThan(secondMove));
    });

    test('prefers an authoritative chain over inconsistent events', () {
      final effects = _project(
        events: const [
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 0,
            fromRow: 0,
            toCol: 2,
            toRow: 0,
          ),
          CityFoundedEvent(cityId: 'city', ownerPlayerId: 'player_1'),
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 1,
            fromRow: 0,
            toCol: 2,
            toRow: 0,
          ),
        ],
        executions: _twoSteps,
      );

      expect(effects.whereType<AnimateUnitMoveEffect>().map(_snapshot), const [
        ('unit_a', 0, 0, 1, 0),
        ('unit_a', 1, 0, 2, 0),
      ]);
    });

    test('uses authoritative execution or a safe visible-event fallback', () {
      expect(
        _project(
          events: const [
            UnitMovedEvent(
              unitId: 'unit_a',
              fromCol: 0,
              fromRow: 0,
              toCol: 1,
              toRow: 0,
            ),
          ],
          executions: _twoSteps,
        ).whereType<AnimateUnitMoveEffect>().map(_snapshot),
        const [('unit_a', 0, 0, 1, 0), ('unit_a', 1, 0, 2, 0)],
      );
      expect(
        _project(
          events: const [
            UnitMovedEvent(
              unitId: 'unit_a',
              fromCol: 0,
              fromRow: 0,
              toCol: 2,
              toRow: 0,
            ),
          ],
          executions: [_execution(0, 1)],
        ).whereType<AnimateUnitMoveEffect>().map(_snapshot),
        const [('unit_a', 0, 0, 2, 0)],
      );
    });
  });
}

List<RendererEffect> _project({
  required List<GameEvent> events,
  required List<MovementCommandExecution> executions,
}) {
  const city = GameCity(
    id: 'city',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: CityHex(col: 4, row: 0),
  );
  return DomainEventPresentationProjector.projectObserved(
    interactionEffects: const [],
    events: events,
    visibleMovementExecutions: executions,
    previousState: _state(0),
    state: GameClientState(units: [_unit(2)], cities: const [city]),
  );
}

GameClientState _state(int col) => GameClientState(units: [_unit(col)]);

GameUnit _unit(int col) => GameUnit.produced(
  id: 'unit_a',
  ownerPlayerId: 'player_2',
  type: GameUnitType.warrior,
  col: col,
  row: 0,
);

List<MovementCommandExecution> get _twoSteps => [
  _execution(0, 1),
  _execution(1, 2),
];

MovementCommandExecution _execution(int fromCol, int toCol) =>
    MovementCommandExecution(
      unitId: 'unit_a',
      fromCol: fromCol,
      fromRow: 0,
      steps: [
        UnitMovementStep(
          col: toCol,
          row: 0,
          enterCost: 1,
          cumulativeCost: toCol,
        ),
      ],
    );

typedef _Snapshot = (String, int, int, int, int);

_Snapshot _snapshot(AnimateUnitMoveEffect effect) {
  final step = effect.steps.single;
  return (effect.unitId, effect.fromCol, effect.fromRow, step.col, step.row);
}
