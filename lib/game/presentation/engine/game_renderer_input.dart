part of 'game_renderer.dart';

extension GameRendererInputHandling on GameRenderer {
  bool _startLongPressInspectAtWidgetPosition(Vector2 widgetPosition) {
    if (!_isReady || isDragging || hasMultipleViewportPointers) return false;
    final tileData = tileDataAtWidgetPositionForTesting(widgetPosition);
    if (tileData == null) return false;

    return _selectTileFromLongPress(tileData, widgetPosition: widgetPosition);
  }

  bool _selectTileFromLongPress(TileData tileData, {Vector2? widgetPosition}) {
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

  bool _canInspectTileFromLongPress(TileData tileData) {
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

  bool _matchesLongPressInspectHex(TileData? tileData) {
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
