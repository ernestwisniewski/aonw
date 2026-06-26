import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_camera_effect_normalizer.dart';
import 'package:aonw/game/presentation/services/turn_start_focus_coordinator.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ignores empty player ids before dispatching', () async {
    final commands = <GameCommand>[];
    final effects = <RendererEffect>[];
    final coordinator = _coordinator(
      state: const GameState(),
      commands: commands,
      effects: effects,
    );

    final focused = await coordinator.focus(playerId: '', moveCamera: true);

    expect(focused, isFalse);
    expect(commands, isEmpty);
    expect(effects, isEmpty);
  });

  test(
    'selects a fallback city when focus without camera changes nothing',
    () async {
      final commands = <GameCommand>[];
      final effects = <RendererEffect>[];
      const state = GameState(cities: [_city]);
      final coordinator = _coordinator(
        state: state,
        commands: commands,
        effects: effects,
        dispatchWithoutRendererEffects: (command) async {
          commands.add(command);
          return const DispatchCommandResult(state: state);
        },
      );

      final focused = await coordinator.focus(
        playerId: _playerId,
        moveCamera: false,
      );

      expect(focused, isTrue);
      expect(commands, [
        const FocusTurnStartActionCommand(_playerId),
        const SelectCityCommand(_cityId),
      ]);
      expect(effects, isEmpty);
    },
  );

  test('accepts camera focus produced by the turn-start command', () async {
    final commands = <GameCommand>[];
    final effects = <RendererEffect>[];
    const state = GameState(cities: [_city]);
    final coordinator = _coordinator(
      state: state,
      commands: commands,
      effects: effects,
      dispatchWithPresentation: (command) async {
        commands.add(command);
        return const DispatchCommandResult(
          state: state,
          uiEffects: [JumpCameraEffect(col: 3, row: 4)],
        );
      },
    );

    final focused = await coordinator.focus(
      playerId: _playerId,
      moveCamera: true,
    );

    expect(focused, isTrue);
    expect(commands, [const FocusTurnStartActionCommand(_playerId)]);
    expect(effects, isEmpty);
  });

  test(
    'focuses a fallback city when turn-start command has no target',
    () async {
      final commands = <GameCommand>[];
      final effects = <RendererEffect>[];
      const state = GameState(cities: [_city]);
      final coordinator = _coordinator(
        state: state,
        commands: commands,
        effects: effects,
        dispatchWithPresentation: (command) async {
          commands.add(command);
          return const DispatchCommandResult(state: state);
        },
      );

      final focused = await coordinator.focus(
        playerId: _playerId,
        moveCamera: true,
      );

      expect(focused, isTrue);
      expect(commands, [
        const FocusTurnStartActionCommand(_playerId),
        const SelectCityCommand(_cityId),
      ]);
      expect(effects.single, isA<SmoothCameraEffect>());
      final effect = effects.single as SmoothCameraEffect;
      expect(effect.col, 7);
      expect(effect.row, 8);
      expect(
        effect.duration,
        GameCameraEffectNormalizer.turnStartCameraTransitionDuration,
      );
    },
  );
}

const _playerId = 'player_1';
const _cityId = 'city_1';
const _city = GameCity(
  id: _cityId,
  ownerPlayerId: _playerId,
  name: 'Capital',
  center: CityHex(col: 7, row: 8),
);

TurnStartFocusCoordinator _coordinator({
  required GameState state,
  required List<GameCommand> commands,
  required List<RendererEffect> effects,
  TurnStartCommandDispatcher? dispatchWithPresentation,
  TurnStartCommandDispatcher? dispatchWithoutRendererEffects,
}) {
  Future<DispatchCommandResult> defaultDispatch(GameCommand command) async {
    commands.add(command);
    return DispatchCommandResult(state: state);
  }

  return TurnStartFocusCoordinator(
    isMounted: () => true,
    readState: () => state,
    dispatchWithPresentation: dispatchWithPresentation ?? defaultDispatch,
    dispatchWithoutRendererEffects:
        dispatchWithoutRendererEffects ?? defaultDispatch,
    handleRendererEffect: (effect) async => effects.add(effect),
  );
}
