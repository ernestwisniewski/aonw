part of 'game_renderer.dart';

extension GameRendererStateSync on GameRenderer {
  void _applyState(GameState state, {required bool suppressCameraFocus}) {
    if (_isDisposed) return;
    _renderState = state;
    if (_isReady) {
      _syncAfterAction(suppressCameraFocus: suppressCameraFocus);
    } else {
      _publishViewModelFromState();
    }
  }

  Future<void> _applyTransitionNow(
    GameState state,
    Iterable<RendererEffect> effects,
  ) async {
    if (_isDisposed) return;
    final pending = effects.toList(growable: false);
    final transitionControlsCamera = _transitionControlsCamera(pending);
    final animatedIds = <String>{
      for (final e in pending)
        if (e is AnimateUnitMoveEffect) e.unitId,
    };
    final combatAnimatedIds = <String>{
      for (final e in pending)
        if (e is PlayCombatAnimationEffect) ...[
          e.attackerUnitId,
          e.defenderUnitId,
        ],
    };
    _unitMarkerLayer
      ..pinPendingMovePositions(animatedIds)
      ..retainPendingAnimationMarkers(combatAnimatedIds);
    _applyState(state, suppressCameraFocus: transitionControlsCamera);
    await _handleEffectsNow(pending);
  }

  Future<void> _handleEffectsNow(Iterable<RendererEffect> effects) async {
    if (_isDisposed) return;
    final pending = effects.toList();
    if (pending.isEmpty) return;
    if (!_isReady) {
      _queuedRendererEffects.addAll(pending);
      return;
    }
    await _effectDispatcher.handleEffects(pending);
  }

