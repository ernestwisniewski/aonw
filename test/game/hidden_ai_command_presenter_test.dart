import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/services/hidden_ai_command_presenter.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HiddenAiCommandPresenter', () {
    test(
      'presents hidden AI command without switching renderer perspective',
      () async {
        final applied = <_AppliedTransition>[];
        const currentAiState = GameState(
          activePlayerId: 'ai_1',
          activePlayerCanAct: true,
        );
        final beforeUnit = GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'ai_1',
          type: GameUnitType.warrior,
          col: 2,
          row: 3,
        );
        final afterUnit = beforeUnit.copyWith(col: 3);
        final humanRendererState = GameState(
          activePlayerId: 'human',
          activePlayerCanAct: false,
          units: [beforeUnit],
        );
        final reducerState = GameState(
          activePlayerId: 'ai_1',
          activePlayerCanAct: false,
          units: [afterUnit],
        );
        const commandMove = AnimateUnitMoveEffect(
          unitId: 'warrior_1',
          fromCol: 2,
          fromRow: 3,
          steps: [
            UnitMovementStep(col: 3, row: 3, enterCost: 1, cumulativeCost: 1),
          ],
        );
        final presenter = HiddenAiCommandPresenter(
          rendererStateReader: () => humanRendererState,
          localizationReader: () => null,
          applyTransition: (state, effects) async {
            applied.add(_AppliedTransition(state, effects));
          },
          dispatchTransition: (command, {required context}) async {
            expect(command, const MoveUnitCommand('warrior_1', 3, 3));
            expect(context.actorPlayerId, 'ai_1');
            return DispatchCommandResult(
              state: reducerState,
              events: const [
                UnitMovedEvent(
                  unitId: 'warrior_1',
                  fromCol: 2,
                  fromRow: 3,
                  toCol: 3,
                  toRow: 3,
                ),
              ],
              movementExecutions: [
                MovementCommandExecution(
                  unitId: 'warrior_1',
                  fromCol: 2,
                  fromRow: 3,
                  steps: commandMove.steps,
                ),
              ],
            );
          },
        );

        final result = await presenter.dispatchAndPresent(
          currentState: currentAiState,
          command: const MoveUnitCommand('warrior_1', 3, 3),
          context: const GameCommandContext(actorPlayerId: 'ai_1'),
        );

        expect(result.state.activePlayerId, 'ai_1');
        expect(result.state.activePlayerCanAct, isTrue);
        expect(applied, hasLength(1));
        expect(applied.single.state.activePlayerId, 'human');
        expect(applied.single.state.activePlayerCanAct, isFalse);
        final move = applied.single.effects.single as AnimateUnitMoveEffect;
        expect(move.unitId, commandMove.unitId);
        expect(move.fromCol, commandMove.fromCol);
        expect(move.fromRow, commandMove.fromRow);
        expect(move.steps, commandMove.steps);
      },
    );

    test('uses current AI state when renderer has no prior state', () async {
      final applied = <_AppliedTransition>[];
      const currentAiState = GameState(
        activePlayerId: 'ai_1',
        activePlayerCanAct: true,
      );
      const reducerState = GameState(activePlayerId: 'ai_1');
      final presenter = HiddenAiCommandPresenter(
        rendererStateReader: () => null,
        localizationReader: () => null,
        applyTransition: (state, effects) async {
          applied.add(_AppliedTransition(state, effects));
        },
        dispatchTransition: (command, {required context}) async {
          return const DispatchCommandResult(
            state: reducerState,
            uiEffects: [JumpCameraEffect(col: 1, row: 2)],
          );
        },
      );

      await presenter.dispatchAndPresent(
        currentState: currentAiState,
        command: const SelectTileCommand(1, 2),
        context: const GameCommandContext(actorPlayerId: 'ai_1'),
      );

      expect(applied.single.state.activePlayerId, 'ai_1');
      expect(applied.single.state.activePlayerCanAct, isTrue);
    });

    test('does not apply renderer effects for terminal commands', () async {
      var applied = false;
      final presenter = HiddenAiCommandPresenter(
        rendererStateReader: () => const GameState(activePlayerId: 'human'),
        localizationReader: () => null,
        applyTransition: (state, effects) async {
          applied = true;
        },
        dispatchTransition: (command, {required context}) async {
          return const DispatchCommandResult(
            state: GameState(activePlayerId: 'ai_1'),
            uiEffects: [
              ShowFloatingTextEffect(
                text: 'done',
                col: 0,
                row: 0,
                colorValue: 0xFFFFFFFF,
              ),
            ],
            events: [
              UnitMovedEvent(
                unitId: 'warrior_1',
                fromCol: 1,
                fromRow: 1,
                toCol: 2,
                toRow: 1,
              ),
            ],
          );
        },
      );

      final result = await presenter.dispatchAndPresent(
        currentState: const GameState(
          activePlayerId: 'ai_1',
          activePlayerCanAct: true,
        ),
        command: const EndTurnCommand('ai_1'),
        context: const GameCommandContext(actorPlayerId: 'ai_1'),
      );

      expect(applied, isFalse);
      expect(result.state.activePlayerId, 'ai_1');
      expect(result.state.activePlayerCanAct, isTrue);
    });

    test(
      'presents canonical movement evidence from terminal commands',
      () async {
        final applied = <_AppliedTransition>[];
        final beforeUnit = GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'ai_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        );
        final presenter = HiddenAiCommandPresenter(
          rendererStateReader: () =>
              GameState(activePlayerId: 'human', units: [beforeUnit]),
          localizationReader: () => null,
          applyTransition: (state, effects) async {
            applied.add(_AppliedTransition(state, effects));
          },
          dispatchTransition: (command, {required context}) async {
            return DispatchCommandResult(
              state: GameState(
                activePlayerId: 'ai_1',
                units: [beforeUnit.copyWith(col: 2)],
              ),
              events: const [
                UnitMovedEvent(
                  unitId: 'warrior_1',
                  fromCol: 1,
                  fromRow: 1,
                  toCol: 2,
                  toRow: 1,
                ),
              ],
              movementExecutions: [
                MovementCommandExecution(
                  unitId: 'warrior_1',
                  fromCol: 1,
                  fromRow: 1,
                  steps: [
                    const UnitMovementStep(
                      col: 2,
                      row: 1,
                      enterCost: 1,
                      cumulativeCost: 1,
                    ),
                  ],
                ),
              ],
            );
          },
        );

        await presenter.dispatchAndPresent(
          currentState: const GameState(activePlayerId: 'ai_1'),
          command: const EndTurnCommand('ai_1'),
          context: const GameCommandContext(actorPlayerId: 'ai_1'),
        );

        expect(applied, hasLength(1));
        final move = applied.single.effects.single as AnimateUnitMoveEffect;
        expect(move.unitId, 'warrior_1');
        expect(
          move.steps.single,
          const UnitMovementStep(
            col: 2,
            row: 1,
            enterCost: 1,
            cumulativeCost: 1,
          ),
        );
      },
    );
  });
}

final class _AppliedTransition {
  final GameState state;
  final List<RendererEffect> effects;

  const _AppliedTransition(this.state, this.effects);
}
