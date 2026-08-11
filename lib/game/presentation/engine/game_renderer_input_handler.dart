import 'dart:async';

import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/hex_world.dart';
import 'package:aonw/shared/input/hex_input_behavior.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Offset;

typedef TileInspectionPreview = void Function(WorldTile tile, {Offset? anchor});

/// Owns long-press inspection state and translates it into game intents.
final class GameRendererInputHandler {
  GameRendererInputHandler({
    required GameClientState Function() state,
    required Future<void> Function(GameIntent intent) onCommand,
    required void Function() clearHover,
    required void Function(WorldTile tile, {bool forceInspect}) syncHover,
    required void Function(Vector2? position) setHoverPosition,
    required TileInspectionPreview previewInspection,
    required VoidCallback? confirmInspection,
    required VoidCallback? cancelInspection,
  }) : _state = state,
       _onCommand = onCommand,
       _clearHover = clearHover,
       _syncHover = syncHover,
       _setHoverPosition = setHoverPosition,
       _previewInspection = previewInspection,
       _confirmInspection = confirmInspection,
       _cancelInspection = cancelInspection;

  final GameClientState Function() _state;
  final Future<void> Function(GameIntent intent) _onCommand;
  final void Function() _clearHover;
  final void Function(WorldTile tile, {bool forceInspect}) _syncHover;
  final void Function(Vector2? position) _setHoverPosition;
  final TileInspectionPreview _previewInspection;
  final VoidCallback? _confirmInspection;
  final VoidCallback? _cancelInspection;

  bool _active = false;
  bool _previewActive = false;
  bool suppressTapsUntilNextPointerDown = false;
  CityHex? _inspectHex;

  bool get isActive => _active;

  bool start(
    Vector2 widgetPosition, {
    required bool isReady,
    required bool isDragging,
    required bool hasMultiplePointers,
    required WorldTile? Function(Vector2 position) tileAtPosition,
    required Offset Function(WorldTile tile, {Vector2? fallback}) anchorForTile,
  }) {
    if (!isReady || isDragging || hasMultiplePointers) return false;
    final tile = tileAtPosition(widgetPosition);
    if (tile == null) return false;
    return selectTile(
      tile,
      widgetPosition: widgetPosition,
      anchor: anchorForTile(tile, fallback: widgetPosition),
    );
  }

  bool selectTile(WorldTile tile, {Vector2? widgetPosition, Offset? anchor}) {
    suppressTapsUntilNextPointerDown = true;
    if (_cancelMoveTargeting()) return true;
    if (!_canInspect(tile)) {
      _clearHover();
      return false;
    }

    final inspectHex = CityHex(col: tile.col, row: tile.row);
    if (_active && _inspectHex == inspectHex) {
      _rememberHover(widgetPosition);
      _syncHover(tile, forceInspect: true);
      return true;
    }

    _active = true;
    _previewActive = true;
    _inspectHex = inspectHex;
    _rememberHover(widgetPosition);
    _syncHover(tile, forceInspect: true);
    unawaited(_onCommand(SelectTileCommand(tile.col, tile.row)));
    _previewInspection(tile, anchor: anchor);
    return true;
  }

  void update(
    Vector2 widgetPosition, {
    required WorldTile? Function(Vector2 position) tileAtPosition,
  }) {
    if (!_active) return;
    final tile = tileAtPosition(widgetPosition);
    if (!_matches(tile)) {
      cancel();
      _clearHover();
      return;
    }
    _rememberHover(widgetPosition);
    _syncHover(tile!, forceInspect: true);
  }

  void beginPreviewForTesting(WorldTile tile) {
    suppressTapsUntilNextPointerDown = true;
    _active = true;
    _previewActive = true;
    _inspectHex = CityHex(col: tile.col, row: tile.row);
    _previewInspection(tile);
  }

  void confirm() {
    if (!_active) return;
    final wasPreviewing = _previewActive;
    _clearInspection();
    if (wasPreviewing) _confirmInspection?.call();
  }