  Future<void> _enqueueTransition(Future<void> Function() operation) {
    final next = _transitionQueue.then((_) => operation());
    _transitionQueue = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  void _syncGridSelection() {
    if (!_isReady || _isDisposed) return;
    final selection = _viewModelNotifier.value.selection;
    final tile = selection?.tile;
    if (selection?.type == GameSelectionType.tile && tile != null) {
      _sceneBuilder.grid.selectTile(tile.col, tile.row);
    } else {
      _sceneBuilder.grid.clearSelection();
    }
  }

  void _syncAfterAction({bool suppressCameraFocus = false}) {
    if (_isDisposed) return;
    _renderingCoordinator.syncAll(
      state: _renderState,
      parent: world,
      viewModelNotifier: _viewModelNotifier,
      workerActionPaletteOptions: _workerActionPaletteOptions(),
      showCityLabels: _shouldShowCityLabels,
      strategicView: _viewMode == MapViewMode.tile,
    );
    _combatHexAlertLayer.syncState(
      parent: _sceneBuilder.grid,
      state: _renderState,
      reduceMotion: _reduceMotion,
    );
    _syncCityProductionParticles();
    _syncCloudDriftLayer();
    if (suppressCameraFocus) {
      _primeSelectionFocus();
    } else {
      _focusInitialActivePlayer();
      _focusActiveSelection();
    }
    _syncHoverIntentAfterStateChange();
  }

  void _syncHoverIntentAfterStateChange() {
    if (_hoverIntentIsStaleForCurrentState(
      _hoverIntentMarkerLayer.activeKind,
    )) {
      _clearHoverIntent();
      return;
    }
    _lastSyncedHoverHex = null;
    _refreshHoverIntent();
  }

  bool _hoverIntentIsStaleForCurrentState(HoverIntentKind? kind) {
    return _hoverIntentResolver().isStale(
      kind,
      longPressInspectActive: _longPressInspectActive,
    );
  }

  void _primeSelectionFocus() {
    _lastFocusedSelectionKey = _selectionFocusKey(_renderState.selection);
    _didPrimeSelectionFocus = true;
  }

  List<ActionPaletteOption> _workerActionPaletteOptions() {
    final builder = _workerActionPaletteOptionsBuilder;
    if (builder == null) return const [];
    final pending = _renderState.pendingAction;
    if (pending is! PendingWorkerActionSelection) return const [];
    final worker = _unitById(pending.unitId);
    if (worker == null || worker.type != GameUnitType.worker) return const [];
    return builder(
      state: _renderState,
      worker: worker,
      pendingAction: pending,
      mapData: mapData,
    );
  }

  void _syncCityProductionParticles() {
    _cityProductionParticleLayer.visible = _shouldShowProductionParticles;
    _cityProductionParticleLayer.sync(
      parent: world,
      cities: _renderState.citiesKnownToActivePlayer.where(
        (city) => city.ownerPlayerId == _renderState.activePlayerId,
      ),
      colorForPlayer: _colorForPlayer,
    );
  }

  void _syncCloudDriftLayer() {
    _cloudDriftLayer.sync(
      parent: world,
      mapData: mapData,
      visibility: _renderState.activePlayerVisibility,
    );
  }

  MarkerDensity get _currentMarkerDensity {
    final viewportSize = camera.viewport.size;
    return GameRenderer._markerDensityPolicy.resolve(
      zoom: camera.viewfinder.zoom,
      viewportWidth: viewportSize.x,
      viewportHeight: viewportSize.y,
    );
  }

  bool get _shouldShowCityLabels => _currentMarkerDensity.showCityLabels;

  void _publishZoom() {
    if (_isDisposed) return;
    final zoom = camera.viewfinder.zoom;
    if (_zoomNotifier.value == zoom) return;
    _zoomNotifier.value = zoom;
  }

  void _syncMarkerDensityForZoom({bool force = false}) {
    final density = _markerDensityForZoomSync(force: force);
    if (density == null) return;
    _cityMarkerLayer
      ..markerWorldScale = density.markerWorldScale
      ..setLabelVisibility(density.showCityLabels)
      ..showHealthBar = density.showHealthBar;
    _unitMarkerLayer.markerWorldScale = density.markerWorldScale;
    _artifactMarkerLayer.markerWorldScale = density.markerWorldScale;
    _mapObjectiveMarkerLayer.markerWorldScale = density.markerWorldScale;
    _unitMarkerLayer.setDetailVisibility(
      showPeripheralDetails: density.showUnitPeripheralDetails,
      showOwnerColor: density.showOwnerColor,
      showHealthBar: density.showHealthBar,
      showTypeBadge: density.showTypeBadge,
      showStateBadge: density.showStateBadge,
    );
    _cityTerritoryOverlayLayer.zoomEmphasis = density.territoryOverlayEmphasis;
    _unitMarkerLayer
      ..spriteScale = density.unitSpriteScale
      ..tacticalViewEmphasis = density.unitTacticalEmphasis
      ..animateIdle = density.animateUnitIdle;
    _movePreviewLayer.showCostLabel = density.showCostLabel;
    _floatingTextLayer.visible = density.showFloatingText;
    _cityProductionParticleLayer.visible = _shouldShowProductionParticles;
    _syncCityProductionParticles();
  }

  bool get _shouldShowProductionParticles =>
      _currentMarkerDensity.showProductionParticles &&
      !_mapDecisionModeSuppressesProductionParticles;

  bool get _mapDecisionModeSuppressesProductionParticles {
    return switch (_renderState.interactionMode) {
      GameInteractionMode.cityFounding ||
      GameInteractionMode.moveTargeting ||
      GameInteractionMode.cityWorkedHexSelection ||
      GameInteractionMode.cityExpansionSelection ||
      GameInteractionMode.workerAction ||
      GameInteractionMode.merchantTradeRouteSelection ||
      GameInteractionMode.merchantMoveToCitySelection ||
      GameInteractionMode.attackTargeting => true,
      _ => false,
    };
  }

  void _syncReduceMotion() {
    _unitMarkerLayer.reduceMotion = _reduceMotion;
    _cityMarkerLayer.reduceMotion = _reduceMotion;
    _cityProductionParticleLayer.reduceMotion = _reduceMotion;
    _cloudDriftLayer.reduceMotion = _reduceMotion;
    _floatingTextLayer.reduceMotion = _reduceMotion;
    if (_isReady) {
      _cameraController.reduceMotion = _reduceMotion;
      _lastSyncedHoverHex = null;
      _refreshHoverIntent();
    }
  }

  void _syncHoverIntentAtWidgetPosition(
    Vector2 widgetPosition, {
    bool forceInspect = false,
  }) {
    if (!_isReady || isDragging || hasMultipleViewportPointers) {
      _clearHoverIntent();
      return;
    }
    final tileData = tileDataAtWidgetPositionForTesting(widgetPosition);
    if (tileData == null) {
      _clearHoverIntent();
      return;
    }
    _lastHoverWidgetPosition = widgetPosition.clone();
    _syncHoverIntentForTile(
      tileData,
      forceInspect: forceInspect || _longPressInspectActive,
    );
  }

  void _syncHoverIntentForTile(TileData tileData, {bool forceInspect = false}) {
    if (!_isReady) return;
    final cacheKey = (
      col: tileData.col,
      row: tileData.row,
      forceInspect: forceInspect,
    );
    if (_lastSyncedHoverHex == cacheKey) return;
    _lastSyncedHoverHex = cacheKey;
    final intent = _hoverIntentResolver().resolve(
      tileData,
      forceInspect: forceInspect,
    );
    _hoverIntentMarkerLayer.sync(parent: _sceneBuilder.grid, intent: intent);
  }

  void _refreshHoverIntent() {
    final hoverPosition = _lastHoverWidgetPosition;
    if (hoverPosition == null) return;
    _syncHoverIntentAtWidgetPosition(
      hoverPosition,
      forceInspect: _longPressInspectActive,
    );
  }

  void _clearHoverIntent() {
    _lastHoverWidgetPosition = null;
    _lastSyncedHoverHex = null;
    _hoverIntentMarkerLayer.clear();
  }

  GameHoverIntentResolver _hoverIntentResolver() {
    final cached = _cachedHoverIntentResolver;
    if (cached != null &&
        identical(_cachedHoverIntentResolverState, _renderState) &&
        _cachedHoverIntentResolverReduceMotion == _reduceMotion) {
      return cached;
    }
    final resolver = GameHoverIntentResolver(
      state: _renderState,
      mapData: mapData,
      reduceMotion: _reduceMotion,
      colorForPlayer: _colorForPlayer,
    );
    _cachedHoverIntentResolver = resolver;
    _cachedHoverIntentResolverState = _renderState;
    _cachedHoverIntentResolverReduceMotion = _reduceMotion;
    return resolver;
  }

  void _publishViewModelFromState() {
    if (_isDisposed) return;
    final viewModel = GameRenderViewModel.fromState(_renderState);
    if (_viewModelNotifier.value == viewModel) return;
    _viewModelNotifier.value = viewModel;
  }

  GameUnit? _unitById(String unitId) {
    for (final unit in _renderState.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  int _colorForPlayer(String playerId) {
    return PlayerColorTheme.resolveValue(
      _renderState.colorForPlayer(playerId) ?? Player.palette.first,
    );
  }
}
