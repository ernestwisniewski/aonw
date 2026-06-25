part of 'game_renderer.dart';

extension GameRendererWorldLifecycle on GameRenderer {
  Future<void> _buildRendererWorld() async {
    onLoadingProgress?.call(0);
    _cameraController = GameCameraController(
      camera: camera,
      mapData: mapData,
      reduceMotion: _reduceMotion,
    );
    onLoadingProgress?.call(0.08);
    await _sceneBuilder.build(
      parent: world,
      mapData: mapData,
      imagePath: imagePath,
      viewMode: _viewMode,
      displaySettings: _displaySettings,
      onTileTapped: (tile) => unawaited(_handleTileTapped(tile)),
      onReferenceImageProgress: (progress) {
        final clamped = progress.clamp(0.0, 1.0).toDouble();
        onLoadingProgress?.call(0.08 + clamped * 0.62);
      },
    );
    onLoadingProgress?.call(0.72);

    _effectDispatcher = GameEffectDispatcher(
      unitAnimationController: _unitAnimationController,
      cameraController: _cameraController,
      particleEffectsLayer: _particleEffectsLayer,
      floatingTextLayer: _floatingTextLayer,
      combatHexAlertLayer: _combatHexAlertLayer,
      particleParent: world,
      alertParent: _sceneBuilder.grid,
      onRendererStateChanged: _syncAfterAction,
      reduceMotion: () => _reduceMotion,
      moveCameraForUnitMovement: () => _moveCameraForUnitMovement,
      moveCameraForUnitMovementForUnit: _moveCameraForUnitMovementEffect,
      onUnitMovementCameraComplete: _restoreCameraAfterUnitMovementEffect,
      followUnitMovementCamera: () => _followUnitMovementCamera,
      canAutoFocusMapTarget: _canAutoFocusMapTarget,
      l10n: l10n,
    );
    onLoadingProgress?.call(0.78);

    _renderingCoordinator = GameRenderingCoordinator(
      unitMarkers: _unitMarkerLayer,
      movePreview: _movePreviewLayer,
      fieldImprovementMarkers: _fieldImprovementMarkerLayer,
      artifactMarkers: _artifactMarkerLayer,
      mapObjectiveMarkers: _mapObjectiveMarkerLayer,
      cityMarkers: _cityMarkerLayer,
      cityTerritory: _cityTerritoryOverlayLayer,
      eraTint: _eraTintOverlayLayer,
      cityManagement: _cityManagementOverlayLayer,
      cityFounding: _cityFoundingPreviewLayer,
      fogOfWar: _fogOfWarOverlayLayer,
      threatOverlay: _threatOverlayLayer,
      actionPalette: _actionPaletteLayer,
      grid: _sceneBuilder.grid,
    );
    onLoadingProgress?.call(0.84);

    _isReady = true;
    if (startCameraOffMap) {
      _cameraController.hideMap();
    } else {
      _cameraController.restore(initialCamera);
    }
    _publishZoom();
    _syncMarkerDensityForZoom(force: true);
    _syncAfterAction();
    onLoadingProgress?.call(0.92);
    await _flushQueuedRendererEffects();
    onLoadingProgress?.call(0.98);
    if (!_isDisposed) _readyNotifier.value = true;
    onLoadingProgress?.call(1);
  }

  Future<void> _flushQueuedRendererEffects() async {
    if (_queuedRendererEffects.isEmpty || _isDisposed) return;
    final effects = List<RendererEffect>.of(_queuedRendererEffects);
    _queuedRendererEffects.clear();
    await _effectDispatcher.handleEffects(effects);
  }

  void _applyViewMode() {
    if (!_isReady || _isDisposed) return;
    _sceneBuilder.setViewMode(_viewMode);
    _syncAfterAction();
  }
}
