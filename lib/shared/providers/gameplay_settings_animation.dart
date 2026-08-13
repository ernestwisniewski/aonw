part of 'gameplay_settings_provider.dart';

extension GameplayAnimationSettingsController on GameplaySettingsController {
  void setShowAnimations(bool enabled) {
    if (!_updateAnimationState(showAnimations: enabled)) return;
    _pendingShowAnimations = enabled;
    unawaited(
      _saveBool(
        _showAnimationsKey,
        enabled,
        onSaved: () {
          if (_pendingShowAnimations == enabled) {
            _pendingShowAnimations = null;
          }
        },
      ),
    );
  }

  void setAnimateCameraTransitions(bool enabled) {
    if (!_updateAnimationState(cameraTransitions: enabled)) return;
    _pendingAnimateCameraTransitions = enabled;
    unawaited(
      _saveBool(
        _animateCameraTransitionsKey,
        enabled,
        onSaved: () {
          if (_pendingAnimateCameraTransitions == enabled) {
            _pendingAnimateCameraTransitions = null;
          }
        },
      ),
    );
  }
}
