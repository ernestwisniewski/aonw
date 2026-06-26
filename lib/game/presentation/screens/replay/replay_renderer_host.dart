part of 'replay_screen.dart';

class _ReplayRendererHost extends ConsumerStatefulWidget {
  final GameSession session;
  final ReplayTimeline timeline;
  final HexDisplaySettings displaySettings;
  final bool followUnitMovementCamera;
  final bool cinematicCameraEnabled;
  final AppLocalizations l10n;

  const _ReplayRendererHost({
    required this.session,
    required this.timeline,
    required this.displaySettings,
    required this.followUnitMovementCamera,
    required this.cinematicCameraEnabled,
    required this.l10n,
  });

  @override
  ConsumerState<_ReplayRendererHost> createState() =>
      _ReplayRendererHostState();
}

class _ReplayRendererHostState extends ConsumerState<_ReplayRendererHost> {
  GameRenderer? _renderer;
  late final GameLoadingProgressController _loadingProgressController;
  Timer? _playbackTimer;
  int _stepIndex = 0;
  int _lastAppliedStepIndex = -1;
  bool _playing = false;
  bool _applying = false;
  bool _pendingApply = false;
  bool _pendingApplyAnimated = false;
  bool _reduceMotion = false;
  bool _pendingAllPlayersFocusReset = false;
  bool _pendingPerspectiveCameraFocus = false;
  bool _showTurnMarkers = true;
  double _speed = 1.0;
  int? _announcedTurnNumber;
  int _turnMarkerSignal = 0;
  String? _perspectivePlayerId;

