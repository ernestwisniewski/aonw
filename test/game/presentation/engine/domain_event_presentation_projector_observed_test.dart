import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/domain_event_presentation_projector.dart';
import 'package:aonw/game/presentation/engine/projected_game_effect.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainEventPresentationProjector.projectObserved', () {
    test('assigns stable authoritative identity and logical start offsets', () {
      final before = _state(aCol: 0);
      final after = _state(aCol: 2);
      const identity = PresentationBatchIdentity(
        sourceId: 'match_1',
        eventOffset: 42,
      );

      ProjectedGameEffectBatch project() =>
          DomainEventPresentationProjector.projectObservedBatch(
            identity: identity,
            interactionEffects: const [JumpCameraEffect(col: 9, row: 9)],
            previousState: before,
            state: after,
            events: const [
              UnitMovedEvent(
                unitId: 'unit_a',
                fromCol: 0,
                fromRow: 0,
                toCol: 2,
                toRow: 0,
              ),
            ],
            visibleMovementExecutions: _exactExecutions().where(
              (execution) => execution.unitId == 'unit_a',
            ),
          );

      final acknowledged = project();
      final observed = project();
      expect(acknowledged.projectedInteractionEffects, hasLength(1));
      expect(acknowledged.domainEffects.map((item) => item.animationId), [
        'match_1:42:AnimateUnitMoveEffect:unit_a:0',
        'match_1:42:AnimateUnitMoveEffect:unit_a:1',
      ]);
      expect(
        observed.domainEffects.map((item) => item.animationId),
        acknowledged.domainEffects.map((item) => item.animationId),
      );
      expect(acknowledged.domainEffects.map((item) => item.startOffset), const [
        Duration.zero,
        Duration(milliseconds: 180),
      ]);
    });

    test('ACK and observer project the same visible facts exactly once', () {
      final before = _state(aCol: 0, bCol: 0);
      final after = _state(aCol: 2, bCol: 1);
      const events = [
        UnitMovedEvent(
          unitId: 'unit_a',
          fromCol: 0,
          fromRow: 0,
          toCol: 2,
          toRow: 0,
        ),
        UnitMovedEvent(
          unitId: 'unit_b',
          fromCol: 0,
          fromRow: 1,
          toCol: 1,
          toRow: 1,
        ),
      ];

      List<RendererEffect> project() =>
          DomainEventPresentationProjector.projectObserved(
            interactionEffects: const [],
            previousState: before,
            state: after,
            events: events,
            visibleMovementExecutions: _exactExecutions(),
          );

      final acknowledged = project();
      final observed = project();
      expect(
        acknowledged.whereType<AnimateUnitMoveEffect>().map(_snapshot),
        observed.whereType<AnimateUnitMoveEffect>().map(_snapshot),
      );
      expect(
        acknowledged.whereType<AnimateUnitMoveEffect>().map(_snapshot),
        const [
          ('unit_a', 0, 0, 1, 0, 7, 7),
          ('unit_b', 0, 1, 1, 1, 11, 11),
          ('unit_a', 1, 0, 2, 0, 13, 20),
        ],
      );
    });

    test('preserves exact A1 B1 A2 order and suppresses event duplicates', () {
      final before = _state(aCol: 0, bCol: 0);
      final after = _state(aCol: 2, bCol: 1);

      final effects = DomainEventPresentationProjector.projectObserved(
        interactionEffects: const [],
        previousState: before,
        state: after,
        events: const [
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 0,
            fromRow: 0,
            toCol: 2,
            toRow: 0,
          ),
          UnitMovedEvent(
            unitId: 'unit_b',
            fromCol: 0,
            fromRow: 1,
            toCol: 1,
            toRow: 1,
          ),
        ],
        visibleMovementExecutions: _exactExecutions(),
      );

      expect(effects.whereType<AnimateUnitMoveEffect>().map(_snapshot), const [
        ('unit_a', 0, 0, 1, 0, 7, 7),
        ('unit_b', 0, 1, 1, 1, 11, 11),
        ('unit_a', 1, 0, 2, 0, 13, 20),
      ]);
      expect(effects.clear, throwsUnsupportedError);
    });

    test('deduplicates direct fallback for ambiguous duplicate events', () {
      final effects = DomainEventPresentationProjector.projectObserved(
        interactionEffects: const [],
        previousState: _state(aCol: 0, bCol: 0),
        state: _state(aCol: 2, bCol: 0),
        events: const [
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 0,
            fromRow: 0,
            toCol: 2,
            toRow: 0,
          ),
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 0,
            fromRow: 0,
            toCol: 2,
            toRow: 0,
          ),
        ],
        visibleMovementExecutions: [
          _execution('unit_a', 0, 0, 1, 0, 7, 7),
          _execution('unit_a', 1, 0, 2, 0, 13, 20),
        ],
      );

      expect(effects.whereType<AnimateUnitMoveEffect>().map(_snapshot), const [
        ('unit_a', 0, 0, 2, 0, 0, 0),
      ]);
    });

    test('keeps a legal repeated fallback after a continuous round trip', () {
      final effects = DomainEventPresentationProjector.projectObserved(
        interactionEffects: const [],
        previousState: _state(aCol: 0),
        state: _state(aCol: 1),
        events: const [
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 0,
            fromRow: 0,
            toCol: 1,
            toRow: 0,
          ),
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 1,
            fromRow: 0,
            toCol: 0,
            toRow: 0,
          ),
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 0,
            fromRow: 0,
            toCol: 1,
            toRow: 0,
          ),
        ],
        visibleMovementExecutions: const [],
      );

      expect(effects.whereType<AnimateUnitMoveEffect>().map(_snapshot), const [
        ('unit_a', 0, 0, 1, 0, 0, 0),
        ('unit_a', 1, 0, 0, 0, 0, 0),
        ('unit_a', 0, 0, 1, 0, 0, 0),
      ]);
    });

    test('places typed movement at its global event position', () {
      final attacker = GameUnit.produced(
        id: 'attacker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final defender = GameUnit.produced(
        id: 'defender',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 1,
        row: 0,
      );
      final mover = GameUnit.produced(
        id: 'mover',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 2,
        row: 0,
      );
      const city = GameCity(
        id: 'city',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 4, row: 0),
      );
      final effects = DomainEventPresentationProjector.projectObserved(
        interactionEffects: const [],
        previousState: GameState(units: [attacker, defender, mover]),
        state: GameState(
          units: [attacker, defender, mover.copyWith(col: 3)],
          cities: const [city],
        ),
        events: [
          CombatResolvedEvent(
            attackerUnitId: attacker.id,
            defenderUnitId: defender.id,
            outcome: CombatOutcome(
              attackerUnitId: attacker.id,
              defenderUnitId: defender.id,
              attackerHpAfter: 8,
              defenderHpAfter: 6,
              attackerKilled: false,
              defenderKilled: false,
              steps: [AttackStep(damage: 4), RetaliationStep(damage: 2)],
            ),
          ),
          const UnitMovedEvent(
            unitId: 'mover',
            fromCol: 2,
            fromRow: 0,
            toCol: 3,
            toRow: 0,
          ),
          const CityFoundedEvent(cityId: 'city', ownerPlayerId: 'player_1'),
        ],
        visibleMovementExecutions: [_execution('mover', 2, 0, 3, 0, 5, 5)],
      );

      final combat = effects.indexWhere(
        (effect) => effect is PlayCombatAnimationEffect,
      );
      final movement = effects.indexWhere(
        (effect) => effect is AnimateUnitMoveEffect,
      );
      final construction = effects.indexWhere(
        (effect) =>
            effect is SpawnParticleBurstEffect &&
            effect.kind == ParticleBurstKind.cityFounded,
      );
      expect(combat, greaterThanOrEqualTo(0));
      expect(movement, greaterThan(combat));
      expect(construction, greaterThan(movement));
    });

    test('empty execution evidence uses one visible event fallback', () {
      final effects = DomainEventPresentationProjector.projectObserved(
        interactionEffects: const [],
        previousState: _state(aCol: 0),
        state: _state(aCol: 2),
        events: const [
          UnitMovedEvent(
            unitId: 'unit_a',
            fromCol: 0,
            fromRow: 0,
            toCol: 2,
            toRow: 0,
          ),
        ],
        visibleMovementExecutions: const [],
      );

      expect(effects.whereType<AnimateUnitMoveEffect>().map(_snapshot), const [
        ('unit_a', 0, 0, 2, 0, 0, 0),
      ]);
    });

    test('empty evidence never infers movement from the state delta', () {
      final effects = DomainEventPresentationProjector.projectObserved(
        interactionEffects: const [],
        previousState: _state(aCol: 0),
        state: _state(aCol: 2),
        events: const [],
        visibleMovementExecutions: const [],
      );

      expect(effects.whereType<AnimateUnitMoveEffect>(), isEmpty);
    });

    for (final invalid in [
      [
        _execution('unit_a', 9, 0, 1, 0, 7, 7),
        _execution('unit_a', 1, 0, 2, 0, 13, 20),
      ],
      [
        _execution('unit_a', 0, 0, 1, 0, 7, 7),
        _execution('unit_a', 9, 0, 2, 0, 13, 20),
      ],
      [_execution('unit_a', 0, 0, 1, 0, 7, 7)],
    ]) {
      test('invalid chain falls back to the visible event only', () {
        final effects = DomainEventPresentationProjector.projectObserved(
          interactionEffects: const [],
          previousState: _state(aCol: 0),
          state: _state(aCol: 2),
          events: const [
            UnitMovedEvent(
              unitId: 'unit_a',
              fromCol: 0,
              fromRow: 0,
              toCol: 2,
              toRow: 0,
            ),
          ],
          visibleMovementExecutions: invalid,
        );

        expect(
          effects.whereType<AnimateUnitMoveEffect>().map(_snapshot),
          const [('unit_a', 0, 0, 2, 0, 0, 0)],
        );
      });
    }

    test(
      'uses exact evidence and fallback without duplicating either unit',
      () {
        final effects = DomainEventPresentationProjector.projectObserved(
          interactionEffects: const [],
          previousState: _state(aCol: 0, bCol: 0),
          state: _state(aCol: 2, bCol: 1),
          events: const [
            UnitMovedEvent(
              unitId: 'unit_b',
              fromCol: 0,
              fromRow: 1,
              toCol: 1,
              toRow: 1,
            ),
            UnitMovedEvent(
              unitId: 'unit_a',
              fromCol: 0,
              fromRow: 0,
              toCol: 2,
              toRow: 0,
            ),
          ],
          visibleMovementExecutions: _exactExecutions().where(
            (execution) => execution.unitId == 'unit_a',
          ),
        );

        expect(
          effects.whereType<AnimateUnitMoveEffect>().map(_snapshot),
          const [
            ('unit_b', 0, 1, 1, 1, 0, 0),
            ('unit_a', 0, 0, 1, 0, 7, 7),
            ('unit_a', 1, 0, 2, 0, 13, 20),
          ],
        );
      },
    );
  });
}

