part of 'game_renderer.dart';

/// Owns Flame lifecycle callbacks and renderer resource disposal.
mixin GameRendererLifecycle on HexWorld {
  GameRenderer get _lifecycleRenderer => this as GameRenderer;

  @override
  void update(double dt) {
    super.update(dt);
    final renderer = _lifecycleRenderer;
    if (renderer._isReady && !renderer._isDisposed) {
      renderer._cameraController.update(dt);
    }
    renderer._syncFastCameraRendering(dt);
  }

  @override
  Future<void> buildWorld() => _lifecycleRenderer._buildRendererWorldSafely();

  void disposeRenderer() {
    final renderer = _lifecycleRenderer;
    if (renderer._isDisposed) return;
    renderer
      .._isDisposed = true
      .._cancelRendererTransitions()
      .._readyNotifier.dispose()
      .._zoomNotifier.dispose()
      .._initialCameraFocusReadyNotifier.dispose()
      .._viewModelNotifier.dispose()
      .._unitAnimationController.dispose();
  }
}

extension GameRendererWorldLifecycle on GameRenderer {
  bool get hasReferenceImage => _sceneBuilder.hasReferenceImage;

  void _initializeRendererComponents() {
    final localizations = l10n;
    final turnCostLabelBuilder = localizations == null
        ? null
        : (int count) => localizations.turnCountLabel(count);
    final moveConfirmationLabelBuilder = localizations == null
        ? null
        : (int count) => localizations.selectionActionConfirmWithTurns(
            localizations.turnCountLabel(count),
          );
    _unitMarkerLayer = UnitMarkerLayer(
      mapData: mapData,
      colorForPlayer: _colorForPlayer,
      onUnitTapped: _handleUnitMarkerTapped,
      reduceMotion: _reduceMotion,
    );
    _movePreviewLayer = UnitMovePreviewLayer(
      turnCostLabelBuilder: turnCostLabelBuilder,
      confirmationLabelBuilder: moveConfirmationLabelBuilder,
      confirmationLabel: localizations?.selectionActionConfirm,
    );
    _fieldImprovementMarkerLayer = FieldImprovementMarkerLayer();
    _artifactMarkerLayer = ArtifactMarkerLayer(
      onArtifactTapped: _handleArtifactMarkerTapped,
    );
    _mapObjectiveMarkerLayer = MapObjectiveMarkerLayer(
      colorForPlayer: _colorForPlayer,
      onObjectiveTapped: _handleMapObjectiveMarkerTapped,
    );
    _cityMarkerLayer = CityMarkerLayer(
      colorForPlayer: _colorForPlayer,
      onCityTapped: _handleCityMarkerTapped,
      reduceMotion: _reduceMotion,
    );
    _cityTerritoryOverlayLayer = CityTerritoryOverlayLayer(
      colorForPlayer: _colorForPlayer,
    );
    _eraTintOverlayLayer = EraTintOverlayLayer();
    _cityManagementOverlayLayer = CityManagementOverlayLayer();
    _cityFoundingPreviewLayer = CityFoundingPreviewLayer(
      colorForPlayer: _colorForPlayer,
    );
    _fogOfWarOverlayLayer = FogOfWarOverlayLayer();
    _particleEffectsLayer = ParticleEffectsLayer();
    _cityProductionParticleLayer = CityProductionParticleLayer(
      reduceMotion: _reduceMotion,
    );
    _cloudDriftLayer = CloudDriftLayer(reduceMotion: _reduceMotion);
    _floatingTextLayer = _createFloatingTextLayer();
    _combatHexAlertLayer = CombatHexAlertLayer();
    _threatOverlayLayer = ThreatOverlayLayer();
    _hoverIntentMarkerLayer = HoverIntentMarkerLayer();
    _actionPaletteLayer = ActionPaletteLayer(
      onPreviewWorkerImprovement: _handlePreviewWorkerImprovement,
      onConfirmWorkerImprovement: _handleConfirmWorkerImprovement,
      onCancelWorkerActionSelection: _handleCancelWorkerActionSelection,
      onConfirmMovePreview: _handleConfirmMovePreview,
      turnCostLabelBuilder: turnCostLabelBuilder,
      confirmationLabelBuilder: moveConfirmationLabelBuilder,
      confirmationLabel: localizations?.selectionActionConfirm,
    );

    _unitAnimationController = UnitAnimationController(_unitMarkerLayer);
  }

  Future<void> _buildRendererWorldSafely() async {
    try {
      await _buildRendererWorld();
    } catch (error, stackTrace) {
      _queuedRendererEffects.cancelAll(error, stackTrace);
      disposeRenderer();
      rethrow;
    }
  }

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
    unawaited(_flushQueuedRendererEffectBatches());
    onLoadingProgress?.call(0.98);
    if (!_isDisposed) _readyNotifier.value = true;
    onLoadingProgress?.call(1);
  }

  Future<void> _flushQueuedRendererEffectBatches() async {
    _effectDispatcher.prepareMovementOrigins(
      _queuedRendererEffects.pendingEffects,
    );
    while (_queuedRendererEffects.hasPending && !_isDisposed) {
      final batch = _queuedRendererEffects.takeNext();
      try {
        await _effectDispatcher.handleEffects(
          batch.effects,
          beforeEffect: _ensureRendererActive,
        );
        batch.complete();
      } catch (error, stackTrace) {
        batch.completeError(error, stackTrace);
      } finally {
        _queuedRendererEffects.finish(batch);
      }
    }
  }

  void _cancelRendererTransitions() {
    final error = StateError(
      'GameRenderer disposed before queued effects completed',
    );
    _queuedRendererEffects.cancelAll(error, StackTrace.current);
    if (_isReady) _cameraController.cancelPendingMotion();
  }

  void _applyViewMode() {
    if (!_isReady || _isDisposed) return;
    _sceneBuilder.setViewMode(_viewMode);
    _syncAfterAction();
  }
}

final class _QueuedRendererEffectQueue {
  final List<_QueuedRendererEffectBatch> _pending = [];
  _QueuedRendererEffectBatch? _active;

  bool get hasPending => _pending.isNotEmpty;

  Iterable<RendererEffect> get pendingEffects sync* {
    for (final batch in _pending) {
      yield* batch.effects;
    }
  }

  _QueuedRendererEffectBatch enqueue(Iterable<RendererEffect> effects) {
    final batch = _QueuedRendererEffectBatch(effects);
    _pending.add(batch);
    return batch;
  }

  _QueuedRendererEffectBatch takeNext() {
    final batch = _pending.removeAt(0);
    _active = batch;
    return batch;
  }

  void finish(_QueuedRendererEffectBatch batch) {
    if (identical(_active, batch)) _active = null;
  }

  void cancelAll(Object error, StackTrace stackTrace) {
    _active?.completeError(error, stackTrace);
    for (final batch in _pending) {
      batch.completeError(error, stackTrace);
    }
    _pending.clear();
  }
}

final class _QueuedRendererEffectBatch {
  _QueuedRendererEffectBatch(Iterable<RendererEffect> effects)
    : effects = List<RendererEffect>.unmodifiable(effects);

  final List<RendererEffect> effects;
  final Completer<void> _completer = Completer<void>();

  Future<void> get done => _completer.future;

  void complete() {
    if (!_completer.isCompleted) _completer.complete();
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (!_completer.isCompleted) {
      _completer.completeError(error, stackTrace);
    }
  }
}
