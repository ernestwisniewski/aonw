part of 'game_renderer.dart';

extension _GameRendererCameraPolicy on GameRenderer {
  bool _transitionControlsCamera(Iterable<RendererEffect> effects) {
    for (final effect in effects) {
      if (effect is AnimateUnitMoveEffect) {
        if (_moveCameraForUnitMovementEffect(effect.unitId)) return true;
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

  bool _moveCameraForUnitMovementEffect(String unitId) {
    if (!_moveCameraForUnitMovement) return false;
    final unit = _unitById(unitId);
    if (unit == null) return false;
    if (!_isEnemyUnit(unit)) return true;
    return _followEnemyUnitCamera;
  }

  Future<void> _restoreCameraAfterUnitMovementEffect(String unitId) async {
    if (!_followEnemyUnitCamera) return;
    final unit = _unitById(unitId);
    if (unit == null || !_isEnemyUnit(unit)) return;
    _focusSelection(_renderState.selection);
  }

  bool _isEnemyUnit(GameUnit unit) {
    return unit.ownerPlayerId != _renderState.activePlayerId;
  }
}