GameState _state({required int aCol, int? bCol}) {
  return GameState(
    units: [
      GameUnit.produced(
        id: 'unit_a',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: aCol,
        row: 0,
      ),
      if (bCol != null)
        GameUnit.produced(
          id: 'unit_b',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: bCol,
          row: 1,
        ),
    ],
    activePlayerId: 'player_1',
    activePlayerCanAct: true,
  );
}

List<MovementCommandExecution> _exactExecutions() {
  return [
    _execution('unit_a', 0, 0, 1, 0, 7, 7),
    _execution('unit_b', 0, 1, 1, 1, 11, 11),
    _execution('unit_a', 1, 0, 2, 0, 13, 20),
  ];
}

MovementCommandExecution _execution(
  String unitId,
  int fromCol,
  int fromRow,
  int toCol,
  int toRow,
  int enterCost,
  int cumulativeCost,
) {
  return MovementCommandExecution(
    unitId: unitId,
    fromCol: fromCol,
    fromRow: fromRow,
    steps: [
      UnitMovementStep(
        col: toCol,
        row: toRow,
        enterCost: enterCost,
        cumulativeCost: cumulativeCost,
      ),
    ],
  );
}

typedef _MovementSnapshot = (String, int, int, int, int, int, int);

_MovementSnapshot _snapshot(AnimateUnitMoveEffect effect) {
  final step = effect.steps.single;
  return (
    effect.unitId,
    effect.fromCol,
    effect.fromRow,
    step.col,
    step.row,
    step.enterCost,
    step.cumulativeCost,
  );
}