  void cancel() {
    if (!_active) return;
    final wasPreviewing = _previewActive;
    _clearInspection();
    if (wasPreviewing) _cancelInspection?.call();
  }

  bool _cancelMoveTargeting() {
    final state = _state();
    if (!state.moveCommandActive || state.selectedUnit == null) return false;
    _clearHover();
    unawaited(_onCommand(const ToggleMoveTargetingCommand()));
    return true;
  }

  bool _canInspect(WorldTile tile) {
    final state = _state();
    final playerId = state.activePlayerId;
    if (playerId.isEmpty || playerId == '__loading__') return true;
    if (!state.fogOfWar.players.containsKey(playerId)) return true;
    return state.activePlayerVisibility.canInspectTile(tile);
  }

  bool _matches(WorldTile? tile) {
    final inspectHex = _inspectHex;
    return inspectHex != null &&
        tile != null &&
        tile.col == inspectHex.col &&
        tile.row == inspectHex.row;
  }

  void _rememberHover(Vector2? position) {
    if (position != null) _setHoverPosition(position.clone());
  }

  void _clearInspection() {
    _active = false;
    _previewActive = false;
    _inspectHex = null;
    suppressTapsUntilNextPointerDown = true;
  }
}

/// Thin Flame adapter; all mutable inspection policy lives in the handler.
mixin GameRendererInputAdapter on HexWorld, HexInputBehavior {
  final Map<int, Vector2> _pendingViewportPointerMoves = {};
  int _viewportPointerMoveFlushCount = 0;

  GameRendererInputHandler get inputHandler;
  bool get rendererInputReady;
  void clearRendererHoverIntent();
  void syncRendererHoverAt(Vector2 position);

  @override
  void handleViewportLongPressStart(Vector2 position) {
    _pendingViewportPointerMoves.clear();
    inputHandler.start(
      position,
      isReady: rendererInputReady,
      isDragging: isDragging,
      hasMultiplePointers: hasMultipleViewportPointers,
      tileAtPosition: tileDataAtWidgetPosition,
      anchorForTile: inspectionAnchorForTile,
    );
  }

  @override
  void handleViewportLongPressMoveUpdate(Vector2 position) {
    inputHandler.update(position, tileAtPosition: tileDataAtWidgetPosition);
  }

  @override
  void handleViewportLongPressUp() {
    inputHandler.confirm();
    clearRendererHoverIntent();
  }

  @override
  void handleViewportLongPressEnd(Vector2 position) {
    inputHandler.confirm();
    clearRendererHoverIntent();
  }

  @override
  void handleViewportLongPressCancel() {
    inputHandler.cancel();
    clearRendererHoverIntent();
  }

  @override
  void handleViewportPointerDown(int pointerId, Vector2 position) {
    _pendingViewportPointerMoves.remove(pointerId);
    final hadActiveInspection = inputHandler.isActive;
    if (hadActiveInspection) inputHandler.cancel();
    inputHandler.suppressTapsUntilNextPointerDown = hadActiveInspection;
    super.handleViewportPointerDown(
      pointerId,
      worldInputPointForWidget(position),
    );
    syncRendererHoverAt(position);
  }

  @override
  void handleViewportPointerMove(int pointerId, Vector2 position) {
    if (inputHandler.isActive) {
      inputHandler.update(position, tileAtPosition: tileDataAtWidgetPosition);
      return;
    }
    final pending = _pendingViewportPointerMoves[pointerId];
    if (pending == null) {
      _pendingViewportPointerMoves[pointerId] = position.clone();
    } else {
      pending.setFrom(position);
    }
  }

  @override
  void flushPendingViewportPointerMoves() {
    if (_pendingViewportPointerMoves.isEmpty) return;
    final pending = _pendingViewportPointerMoves.entries.toList(
      growable: false,
    );
    _pendingViewportPointerMoves.clear();
    _viewportPointerMoveFlushCount++;
    for (final entry in pending) {
      _processViewportPointerMove(entry.key, entry.value);
    }
  }

  void _processViewportPointerMove(int pointerId, Vector2 position) {
    final wasDragging = isDragging;
    super.handleViewportPointerMove(
      pointerId,
      worldInputPointForWidget(position),
    );
    if (isDragging || hasMultipleViewportPointers) {
      if (!wasDragging || hasMultipleViewportPointers) {
        clearRendererHoverIntent();
      }
      return;
    }
    syncRendererHoverAt(position);
  }

  void _flushPendingViewportPointerMove(int pointerId) {
    final position = _pendingViewportPointerMoves.remove(pointerId);
    if (position == null) return;
    _viewportPointerMoveFlushCount++;
    _processViewportPointerMove(pointerId, position);
  }

  @override
  void handleViewportPointerUp(int pointerId) {
    _flushPendingViewportPointerMove(pointerId);
    inputHandler.confirm();
    super.handleViewportPointerUp(pointerId);
    clearRendererHoverIntent();
  }

  @override
  void handleViewportPointerCancel(int pointerId) {
    _pendingViewportPointerMoves.remove(pointerId);
    inputHandler.cancel();
    super.handleViewportPointerCancel(pointerId);
    clearRendererHoverIntent();
  }

  @override
  void handleViewportPointerHover(Vector2 position) {
    syncRendererHoverAt(position);
  }

  @override
  void handleViewportPointerExit() => clearRendererHoverIntent();

  @override
  void handleViewportPanZoomStart(Vector2 focalPoint) {
    inputHandler.cancel();
    super.handleViewportPanZoomStart(worldInputPointForWidget(focalPoint));
    clearRendererHoverIntent();
  }

  @override
  void handleViewportPanZoomUpdate({
    required Vector2 panDelta,
    required double scale,
    required Vector2 focalPoint,
  }) {
    inputHandler.cancel();
    final inputFocalPoint = worldInputPointForWidget(focalPoint);
    final previous = worldInputPointForWidget(focalPoint - panDelta);
    super.handleViewportPanZoomUpdate(
      panDelta: inputFocalPoint - previous,
      scale: scale,
      focalPoint: inputFocalPoint,
    );
    clearRendererHoverIntent();
  }

  @override
  void handleViewportPanZoomEnd() {
    super.handleViewportPanZoomEnd();
    clearRendererHoverIntent();
  }

  WorldTile? tileDataAtWidgetPosition(Vector2 widgetPosition) {
    if (!rendererInputReady) return null;
    final inputPosition = worldInputPointForWidget(widgetPosition);
    final worldPoint = camera.globalToLocal(inputPosition);
    return grid.tileDataAtWorldPoint(worldPoint);
  }

  @visibleForTesting
  WorldTile? tileDataAtWidgetPositionForTesting(Vector2 widgetPosition) =>
      tileDataAtWidgetPosition(widgetPosition);

  @visibleForTesting
  int get pendingViewportPointerMoveCountForTesting =>
      _pendingViewportPointerMoves.length;

  @visibleForTesting
  int get viewportPointerMoveFlushCountForTesting =>
      _viewportPointerMoveFlushCount;

  Offset inspectionAnchorForTile(WorldTile tile, {Vector2? fallback}) {
    if (!rendererInputReady) {
      return Offset(fallback?.x ?? 0, fallback?.y ?? 0);
    }
    final tileCenter = HexGeometry.tilePosition(
      col: tile.col,
      row: tile.row,
      hexRadius: grid.config.hexRadius,
    );
    final worldPoint = Vector2(
      tileCenter.x,
      tileCenter.y * HexGrid.perspectiveY - 16,
    );
    final viewport =
        (worldPoint - camera.viewfinder.position) * camera.viewfinder.zoom;
    final projected = worldOutputPointForWidget(viewport);
    return Offset(projected.x, projected.y);
  }

  HexGrid get grid;
}
