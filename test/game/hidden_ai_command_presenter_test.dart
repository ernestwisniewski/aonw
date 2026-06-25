import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/services/hidden_ai_command_presenter.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
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
        const humanRendererState = GameState(
          activePlayerId: 'human',
          activePlayerCanAct: false,
        );
        const reducerState = GameState(
          activePlayerId: 'ai_1',
          activePlayerCanAct: false,
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
            return const DispatchCommandResult(
              state: reducerState,
              uiEffects: [commandMove],
              events: [
                UnitMovedEvent(
                  unitId: 'warrior_1',
                  fromCol: 2,
                  fromRow: 3,
                  toCol: 3,
                  toRow: 3,
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
        expect(applied.single.effects, const [commandMove]);
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
            uiEffects: [
              ShowFloatingTextEffect(
                text: 'AI',
                col: 1,
                row: 2,
                colorValue: 0xFFFFFFFF,
              ),
            ],
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
  });
}

final class _AppliedTransition {
  final GameState state;
  final List<RendererEffect> effects;

  const _AppliedTransition(this.state, this.effects);
}
