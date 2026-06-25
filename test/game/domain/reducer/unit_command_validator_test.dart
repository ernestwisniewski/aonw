import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/game/domain/reducer/unit_command_validator.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitCommandValidator', () {
    test('accepts a controllable unit', () {
      final unit = GameUnit.startingWarrior(ownerPlayerId: 'player_1');
      final state = GameState(activePlayerId: 'player_1', units: [unit]);

      final result = UnitCommandValidator.controllableUnit(
        state,
        unitId: unit.id,
        context: const GameCommandContext(),
      );

      expect(result, isA<ValidUnit>().having((it) => it.unit, 'unit', unit));
    });

    test('rejects a unit controlled by another player', () {
      final unit = GameUnit.startingWarrior(ownerPlayerId: 'player_2');
      final state = GameState(activePlayerId: 'player_1', units: [unit]);

      final result = UnitCommandValidator.controllableUnit(
        state,
        unitId: unit.id,
        context: const GameCommandContext(),
      );

      expect(
        result,
        isA<InvalidUnit>().having(
          (it) => it.reason,
          'reason',
          UnitCommandValidationFailureReason.notControllable,
        ),
      );
    });

    test('rejects working or fortified units for movement', () {
      final working =
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ).copyWithWorkerJob(
            const WorkerJob(
              targetHex: CityHex(col: 0, row: 0),
              improvementType: FieldImprovementType.farm,
              remainingTurns: 1,
              totalTurns: 1,
            ),
          );
      final fortified = GameUnit.startingWarrior(
        ownerPlayerId: 'player_1',
      ).copyWithPosture(UnitPosture.fortified);
      final state = GameState(
        activePlayerId: 'player_1',
        units: [working, fortified],
      );

      expect(
        UnitCommandValidator.movableUnit(
          state,
          unitId: working.id,
          context: const GameCommandContext(),
        ),
        isA<InvalidUnit>().having(
          (it) => it.reason,
          'reason',
          UnitCommandValidationFailureReason.working,
        ),
      );
      expect(
        UnitCommandValidator.movableUnit(
          state,
          unitId: fortified.id,
          context: const GameCommandContext(),
        ),
        isA<InvalidUnit>().having(
          (it) => it.reason,
          'reason',
          UnitCommandValidationFailureReason.fortified,
        ),
      );
    });

    test('accepts only scouts that can start auto-explore', () {
      final scout = GameUnit.produced(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 0,
        row: 0,
      );
      final queuedScout =
          GameUnit.produced(
            id: 'scout_2',
            ownerPlayerId: 'player_1',
            type: GameUnitType.scout,
            col: 0,
            row: 0,
          ).copyWithQueuedPath(
            QueuedMovePath(
              targetCol: 1,
              targetRow: 0,
              steps: const [
                UnitMovementStep(
                  col: 0,
                  row: 0,
                  enterCost: 0,
                  cumulativeCost: 0,
                ),
              ],
            ),
          );
      final warrior = GameUnit.startingWarrior(ownerPlayerId: 'player_1');
      final state = GameState(
        activePlayerId: 'player_1',
        units: [scout, queuedScout, warrior],
      );

      expect(
        UnitCommandValidator.autoExplorableScout(
          state,
          unitId: scout.id,
          context: const GameCommandContext(),
        ),
        isA<ValidUnit>(),
      );
      expect(
        UnitCommandValidator.autoExplorableScout(
          state,
          unitId: queuedScout.id,
          context: const GameCommandContext(),
        ),
        isA<InvalidUnit>().having(
          (it) => it.reason,
          'reason',
          UnitCommandValidationFailureReason.queuedPath,
        ),
      );
      expect(
        UnitCommandValidator.autoExplorableScout(
          state,
          unitId: warrior.id,
          context: const GameCommandContext(),
        ),
        isA<InvalidUnit>().having(
          (it) => it.reason,
          'reason',
          UnitCommandValidationFailureReason.unsupportedUnitType,
        ),
      );
    });
  });
}
