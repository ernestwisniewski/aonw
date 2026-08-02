part of 'game_renderer.dart';

/// Adapts Flame pointer and long-press callbacks to renderer input intents.
mixin GameRendererInput on HexWorld, HexInputBehavior, LongPressDetector {
  GameRenderer get _inputRenderer => this as GameRenderer;

  @override
  void onLongPressStart(LongPressStartInfo info) {
    handleViewportLongPressStart(info.eventPosition.widget);
  }

  @override
  void onLongPressMoveUpdate(LongPressMoveUpdateInfo info) {
    handleViewportLongPressMoveUpdate(info.eventPosition.widget);
  }

  @override
  void onLongPressUp() {
    handleViewportLongPressUp();
  }

  @override
  void onLongPressEnd(LongPressEndInfo info) {
    handleViewportLongPressEnd(info.eventPosition.widget);
  }

  @override
  void onLongPressCancel() {
    handleViewportLongPressCancel();
  }

  @override
  void handleViewportLongPressStart(Vector2 position) {
    _inputRenderer._startLongPressInspectAtWidgetPosition(position);
  }

  @override
  void handleViewportLongPressMoveUpdate(Vector2 position) {
    _inputRenderer._updateLongPressInspectAtWidgetPosition(position);
  }

  @override
  void handleViewportLongPressUp() {
    _inputRenderer
      .._confirmLongPressInspect()
      .._clearHoverIntent();
  }

  @override
  void handleViewportLongPressEnd(Vector2 position) {
    _inputRenderer
      .._confirmLongPressInspect()
      .._clearHoverIntent();
  }

  @override
  void handleViewportLongPressCancel() {
    _inputRenderer
      .._cancelLongPressInspect()
      .._clearHoverIntent();
  }

  @override
  void handleViewportPointerDown(int pointerId, Vector2 position) {
    final renderer = _inputRenderer;
    final inputPosition = worldInputPointForWidget(position);
    final hadActiveLongPressInspect = renderer._longPressInspectActive;
    if (hadActiveLongPressInspect) {
      renderer._cancelLongPressInspect();
    }
    renderer._suppressTapsUntilNextPointerDown = hadActiveLongPressInspect;
    super.handleViewportPointerDown(pointerId, inputPosition);
    renderer._syncHoverIntentAtWidgetPosition(position);
  }

  @override
  void handleViewportPointerMove(int pointerId, Vector2 position) {
    final renderer = _inputRenderer;
    final inputPosition = worldInputPointForWidget(position);
    if (renderer._longPressInspectActive) {
      renderer._updateLongPressInspectAtWidgetPosition(position);
      return;
    }
    super.handleViewportPointerMove(pointerId, inputPosition);
    if (isDragging || hasMultipleViewportPointers) {
      renderer._clearHoverIntent();
      return;
    }
    renderer._syncHoverIntentAtWidgetPosition(position);
  }

  @override
  void handleViewportPointerUp(int pointerId) {
    _inputRenderer._confirmLongPressInspect();
    super.handleViewportPointerUp(pointerId);
    _inputRenderer._clearHoverIntent();
  }

  @override
  void handleViewportPointerCancel(int pointerId) {
    _inputRenderer._cancelLongPressInspect();
    super.handleViewportPointerCancel(pointerId);
    _inputRenderer._clearHoverIntent();
  }

  @override
  void handleViewportPointerHover(Vector2 position) {
    _inputRenderer._syncHoverIntentAtWidgetPosition(position);
  }

  @override
  void handleViewportPointerExit() {
    _inputRenderer._clearHoverIntent();
  }

  @override
  void handleViewportPanZoomStart(Vector2 focalPoint) {
    _inputRenderer._cancelLongPressInspect();
    super.handleViewportPanZoomStart(worldInputPointForWidget(focalPoint));
    _inputRenderer._clearHoverIntent();
  }

  @override
  void handleViewportPanZoomUpdate({
    required Vector2 panDelta,
    required double scale,
    required Vector2 focalPoint,
  }) {
    _inputRenderer._cancelLongPressInspect();
    final inputFocalPoint = worldInputPointForWidget(focalPoint);
    final inputPreviousFocalPoint = worldInputPointForWidget(
      focalPoint - panDelta,
    );
    super.handleViewportPanZoomUpdate(
      panDelta: inputFocalPoint - inputPreviousFocalPoint,
      scale: scale,
      focalPoint: inputFocalPoint,
    );
    _inputRenderer._clearHoverIntent();
  }

  @override
  void handleViewportPanZoomEnd() {
    super.handleViewportPanZoomEnd();
    _inputRenderer._clearHoverIntent();
  }

  @visibleForTesting
  WorldTile? tileDataAtWidgetPositionForTesting(Vector2 widgetPosition) {
    final renderer = _inputRenderer;
    if (!renderer._isReady) return null;
    final inputPosition = worldInputPointForWidget(widgetPosition);
    final worldPoint = camera.globalToLocal(inputPosition);
    return renderer._sceneBuilder.grid.tileDataAtWorldPoint(worldPoint);
  }

  Offset _inspectionAnchorForTile(WorldTile tileData, {Vector2? fallback}) {
    final renderer = _inputRenderer;
    if (!renderer._isReady) {
      return Offset(fallback?.x ?? 0, fallback?.y ?? 0);
    }
    final tileCenter = HexGeometry.tilePosition(
      col: tileData.col,
      row: tileData.row,
      hexRadius: renderer._sceneBuilder.grid.config.hexRadius,
    );
    final worldPoint = Vector2(
      tileCenter.x,
      tileCenter.y * HexGrid.perspectiveY - 16,
    );
    final viewportPoint =
        (worldPoint - camera.viewfinder.position) * camera.viewfinder.zoom;
    final projectedPoint = worldOutputPointForWidget(viewportPoint);
    return Offset(projectedPoint.x, projectedPoint.y);
  }
}

