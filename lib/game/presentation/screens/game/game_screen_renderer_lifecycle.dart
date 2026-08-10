part of 'game_screen.dart';

extension _GameScreenRendererLifecycle on _GameRendererSessionHostState {
  void _loadMapDisplayColors() => unawaited(
    ref.read(hexDisplayProvider.notifier).loadMapColors(widget.selection),
  );

  GameRenderer _createRenderer() {
    final session = widget.session;
    final gameplaySettings = ref.read(gameplaySettingsProvider);
    final mapInspection = MapInspectionBinder(ref: ref, session: session);
    final renderer = GameRenderer(
      mapData: session.mapData,
      imagePath: session.imagePath,
      initialCamera: session.initialCamera,
      focusActivePlayerOnFirstState:
          session.saveId.isNotEmpty &&
          (session.initialCamera == null ||
              session.initialCamera == CameraState.zero),
      initialViewMode: session.viewMode,
      onCommand: _dispatchRendererCommand,
      onCityDescriptionRequested: (_) {
        ref.read(mapInspectionControllerProvider.notifier).clear();
        ref
            .read(openSelectionDetailControllerProvider.notifier)
            .open(SelectionInfoChipId.description);
      },
      onTileInspected: mapInspection.inspectTile,
      onTileInspectionPreviewed: mapInspection.previewTile,
      onArtifactInspected: (artifact, anchor) {
        ref
            .read(mapInspectionControllerProvider.notifier)
            .inspectArtifact(artifact, anchor: anchor);
      },
      onObjectiveInspected: (progress, anchor) {
        ref
            .read(mapInspectionControllerProvider.notifier)
            .inspectObjective(progress, anchor: anchor);
      },
      onTileInspectionConfirmed: () {
        ref.read(mapInspectionControllerProvider.notifier).confirmPreview();
      },
      onTileInspectionCanceled: () {
        ref.read(mapInspectionControllerProvider.notifier).cancelPreview();
      },
      onLoadingProgress: _reportRendererLoadProgress,
      l10n: widget.l10n,
      presentationClock: session.gameMode == GameMode.multiplayer
          ? ref.read(gameClockProvider)
          : null,
      followUnitMovementCamera: gameplaySettings.followUnitMovementCamera,
      followEnemyUnitCamera: gameplaySettings.followEnemyUnitCamera,
      cinematicCameraEnabled: gameplaySettings.cinematicCameraEnabled,
    )..activateProjectedEffectSource(session.saveId);
    return renderer;
  }

  void _attachMapZoomDebugListener(GameRenderer renderer) {
    renderer.zoomListenable.addListener(_syncMapZoomDebugValue);
    _syncMapZoomDebugValue(renderer);
  }

  void _detachMapZoomDebugListener(GameRenderer renderer) =>
      renderer.zoomListenable.removeListener(_syncMapZoomDebugValue);

  void _syncMapZoomDebugValue([GameRenderer? source]) {
    final renderer = source ?? _renderer;
    final zoom = renderer.zoomListenable.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_renderer, renderer)) return;
      _mapZoomDebugController.setZoom(zoom);
    });
  }

  void _clearMapZoomDebugAfterLifecycle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapZoomDebugController.clear();
      } on Object {
        // The owning provider scope may already be gone during app teardown.
      }
    });
  }

  String? _activeMultiplayerMatchId() {
    final gameSave = widget.gameSave;
    final saveId = widget.session.saveId;
    if (gameSave?.gameMode != GameMode.multiplayer || saveId.isEmpty) {
      return null;
    }

    final networkSession = ref.read(networkSessionProvider);
    final sessionMatchId = networkSession?.matchId;
    if (sessionMatchId != null && sessionMatchId != saveId) return null;
    return saveId;
  }

  bool _shouldRecreateRenderer(_GameRendererSessionHost oldWidget) {
    final oldSession = oldWidget.session;
    return oldSession.saveId != widget.session.saveId ||
        oldSession.mapData != widget.session.mapData ||
        oldSession.imagePath != widget.session.imagePath ||
        oldSession.initialCamera != widget.session.initialCamera ||
        oldWidget.l10n.localeName != widget.l10n.localeName;
  }

  void _releaseRendererAfterFrame(GameRenderer renderer) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!identical(_renderer, renderer)) {
        renderer.disposeRenderer();
      }
    });
  }
}
