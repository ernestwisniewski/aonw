import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/services/ai_turn_presentation_driver.dart';
import 'package:aonw/game/presentation/services/hidden_ai_renderer_playback.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnPresentationDriver', () {
    test('uses hidden presentation for hot-seat AI commands', () async {
      final applied = <_AppliedTransition>[];
      final hiddenCommands = <GameCommand>[];
      final driver = _driver(
        session: _session(gameMode: GameMode.hotSeat),
        rendererState: const GameState(
          activePlayerId: 'human',
          activePlayerCanAct: false,
        ),
        applyTransition: (state, effects) async {
          applied.add(_AppliedTransition(state, effects));
        },
        hiddenDispatch:
            ({required saveId, required command, required context}) async {
              hiddenCommands.add(command);
              return const DispatchCommandResult(
                state: GameState(
                  activePlayerId: 'ai_1',
                  activePlayerCanAct: false,
                ),
                uiEffects: [_commandMove],
              );
            },
      );

      final result = await driver.dispatchCommand(
        saveId: 'save_1',
        currentState: const GameState(
          activePlayerId: 'ai_1',
          activePlayerCanAct: true,
        ),
        command: const MoveUnitCommand('warrior_1', 3, 3),
        context: const GameCommandContext(actorPlayerId: 'ai_1'),
      );

      expect(hiddenCommands, const [MoveUnitCommand('warrior_1', 3, 3)]);
      expect(result.state.activePlayerId, 'ai_1');
      expect(result.state.activePlayerCanAct, isTrue);
      expect(applied, hasLength(1));
      expect(applied.single.state.activePlayerId, 'human');
      expect(applied.single.effects, const [_commandMove]);
    });

    test('uses hidden presentation for multiplayer AI commands', () async {
      final hiddenCommands = <GameCommand>[];
      final driver = _driver(
        session: _session(gameMode: GameMode.multiplayer),
        hiddenDispatch:
            ({required saveId, required command, required context}) async {
              hiddenCommands.add(command);
              return const DispatchCommandResult(
                state: GameState(activePlayerId: 'ai_1'),
              );
            },
      );

      final result = await driver.dispatchCommand(
        saveId: 'save_1',
        currentState: const GameState(
          activePlayerId: 'ai_1',
          activePlayerCanAct: true,
        ),
        command: const SkipUnitTurnCommand('warrior_1'),
        context: const GameCommandContext(actorPlayerId: 'ai_1'),
      );

      expect(hiddenCommands, const [SkipUnitTurnCommand('warrior_1')]);
      expect(result.state.activePlayerId, 'ai_1');
    });

    test(
      'returns current state when active session does not match save',
      () async {
        final driver = _driver(
          session: _session(saveId: 'other_save'),
          hiddenDispatch:
              ({required saveId, required command, required context}) async {
                fail('stale sessions should not dispatch hidden commands');
              },
        );

        const currentState = GameState(activePlayerId: 'ai_1');
        final result = await driver.dispatchCommand(
          saveId: 'save_1',
          currentState: currentState,
          command: const SkipUnitTurnCommand('warrior_1'),
          context: const GameCommandContext(actorPlayerId: 'ai_1'),
        );

        expect(result.state, currentState);
      },
    );

    test('plays smoothed hidden turn-advance effects', () async {
      final applied = <_AppliedTransition>[];
      final driver = _driver(
        session: _session(),
        rendererState: const GameState(activePlayerId: 'human'),
        applyTransition: (state, effects) async {
          applied.add(_AppliedTransition(state, effects));
        },
      );

      final count = await driver.playTurnAdvanceEffects(
        saveId: 'save_1',
        terminalUiEffects: const [JumpCameraEffect(col: 2, row: 3)],
      );

      expect(count, 1);
      expect(applied, hasLength(1));
      final camera = applied.single.effects.single as SmoothCameraEffect;
      expect(camera.col, 2);
      expect(camera.row, 3);
    });

    test(
      'skips turn-advance playback without state or renderer effects',
      () async {
        var applied = false;
        final driver = _driver(
          session: _session(),
          rendererState: null,
          applyTransition: (state, effects) async {
            applied = true;
          },
        );

        final noEffects = await driver.playTurnAdvanceEffects(
          saveId: 'save_1',
          terminalUiEffects: const [
            ShowFloatingTextEffect(
              text: 'turn',
              col: 1,
              row: 1,
              colorValue: 0xFFFFFFFF,
            ),
          ],
        );
        final noState = await driver.playTurnAdvanceEffects(
          saveId: 'save_1',
          terminalUiEffects: const [JumpCameraEffect(col: 2, row: 3)],
        );

        expect(noEffects, 0);
        expect(noState, 0);
        expect(applied, isFalse);
      },
    );
  });
}

AiTurnPresentationDriver _driver({
  required GameSession? session,
  GameState? rendererState = const GameState(activePlayerId: 'human'),
  HiddenAiTransitionApplier? applyTransition,
  AiTurnHiddenCommandDispatcher? hiddenDispatch,
}) {
  return AiTurnPresentationDriver(
    sessionReader: () => session,
    stateReader: (_) => rendererState,
    localizationReader: () => null,
    applyTransition:
        applyTransition ??
        (state, effects) async {
          fail('unexpected renderer transition');
        },
    hiddenDispatch:
        hiddenDispatch ??
        ({required saveId, required command, required context}) async {
          return const DispatchCommandResult(state: GameState());
        },
  );
}

GameSession _session({
  String saveId = 'save_1',
  GameMode gameMode = GameMode.hotSeat,
}) {
  return GameSession(
    mapData: MapData(cols: 1, rows: 1, tiles: const []),
    viewMode: MapViewMode.tile,
    saveId: saveId,
    gameMode: gameMode,
  );
}

const _commandMove = AnimateUnitMoveEffect(
  unitId: 'warrior_1',
  fromCol: 2,
  fromRow: 3,
  steps: [UnitMovementStep(col: 3, row: 3, enterCost: 1, cumulativeCost: 1)],
);

final class _AppliedTransition {
  final GameState state;
  final List<RendererEffect> effects;

  const _AppliedTransition(this.state, this.effects);
}