extension GameRendererInputHandling on GameRenderer {
  bool _startLongPressInspectAtWidgetPosition(Vector2 widgetPosition) {
    if (!_isReady || isDragging || hasMultipleViewportPointers) return false;
    final tileData = tileDataAtWidgetPositionForTesting(widgetPosition);
    if (tileData == null) return false;

    return _selectTileFromLongPress(tileData, widgetPosition: widgetPosition);
  }

  bool _selectTileFromLongPress(WorldTile tileData, {Vector2? widgetPosition}) {
    _suppressTapsUntilNextPointerDown = true;
    if (_cancelMoveTargetingForLongPress()) {
      return true;
    }
    if (!_canInspectTileFromLongPress(tileData)) {
      _clearHoverIntent();
      return false;
    }

    final inspectHex = CityHex(col: tileData.col, row: tileData.row);
    if (_longPressInspectActive && _longPressInspectHex == inspectHex) {
      if (widgetPosition != null) {
        _lastHoverWidgetPosition = widgetPosition.clone();
      }
      _syncHoverIntentForTile(tileData, forceInspect: true);
      return true;
    }

    _longPressInspectActive = true;
    _longPressInspectionPreviewActive = true;
    _longPressInspectHex = inspectHex;
    if (widgetPosition != null) {
      _lastHoverWidgetPosition = widgetPosition.clone();
    }
    _syncHoverIntentForTile(tileData, forceInspect: true);
    unawaited(onCommand(SelectTileCommand(tileData.col, tileData.row)));
    _handleTileInspectionPreviewed(
      tileData,
      anchor: _inspectionAnchorForTile(tileData, fallback: widgetPosition),
    );
    return true;
  }

  bool _cancelMoveTargetingForLongPress() {
    if (!_renderState.moveCommandActive || _renderState.selectedUnit == null) {
      return false;
    }
    _clearHoverIntent();
    unawaited(onCommand(const ToggleMoveTargetingCommand()));
    return true;
  }

  bool _canInspectTileFromLongPress(WorldTile tileData) {
    final playerId = _renderState.activePlayerId;
    if (playerId.isEmpty || playerId == GameRenderer._loadingPlayerId) {
      return true;
    }
    if (!_renderState.fogOfWar.players.containsKey(playerId)) return true;
    final visibility = _renderState.activePlayerVisibility;
    return visibility.canInspectTile(tileData);
  }

  void _updateLongPressInspectAtWidgetPosition(Vector2 widgetPosition) {
    if (!_longPressInspectActive) return;
    final tileData = tileDataAtWidgetPositionForTesting(widgetPosition);
    if (!_matchesLongPressInspectHex(tileData)) {
      _cancelLongPressInspect();
      _clearHoverIntent();
      return;
    }

    _lastHoverWidgetPosition = widgetPosition.clone();
    _syncHoverIntentForTile(tileData!, forceInspect: true);
  }

  bool _matchesLongPressInspectHex(WorldTile? tileData) {
    final inspectHex = _longPressInspectHex;
    return inspectHex != null &&
        tileData != null &&
        tileData.col == inspectHex.col &&
        tileData.row == inspectHex.row;
  }

  void _confirmLongPressInspect() {
    if (!_longPressInspectActive) return;
    final wasPreviewing = _longPressInspectionPreviewActive;
    _longPressInspectActive = false;
    _longPressInspectionPreviewActive = false;
    _longPressInspectHex = null;
    _suppressTapsUntilNextPointerDown = true;
    if (wasPreviewing) onTileInspectionConfirmed?.call();
  }

  void _cancelLongPressInspect() {
    if (!_longPressInspectActive) return;
    final wasPreviewing = _longPressInspectionPreviewActive;
    _longPressInspectActive = false;
    _longPressInspectionPreviewActive = false;
    _longPressInspectHex = null;
    _suppressTapsUntilNextPointerDown = true;
    if (wasPreviewing) onTileInspectionCanceled?.call();
  }
}
