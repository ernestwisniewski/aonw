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

typedef HexSelectionPaletteRequest =
    void Function(WorldTile tile, {required Offset anchor});

/// Owns the long-press gesture lifecycle and requests the contextual
/// selection palette after resolving a visible map tile.
final class GameRendererInputHandler {
  GameRendererInputHandler({
    required GameClientState Function() state,
    required Future<void> Function(GameIntent intent) onCommand,
    required void Function() clearHover,
    required void Function(WorldTile tile, {bool forceInspect}) syncHover,
    required void Function(Vector2? position) setHoverPosition,
    required HexSelectionPaletteRequest openSelectionPalette,
    required VoidCallback closeSelectionPalette,
  }) : _state = state,
       _onCommand = onCommand,
       _clearHover = clearHover,
       _syncHover = syncHover,
       _setHoverPosition = setHoverPosition,
       _openSelectionPalette = openSelectionPalette,
       _closeSelectionPalette = closeSelectionPalette;

  final GameClientState Function() _state;
  final Future<void> Function(GameIntent intent) _onCommand;
  final void Function() _clearHover;
  final void Function(WorldTile tile, {bool forceInspect}) _syncHover;
  final void Function(Vector2? position) _setHoverPosition;
  final HexSelectionPaletteRequest _openSelectionPalette;
  final VoidCallback _closeSelectionPalette;

  bool _active = false;
  bool suppressTapsUntilNextPointerDown = false;
  CityHex? _pressedHex;

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
    return openForTile(
      tile,
      widgetPosition: widgetPosition,
      anchor: anchorForTile(tile, fallback: widgetPosition),
    );
  }

  bool openForTile(WorldTile tile, {Vector2? widgetPosition, Offset? anchor}) {
    suppressTapsUntilNextPointerDown = true;
    if (_cancelMoveTargeting()) return true;
    if (!_canInspect(tile)) {
      _clearHover();
      return false;
    }

    final pressedHex = CityHex(col: tile.col, row: tile.row);
    if (_active && _pressedHex == pressedHex) {
      _rememberHover(widgetPosition);
      _syncHover(tile, forceInspect: true);
      return true;
    }

    _active = true;
    _pressedHex = pressedHex;
    _rememberHover(widgetPosition);
    _syncHover(tile, forceInspect: true);
    _openSelectionPalette(
      tile,
      anchor: anchor ?? Offset(widgetPosition?.x ?? 0, widgetPosition?.y ?? 0),
    );
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

  void finish() {
    if (!_active) return;
    _clearGesture();
  }

  void cancel() {
    if (!_active) return;
    _clearGesture();
    _closeSelectionPalette();
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
    final pressedHex = _pressedHex;
    return pressedHex != null &&
        tile != null &&
        tile.col == pressedHex.col &&
        tile.row == pressedHex.row;
  }

  void _rememberHover(Vector2? position) {
    if (position != null) _setHoverPosition(position.clone());
  }

  void _clearGesture() {
    _active = false;
    _pressedHex = null;
    suppressTapsUntilNextPointerDown = true;
  }
}

/// Thin Flame adapter; all mutable long-press policy lives in the handler.
mixin GameRendererInputAdapter on HexWorld, HexInputBehavior {
  final Map<int, Vector2> _pendingViewportPointerMoves = {};
  int _viewportPointerMoveFlushCount = 0;

  GameRendererInputHandler get inputHandler;
  bool get rendererInputReady;
  void clearRendererHoverIntent();
  void syncRendererHoverAt(Vector2 position);
  void clearRendererHexSelectionPalette();

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
    inputHandler.finish();
    clearRendererHoverIntent();
  }

  @override
  void handleViewportLongPressEnd(Vector2 position) {
    inputHandler.finish();
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
    final hadActiveLongPress = inputHandler.isActive;
    if (hadActiveLongPress) inputHandler.cancel();
    inputHandler.suppressTapsUntilNextPointerDown = hadActiveLongPress;
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
      clearRendererHexSelectionPalette();
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
    inputHandler.finish();
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
    clearRendererHexSelectionPalette();
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
