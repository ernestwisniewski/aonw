part of 'replay_screen.dart';

extension _ReplayRendererHostControls on _ReplayRendererHostState {
  void _setFreeCamera(bool value) {
    if (_freeCamera == value) return;
    ref
        .read(gameplaySettingsProvider.notifier)
        .setFollowUnitMovementCamera(!value);
    _syncReplayCameraMode(freeCamera: value);
    if (value) {
      _renderer?.stopFollowingCameraTarget();
    } else {
      _syncPerspectiveCamera(immediate: false, freeCamera: value);
    }
  }

  bool get _freeCamera => !widget.followUnitMovementCamera;

  void _syncReplayCameraMode({GameRenderer? renderer, bool? freeCamera}) {
    final target = renderer ?? _renderer;
    if (target == null) return;
    final followMovement = !(freeCamera ?? _freeCamera);
    target
      ..moveCameraForUnitMovement = followMovement
      ..followUnitMovementCamera = followMovement;
  }

  bool _consumePendingPerspectiveCameraFocus() {
    final pending = _pendingPerspectiveCameraFocus;
    _pendingPerspectiveCameraFocus = false;
    return pending;
  }

  void _syncPerspectiveCamera({required bool immediate, bool? freeCamera}) {
    if (freeCamera ?? _freeCamera) {
      _renderer?.stopFollowingCameraTarget();
      return;
    }
    final playerId = _perspectivePlayerId;
    if (playerId == null || playerId.isEmpty) {
      _renderer?.stopFollowingCameraTarget();
      return;
    }
    _renderer?.followPlayerCamera(playerId, immediate: immediate);
  }

  void _schedulePlayback() {
    _playbackTimer?.cancel();
    if (!_playing) return;
    _playbackTimer = Timer(_playbackDelay(), () {
      if (!mounted || !_playing) return;
      unawaited(_advancePlayback());
    });
  }

  Duration _playbackDelay() {
    return _playbackPolicy.delayBeforeStep(_nextPlaybackStep);
  }

  ReplayStep? get _nextPlaybackStep {
    if (_stepIndex >= widget.timeline.steps.length) return null;
    return widget.timeline.steps[_stepIndex];
  }

  bool _shouldFastForwardStep(
    ReplayStep step,
    Iterable<RendererEffect> effects,
    GameState state,
    GameState previousState,
  ) {
    if (!_playbackPolicy.shouldFastForwardStep(step)) return false;
    return !ReplayRendererEffectPlanner.hasPerspectiveVisibleEffect(
      effects: effects,
      state: state,
      previousState: previousState,
      perspectivePlayerId: _perspectivePlayerId,
    );
  }

  ReplayPlaybackPolicy get _playbackPolicy => ReplayPlaybackPolicy(
    perspectivePlayerId: _perspectivePlayerId,
    speed: _speed,
  );
}