  @override
  void initState() {
    super.initState();
    _announcedTurnNumber = _turnForStep(_stepIndex);
    _loadingProgressController = GameLoadingProgressController(
      GameLoadingProgress.initial.bumpedTo(0.42),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _createAndMountRenderer();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    _renderer?.reduceMotion = reduceMotion;
  }

  @override
  void didUpdateWidget(_ReplayRendererHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldRecreateRenderer(oldWidget)) {
      final oldRenderer = _renderer;
      if (oldRenderer != null) _detachRendererListeners(oldRenderer);
      _renderer = null;
      _lastAppliedStepIndex = -1;
      _pendingAllPlayersFocusReset = false;
      _resetTurnMarkerForCurrentStep();
      if (oldRenderer != null) _releaseRendererAfterFrame(oldRenderer);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _createAndMountRenderer();
      });
      return;
    }
    _renderer?.displaySettings = widget.displaySettings;
    _renderer?.cinematicCameraEnabled = widget.cinematicCameraEnabled;
    _syncReplayCameraMode();
    if (oldWidget.followUnitMovementCamera != widget.followUnitMovementCamera) {
      if (_freeCamera) {
        _renderer?.stopFollowingCameraTarget();
      } else {
        _syncPerspectiveCamera(immediate: false);
      }
    }
    if (oldWidget.timeline != widget.timeline) {
      _stepIndex = _stepIndex.clamp(0, widget.timeline.steps.length).toInt();
      _lastAppliedStepIndex = -1;
      _pendingAllPlayersFocusReset = false;
      _resetTurnMarkerForCurrentStep();
      _applyCurrentStepWhenRendererReady();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    final renderer = _renderer;
    if (renderer != null) {
      _detachRendererListeners(renderer);
      renderer.disposeRenderer();
    }
    _loadingProgressController.dispose();
    super.dispose();
  }

  void _createAndMountRenderer() {
    if (_renderer != null) return;
    final renderer = _createRenderer();
    _attachRendererListeners(renderer);
    _syncReplayCameraMode(renderer: renderer);
    setState(() => _renderer = renderer);
    _applyCurrentStepWhenRendererReady();
  }

  void _announceTurnMarkerForTransition({
    required int previousIndex,
    required int targetIndex,
    required bool animated,
  }) {
    if (!_showTurnMarkers || !mounted || previousIndex < 0) return;
    final turn = ReplayTurnBannerPolicy.turnForTransition(
      previousTurn: _turnForStep(previousIndex),
      targetTurn: _turnForStep(targetIndex),
      animated: animated,
      forward: targetIndex > previousIndex,
    );
    if (turn == null) return;
    setState(() {
      _announcedTurnNumber = turn;
      _turnMarkerSignal++;
    });
  }

  void _setStep(int value, {bool animated = false}) {
    final next = value.clamp(0, widget.timeline.steps.length).toInt();
    if (next == _stepIndex && _lastAppliedStepIndex == next) return;
    _playbackTimer?.cancel();
    setState(() {
      _playing = false;
      _stepIndex = next;
    });
    unawaited(_applyStep(animated: animated));
  }

  void _setPerspective(String? playerId) {
    if (_perspectivePlayerId == playerId) return;
    _playbackTimer?.cancel();
    setState(() {
      _playing = false;
      _perspectivePlayerId = playerId;
      _lastAppliedStepIndex = -1;
      _pendingPerspectiveCameraFocus = true;
    });
    unawaited(_applyStep(animated: false));
  }

  void _setShowTurnMarkers(bool value) {
    if (_showTurnMarkers == value) return;
    setState(() {
      _showTurnMarkers = value;
      if (value) {
        _announcedTurnNumber = _turnForStep(_stepIndex);
        _turnMarkerSignal++;
      } else {
        _announcedTurnNumber = null;
      }
    });
  }

  void _togglePlayback() {
    if (_playing) {
      _playbackTimer?.cancel();
      setState(() => _playing = false);
      return;
    }
    if (_stepIndex >= widget.timeline.steps.length) {
      _stepIndex = 0;
      _lastAppliedStepIndex = -1;
      unawaited(_applyStep(animated: false));
    }
    setState(() => _playing = true);
    _schedulePlayback();
  }

  Future<void> _advancePlayback() async {
    if (_stepIndex >= widget.timeline.steps.length) {
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() => _stepIndex += 1);
    await _applyStep(animated: true);
    if (!mounted || !_playing) return;
    if (_stepIndex >= widget.timeline.steps.length) {
      setState(() => _playing = false);
      return;
    }
    _schedulePlayback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: GameUiTheme.bg),
              child: Center(
                child: SizedBox(
                  // Keep the Flame surface bounded in replay; the macOS
                  // renderer can stay blank when hosted full-screen here.
                  width: _replayViewportSize.width,
                  height: _replayViewportSize.height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: GameUiTheme.goldLight,
                        width: 4,
                      ),
                    ),
                    child: _ReplayMapSurface(
                      renderer: _renderer,
                      loadingProgress: _loadingProgressController,
                      l10n: widget.l10n,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: TurnStartBannerOverlay(
              turnNumber: _showTurnMarkers ? _announcedTurnNumber : null,
              showOnFirstBuild: _showTurnMarkers,
              showSignal: _turnMarkerSignal,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12 + MediaQuery.viewPaddingOf(context).bottom,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(
                child: _ReplayControls(
                  timeline: widget.timeline,
                  stepIndex: _stepIndex,
                  playing: _playing,
                  speed: _speed,
                  perspectivePlayerId: _perspectivePlayerId,
                  showTurnMarkers: _showTurnMarkers,
                  freeCamera: _freeCamera,
                  onTogglePlayback: _togglePlayback,
                  onPrevious: _stepIndex <= 0
                      ? null
                      : () => _setStep(_stepIndex - 1),
                  onNext: _stepIndex >= widget.timeline.steps.length
                      ? null
                      : () => _setStep(_stepIndex + 1, animated: true),
                  onStepChanged: (value) => _setStep(value),
                  onSpeedChanged: (value) => setState(() => _speed = value),
                  onPerspectiveChanged: _setPerspective,
                  onShowTurnMarkersChanged: _setShowTurnMarkers,
                  onFreeCameraChanged: _setFreeCamera,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _ReplayTopBar(
              title: widget.l10n.replayTitle,
              saveName: widget.timeline.save.name,
              onClose: () => context.go('/load-game'),
            ),
          ),
        ],
      ),
    );
  }
}
