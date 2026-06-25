import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_camera_effect_normalizer.dart';
import 'package:aonw/game/presentation/services/game_map_focus_target_resolver.dart';
import 'package:aonw_core/game/domain/command.dart';

typedef TurnStartFocusMountedCheck = bool Function();
typedef TurnStartFocusStateReader = GameState? Function();
typedef TurnStartCommandDispatcher =
    Future<DispatchCommandResult> Function(GameCommand command);
typedef TurnStartRendererEffectHandler =
    Future<void> Function(RendererEffect effect);

final class TurnStartFocusCoordinator {
  const TurnStartFocusCoordinator({
    required this.isMounted,
    required this.readState,
    required this.dispatchWithPresentation,
    required this.dispatchWithoutRendererEffects,
    required this.handleRendererEffect,
  });

  final TurnStartFocusMountedCheck isMounted;
  final TurnStartFocusStateReader readState;
  final TurnStartCommandDispatcher dispatchWithPresentation;
  final TurnStartCommandDispatcher dispatchWithoutRendererEffects;
  final TurnStartRendererEffectHandler handleRendererEffect;

  Future<bool> focus({required String playerId, required bool moveCamera}) {
    if (!_canFocus(playerId)) return Future.value(false);
    return moveCamera
        ? _focusWithCamera(playerId)
        : _focusWithoutCamera(playerId);
  }

  bool _canFocus(String playerId) {
    return isMounted() && playerId.isNotEmpty;
  }

  Future<bool> _focusWithoutCamera(String playerId) async {
    final beforeState = readState();
    final result = await dispatchWithoutRendererEffects(
      FocusTurnStartActionCommand(playerId),
    );
    if (!isMounted()) return false;
    if (_stateChanged(result, beforeState)) return true;
    return _selectFallbackCityWithoutCamera(playerId);
  }

  Future<bool> _selectFallbackCityWithoutCamera(String playerId) async {
    final fallbackCity = _focusTargets.firstOwnedCity(playerId);
    if (fallbackCity != null) {
      await dispatchWithoutRendererEffects(SelectCityCommand(fallbackCity.id));
    }
    return true;
  }

  Future<bool> _focusWithCamera(String playerId) async {
    final beforeState = readState();
    final result = await dispatchWithPresentation(
      FocusTurnStartActionCommand(playerId),
    );
    if (!isMounted()) return false;
    if (_hasCommandCameraFocus(result)) return true;
    if (_shouldFocusPlayerStart(result, beforeState)) {
      await _focusPlayerStartCamera(playerId);
      return true;
    }
    return _selectFallbackCityWithCamera(playerId);
  }

  Future<bool> _selectFallbackCityWithCamera(String playerId) async {
    final fallbackCity = _focusTargets.firstOwnedCity(playerId);
    if (fallbackCity == null) return false;

    await dispatchWithPresentation(SelectCityCommand(fallbackCity.id));
    if (!isMounted()) return false;
    await _smoothFocus(GameMapFocusTarget.city(fallbackCity));
    return true;
  }

  bool _stateChanged(DispatchCommandResult result, GameState? beforeState) {
    return result.state != beforeState;
  }

  bool _hasCommandCameraFocus(DispatchCommandResult result) {
    return result.uiEffects.whereType<JumpCameraEffect>().isNotEmpty;
  }

  bool _shouldFocusPlayerStart(
    DispatchCommandResult result,
    GameState? beforeState,
  ) {
    return _stateChanged(result, beforeState) ||
        result.uiEffects.whereType<ShowCityProductionBubbleEffect>().isNotEmpty;
  }

  Future<bool> _focusPlayerStartCamera(String playerId) async {
    final target = _focusTargets.playerStartTarget(playerId);
    if (target == null) return false;
    await _smoothFocus(target);
    return true;
  }

  Future<void> _smoothFocus(GameMapFocusTarget target) {
    return handleRendererEffect(
      SmoothCameraEffect(
        col: target.col,
        row: target.row,
        duration: GameCameraEffectNormalizer.turnStartCameraTransitionDuration,
      ),
    );
  }

  GameMapFocusTargetResolver get _focusTargets {
    return GameMapFocusTargetResolver(readState());
  }
}
