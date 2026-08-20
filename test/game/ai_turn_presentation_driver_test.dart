import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/services/ai_turn_presentation_driver.dart';
import 'package:aonw/game/presentation/services/hidden_ai_renderer_playback.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_view_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnPresentationDriver', () {
    test('uses hidden presentation for hot-seat AI commands', () async {
      final applied = <_AppliedTransition>[];
      final hiddenCommands = <DomainCommand>[];
      final beforeUnit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'ai_1',
        type: GameUnitType.warrior,
        col: 2,
        row: 3,
      );
      final driver = _driver(
        session: _session(gameMode: GameMode.hotSeat),
        rendererState: GameClientState(
          activePlayerId: 'human',
          activePlayerCanAct: false,
          units: [beforeUnit],
        ),
        applyProjectedTransition: (state, batch) async {
          applied.add(_AppliedTransition(state, batch.effects));
        },
        hiddenDispatch:
            ({required saveId, required command, required context}) async {
              hiddenCommands.add(command);
              return DispatchCommandResult(
                state: GameClientState(
                  activePlayerId: 'ai_1',
                  activePlayerCanAct: false,
                  units: [beforeUnit.copyWith(col: 3)],
                ),
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
                    steps: _commandMoveSteps,
                  ),
                ],
              );
            },
      );

      final result = await driver.dispatchCommand(
        saveId: 'save_1',
        currentState: GameClientState(
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
      final move = applied.single.effects.single as AnimateUnitMoveEffect;
      expect(move.unitId, _commandMove.unitId);
      expect(move.fromCol, _commandMove.fromCol);
      expect(move.fromRow, _commandMove.fromRow);
      expect(move.steps, _commandMove.steps);
    });

    test('uses hidden presentation for multiplayer AI commands', () async {
      final hiddenCommands = <DomainCommand>[];
      final driver = _driver(
        session: _session(gameMode: GameMode.multiplayer),
        hiddenDispatch:
            ({required saveId, required command, required context}) async {
              hiddenCommands.add(command);
              return DispatchCommandResult(
                state: GameClientState(activePlayerId: 'ai_1'),
              );
            },
      );

      final result = await driver.dispatchCommand(
        saveId: 'save_1',
        currentState: GameClientState(
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

        final currentState = GameClientState(activePlayerId: 'ai_1');
        final result = await driver.dispatchCommand(
          saveId: 'save_1',
          currentState: currentState,
          command: const SkipUnitTurnCommand('warrior_1'),
          context: const GameCommandContext(actorPlayerId: 'ai_1'),
        );

        expect(result.state, currentState);
      },
    );

    test(
      'skips renderer playback when its owner unmounts during dispatch',
      () async {
        var canContinue = true;
        var localizationRead = false;
        var transitionApplied = false;
        final driver = _driver(
          session: _session(),
          canContinue: () => canContinue,
          localizationReader: () {
            localizationRead = true;
            return null;
          },
          applyProjectedTransition: (state, batch) async {
            transitionApplied = true;
          },
          hiddenDispatch:
              ({required saveId, required command, required context}) async {
                canContinue = false;
                return DispatchCommandResult(
                  state: GameClientState(activePlayerId: 'human'),
                  offset: 7,
                );
              },
        );

        final result = await driver.dispatchCommand(
          saveId: 'save_1',
          currentState: GameClientState(
            activePlayerId: 'ai_1',
            activePlayerCanAct: true,
          ),
          command: const EndTurnCommand('ai_1'),
          context: const GameCommandContext(actorPlayerId: 'ai_1'),
        );

        expect(result.state.activePlayerId, 'ai_1');
        expect(result.state.activePlayerCanAct, isTrue);
        expect(localizationRead, isFalse);
        expect(transitionApplied, isFalse);
      },
    );

    test('plays smoothed hidden turn-advance effects', () async {
      final applied = <_AppliedTransition>[];
      final driver = _driver(
        session: _session(),
        rendererState: GameClientState(activePlayerId: 'human'),
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

const _defaultRendererState = Object();

AiTurnPresentationDriver _driver({
  required GameSession? session,
  Object? rendererState = _defaultRendererState,
  AiTurnTransitionApplier? applyTransition,
  HiddenAiProjectedTransitionApplier? applyProjectedTransition,
  AiTurnHiddenCommandDispatcher? hiddenDispatch,
  HiddenAiLocalizationReader? localizationReader,
  AiTurnPresentationGuard? canContinue,
}) {
  return AiTurnPresentationDriver(
    sessionReader: () => session,
    stateReader: (_) => identical(rendererState, _defaultRendererState)
        ? GameClientState(activePlayerId: 'human')
        : rendererState as GameClientState?,
    localizationReader: localizationReader ?? () => null,
    applyTransition:
        applyTransition ??
        (state, effects) async {
          fail('unexpected renderer transition');
        },
    applyProjectedTransition:
        applyProjectedTransition ??
        (state, batch) async {
          fail('unexpected projected renderer transition');
        },
    hiddenDispatch:
        hiddenDispatch ??
        ({required saveId, required command, required context}) async {
          return DispatchCommandResult(state: GameClientState());
        },
    canContinue: canContinue ?? () => true,
  );
}

GameSession _session({
  String saveId = 'save_1',
  GameMode gameMode = GameMode.hotSeat,
}) {
  return GameSession(
    mapData: WorldMap(cols: 1, rows: 1, tiles: []),
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
const _commandMoveSteps = [
  UnitMovementStep(col: 3, row: 3, enterCost: 1, cumulativeCost: 1),
];

final class _AppliedTransition {
  final GameClientState state;
  final List<RendererEffect> effects;

  const _AppliedTransition(this.state, this.effects);
}
