import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/game_renderer_camera_settings.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class GameRendererCameraPolicy {
  const GameRendererCameraPolicy({
    required this.settings,
    required this.state,
    required this.isDisposed,
    required this.focusActiveSelection,
  });

  final GameRendererCameraSettings settings;
  final GameClientState Function() state;
  final bool Function() isDisposed;
  final void Function() focusActiveSelection;

  bool transitionControlsCamera(Iterable<RendererEffect> effects) {
    for (final effect in effects) {
      if (effect is AnimateUnitMoveEffect) {
        if (_unitMovementControlsCamera(effect.unitId)) return true;
        continue;
      }
      if (effect is PlayCombatAnimationEffect ||
          effect is JumpCameraEffect ||
          effect is SmoothCameraEffect) {
        return true;
      }
    }
    return false;
  }

  bool _unitMovementControlsCamera(String unitId) {
    if (!settings.moveCameraForUnitMovement) return false;
    return focusCameraForUnit(unitId) || followCameraForUnit(unitId);
  }

  bool focusCameraForUnit(String unitId) {
    final unit = state().unitById(unitId);
    if (unit == null) return false;
    return _isEnemyUnit(unit)
        ? settings.focusEnemyUnitMovementCamera
        : settings.focusOwnUnitMovementCamera;
  }

  bool followCameraForUnit(String unitId) {
    final unit = state().unitById(unitId);
    if (unit == null) return false;
    return _isEnemyUnit(unit)
        ? settings.followEnemyUnitMovementCamera
        : settings.followOwnUnitMovementCamera;
  }

  Future<void> restoreAfterUnitMovement(String unitId) async {
    if (isDisposed()) return;
    final unit = state().unitById(unitId);
    if (unit == null || !_isEnemyUnit(unit)) return;
    if (!settings.focusEnemyUnitMovementCamera &&
        !settings.followEnemyUnitMovementCamera) {
      return;
    }
    focusActiveSelection();
  }

  bool _isEnemyUnit(GameUnit unit) {
    return unit.ownerPlayerId != state().activePlayerId;
  }
}
