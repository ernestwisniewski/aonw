import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/replay/replay_renderer_effect_planner.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

part 'replay_renderer_effect_planner_test_support.dart';

void main() {
  group('ReplayRendererEffectPlanner', () {
    test('upcasts combat geometry only for historical replay steps', () {
      final attacker = GameUnit(
        id: 'attacker',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: 'Attacker',
        col: 2,
        row: 4,
      );
      final defender = GameUnit(
        id: 'defender',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: 'Defender',
        col: 3,
        row: 4,
      );

      final effects = ReplayRendererEffectPlanner.effectsForStep(
        interactionEffects: const [],
        events: [
          CombatResolvedEvent(
            attackerUnitId: 'attacker',
            defenderUnitId: 'defender',
            outcome: CombatOutcome(
              attackerUnitId: 'attacker',
              defenderUnitId: 'defender',
              attackerHpAfter: 7,
              defenderHpAfter: 0,
              attackerKilled: false,
              defenderKilled: true,
              steps: [AttackStep(damage: 10)],
            ),
          ),
        ],
        previousState: GameClientState(units: [attacker, defender]),
        state: GameClientState(units: [attacker]),
      );

      final animation = effects.whereType<PlayCombatAnimationEffect>().single;
      expect(
        (
          animation.attackerFromCol,
          animation.attackerFromRow,
          animation.attackerToCol,
          animation.attackerToRow,
        ),
        (2, 4, 3, 4),
      );
    });

    test('projects auto-explore movement from canonical execution facts', () {
      final scout = _scout(col: 1, row: 1);
      final movedScout = scout.copyWith(col: 2, row: 1);

      final effects = ReplayRendererEffectPlanner.effectsForStep(
        interactionEffects: const [],
        events: const [
          UnitMovedEvent(
            unitId: 'scout_1',
            fromCol: 1,
            fromRow: 1,
            toCol: 2,
            toRow: 1,
          ),
        ],
        movementExecutions: [
          _movementExecution(
            unitId: scout.id,
            fromCol: 1,
            fromRow: 1,
            steps: const [
              UnitMovementStep(col: 2, row: 1, enterCost: 0, cumulativeCost: 0),
            ],
          ),
        ],
        previousState: GameClientState(units: [scout]),
        state: GameClientState(units: [movedScout]),
      );

      final move = effects.whereType<AnimateUnitMoveEffect>().single;
      expect(move.unitId, scout.id);
      expect(move.fromCol, 1);
      expect(move.fromRow, 1);
      expect(move.steps.single.col, 2);
      expect(move.steps.single.row, 1);
    });

    test('projects merchant route from canonical execution facts', () {
      final merchant = _merchantWithTradeRoute(col: 0, row: 0);
      final movedMerchant = merchant.copyWith(col: 3, row: 0);

      final effects = ReplayRendererEffectPlanner.effectsForStep(
        interactionEffects: const [],
        events: const [
          UnitMovedEvent(
            unitId: 'merchant_1',
            fromCol: 0,
            fromRow: 0,
            toCol: 3,
            toRow: 0,
          ),
        ],
        movementExecutions: [
          _movementExecution(
            unitId: merchant.id,
            fromCol: 0,
            fromRow: 0,
            steps: const [
              UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
              UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
              UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
            ],
          ),
        ],
        previousState: GameClientState(units: [merchant]),
        state: GameClientState(units: [movedMerchant]),
      );

      final move = effects.whereType<AnimateUnitMoveEffect>().single;
      expect(move.unitId, merchant.id);
      expect(move.fromCol, 0);
      expect(move.fromRow, 0);
      expect(move.steps.map((step) => step.col), [1, 2, 3]);
    });

    test('projects one movement effect from fact plus matching event', () {
      final scout = _scout(col: 1, row: 1);
      final movedScout = scout.copyWith(col: 2, row: 1);
      final effects = ReplayRendererEffectPlanner.effectsForStep(
        interactionEffects: const [],
        events: const [
          UnitMovedEvent(
            unitId: 'scout_1',
            fromCol: 1,
            fromRow: 1,
            toCol: 2,
            toRow: 1,
          ),
        ],
        movementExecutions: [
          _movementExecution(
            unitId: scout.id,
            fromCol: 1,
            fromRow: 1,
            steps: const [
              UnitMovementStep(col: 2, row: 1, enterCost: 0, cumulativeCost: 0),
            ],
          ),
        ],
        previousState: GameClientState(units: [scout]),
        state: GameClientState(units: [movedScout]),
      );

      expect(effects.whereType<AnimateUnitMoveEffect>(), hasLength(1));
      expect(
        effects.whereType<AnimateUnitMoveEffect>().single.unitId,
        scout.id,
      );
    });

    test('treats selected player movement as visible in perspective', () {
      final scout = _scout(col: 1, row: 1);
      final movedScout = scout.copyWith(col: 2, row: 1);
      const effect = AnimateUnitMoveEffect(
        unitId: 'scout_1',
        fromCol: 1,
        fromRow: 1,
        steps: [
          UnitMovementStep(col: 2, row: 1, enterCost: 0, cumulativeCost: 0),
        ],
      );

      final visible = ReplayRendererEffectPlanner.hasPerspectiveVisibleMovement(
        effects: const [effect],
        previousState: GameClientState(
          activePlayerId: 'player_1',
          units: [scout],
          fogOfWar: _fogForPlayer('player_1', const {}),
        ),
        state: GameClientState(
          activePlayerId: 'player_1',
          units: [movedScout],
          fogOfWar: _fogForPlayer('player_1', const {}),
        ),
        perspectivePlayerId: 'player_1',
      );

      expect(visible, isTrue);
    });

    test('treats enemy movement in perspective fog as visible', () {
      final enemy = _scout(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        col: 4,
        row: 1,
      );
      final movedEnemy = enemy.copyWith(col: 5, row: 1);
      const effect = AnimateUnitMoveEffect(
        unitId: 'enemy_1',
        fromCol: 4,
        fromRow: 1,
        steps: [
          UnitMovementStep(col: 5, row: 1, enterCost: 0, cumulativeCost: 0),
        ],
      );

      final visible = ReplayRendererEffectPlanner.hasPerspectiveVisibleMovement(
        effects: const [effect],
        previousState: GameClientState(
          activePlayerId: 'player_1',
          units: [enemy],
          fogOfWar: _fogForPlayer('player_1', {
            const HexCoordinate(col: 4, row: 1),
          }),
        ),
        state: GameClientState(
          activePlayerId: 'player_1',
          units: [movedEnemy],
          fogOfWar: _fogForPlayer('player_1', {
            const HexCoordinate(col: 5, row: 1),
          }),
        ),
        perspectivePlayerId: 'player_1',
      );

      expect(visible, isTrue);
    });

    test('ignores enemy movement outside perspective fog', () {
      final enemy = _scout(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        col: 4,
        row: 1,
      );
      final movedEnemy = enemy.copyWith(col: 5, row: 1);
      const effect = AnimateUnitMoveEffect(
        unitId: 'enemy_1',
        fromCol: 4,
        fromRow: 1,
        steps: [
          UnitMovementStep(col: 5, row: 1, enterCost: 0, cumulativeCost: 0),
        ],
      );

      final visible = ReplayRendererEffectPlanner.hasPerspectiveVisibleMovement(
        effects: const [effect],
        previousState: GameClientState(
          activePlayerId: 'player_1',
          units: [enemy],
          fogOfWar: _fogForPlayer('player_1', const {}),
        ),
        state: GameClientState(
          activePlayerId: 'player_1',
          units: [movedEnemy],
          fogOfWar: _fogForPlayer('player_1', const {}),
        ),
        perspectivePlayerId: 'player_1',
      );

      expect(visible, isFalse);
    });
  });
}
