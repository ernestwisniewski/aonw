part of 'replay_screen.dart';

extension _ReplayRendererHostLifecycle on _ReplayRendererHostState {
  GameRenderer _createRenderer() {
    final session = widget.session;
    return GameRenderer(
      mapData: session.mapData,
      imagePath: session.imagePath,
      // Replay renders from the immutable seed snapshot, not the latest save.
      initialCamera: widget.timeline.initialSnapshot.save.camera,
      initialViewMode: session.viewMode,
      focusActivePlayerOnFirstState: true,
      onCommand: (GameCommand _) async {},
      onLoadingProgress: _reportRendererLoadProgress,
      l10n: widget.l10n,
      displaySettings: widget.displaySettings,
      reduceMotion: _reduceMotion,
      moveCameraForUnitMovement: widget.followUnitMovementCamera,
      followUnitMovementCamera: widget.followUnitMovementCamera,
      cinematicCameraEnabled: widget.cinematicCameraEnabled,
    );
  }

  void _attachRendererListeners(GameRenderer renderer) {
    renderer.readyListenable.addListener(_applyCurrentStepWhenRendererReady);
    renderer.initialCameraFocusReadyListenable.addListener(
      _syncAllPlayersAfterInitialFocus,
    );
  }

  void _detachRendererListeners(GameRenderer renderer) {
    renderer.readyListenable.removeListener(_applyCurrentStepWhenRendererReady);
    renderer.initialCameraFocusReadyListenable.removeListener(
      _syncAllPlayersAfterInitialFocus,
    );
  }

  void _applyCurrentStepWhenRendererReady() {
    final renderer = _renderer;
    if (renderer == null || !renderer.readyListenable.value || !mounted) {
      return;
    }
    unawaited(_applyStep(animated: false));
  }

  bool _shouldRecreateRenderer(_ReplayRendererHost oldWidget) {
    final oldSession = oldWidget.session;
    final session = widget.session;
    return oldSession.saveId != session.saveId ||
        oldSession.mapData != session.mapData ||
        oldSession.imagePath != session.imagePath ||
        oldWidget.timeline.initialSnapshot.save.camera !=
            widget.timeline.initialSnapshot.save.camera ||
        oldWidget.l10n.localeName != widget.l10n.localeName;
  }

  void _releaseRendererAfterFrame(GameRenderer renderer) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!identical(_renderer, renderer)) {
        renderer.disposeRenderer();
      }
    });
  }

  void _reportRendererLoadProgress(double value) {
    _loadingProgressController.value = GameLoadingProgress.initial.bumpedTo(
      0.42 + value.clamp(0.0, 1.0) * 0.54,
    );
  }

  Future<void> _applyStep({required bool animated}) async {
    if (_applying) {
      _pendingApply = true;
      _pendingApplyAnimated = _pendingApplyAnimated || animated;
      return;
    }
    _applying = true;
    try {
      var animateNext = animated;
      while (mounted) {
        _pendingApply = false;
        _pendingApplyAnimated = false;
        await _applyStepNow(animated: animateNext);
        if (!_pendingApply) break;
        animateNext = _pendingApplyAnimated;
      }
    } finally {
      _applying = false;
    }
  }

  Future<void> _applyStepNow({required bool animated}) async {
    final targetIndex = _stepIndex;
    final renderer = _renderer;
    if (renderer == null || !renderer.readyListenable.value) return;
    final previousAppliedStepIndex = _lastAppliedStepIndex;
    final shouldFocusInitialState =
        !animated && targetIndex == 0 && _lastAppliedStepIndex < 0;
    final state = _displayState(
      _stateForStep(targetIndex),
      forInitialFocus: shouldFocusInitialState,
    );
    final canAnimate =
        animated && targetIndex > 0 && _lastAppliedStepIndex == targetIndex - 1;
    if (!canAnimate) {
      if (shouldFocusInitialState) {
        renderer.applyState(state);
        if (_perspectivePlayerId == null &&
            _fallbackPerspectivePlayerId.isNotEmpty) {
          _pendingAllPlayersFocusReset = true;
          _syncAllPlayersAfterInitialFocus();
        }
      } else {
        renderer.applyStateWithoutCameraFocus(state);
      }
      _lastAppliedStepIndex = targetIndex;
      _syncPerspectiveCamera(
        immediate: _consumePendingPerspectiveCameraFocus(),
      );
      _announceTurnMarkerForTransition(
        previousIndex: previousAppliedStepIndex,
        targetIndex: targetIndex,
        animated: animated,
      );
      return;
    }

    final step = widget.timeline.steps[targetIndex - 1];
    final previousState = _displayState(step.previousState);
    final effects = ReplayRendererEffectPlanner.effectsForStep(
      commandEffects: step.uiEffects.rendererEffects,
      events: step.events,
      state: state,
      previousState: previousState,
      l10n: widget.l10n,
    );
    if (_shouldFastForwardStep(step, effects, state, previousState)) {
      renderer.applyStateWithoutCameraFocus(state);
      _lastAppliedStepIndex = targetIndex;
      _syncPerspectiveCamera(
        immediate: _consumePendingPerspectiveCameraFocus(),
      );
      _announceTurnMarkerForTransition(
        previousIndex: previousAppliedStepIndex,
        targetIndex: targetIndex,
        animated: animated,
      );
      return;
    }

    await renderer.applyTransition(state, effects);
    _lastAppliedStepIndex = targetIndex;
    _syncPerspectiveCamera(immediate: _consumePendingPerspectiveCameraFocus());
    _announceTurnMarkerForTransition(
      previousIndex: previousAppliedStepIndex,
      targetIndex: targetIndex,
      animated: animated,
    );
  }

  GameState _stateForStep(int index) {
    if (index <= 0) return widget.timeline.initialState;
    return widget.timeline.steps[index - 1].state;
  }

  GameState _displayState(GameState state, {bool forInitialFocus = false}) {
    return state.copyWith(
      activePlayerId:
          _perspectivePlayerId ??
          (forInitialFocus ? _fallbackPerspectivePlayerId : ''),
      activePlayerCanAct: false,
    );
  }

  int _turnForStep(int index) {
    if (index <= 0) return widget.timeline.firstTurn;
    return widget.timeline.steps[index - 1].turn;
  }

  void _resetTurnMarkerForCurrentStep() {
    _announcedTurnNumber = _showTurnMarkers ? _turnForStep(_stepIndex) : null;
    _turnMarkerSignal++;
  }

  String get _fallbackPerspectivePlayerId {
    final playerIds = widget.timeline.playerIds;
    return playerIds.isEmpty ? '' : playerIds.first;
  }

  void _syncAllPlayersAfterInitialFocus() {
    if (!_pendingAllPlayersFocusReset ||
        _renderer == null ||
        !_renderer!.initialCameraFocusReadyListenable.value ||
        !mounted) {
      return;
    }
    _pendingAllPlayersFocusReset = false;
    _renderer!.applyStateWithoutCameraFocus(
      _displayState(_stateForStep(_stepIndex)),
    );
    _syncPerspectiveCamera(immediate: false);
  }
}
