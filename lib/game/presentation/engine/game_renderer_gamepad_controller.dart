import 'dart:async';

import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:flame/components.dart';

final class GameRendererGamepadController {
  GameRendererGamepadController({
    required this.mapData,
    required GameClientState Function() state,
    required bool Function() isReady,
    required bool Function() isDisposed,
    required Vector2 Function() viewportSize,
    required WorldTile? Function(Vector2 point) tileAtViewportPoint,
    required double Function() currentZoom,
    required void Function(Vector2 delta) panByScreenDelta,
    required void Function(double zoom, Vector2 focalPoint) setZoomAround,
    required void Function(WorldTile tile) inspectTile,
    required void Function(WorldTile tile) syncHoverIntent,
    required Future<void> Function(GameIntent intent) onCommand,
  }) : _state = state,
       _isReady = isReady,
       _isDisposed = isDisposed,
       _viewportSize = viewportSize,
       _tileAtViewportPoint = tileAtViewportPoint,
       _currentZoom = currentZoom,
       _panByScreenDelta = panByScreenDelta,
       _setZoomAround = setZoomAround,
       _inspectTile = inspectTile,
       _syncHoverIntent = syncHoverIntent,
       _onCommand = onCommand;

  static const double _cameraPanSpeed = 520.0;
  static const double _zoomSpeed = 1.35;

  final WorldMap mapData;
  final GameClientState Function() _state;
  final bool Function() _isReady;
  final bool Function() _isDisposed;
  final Vector2 Function() _viewportSize;
  final WorldTile? Function(Vector2 point) _tileAtViewportPoint;
  final double Function() _currentZoom;
  final void Function(Vector2 delta) _panByScreenDelta;
  final void Function(double zoom, Vector2 focalPoint) _setZoomAround;
  final void Function(WorldTile tile) _inspectTile;
  final void Function(WorldTile tile) _syncHoverIntent;
  final Future<void> Function(GameIntent intent) _onCommand;

  CityHex? _cursorHex;
  String? _cursorSelectionKey;

  void applyAnalogFrame(GamepadControlFrame frame, double dt) {
    if (!_isAvailable || !_hasAnalogInput(frame)) return;
    _applyAnalogCameraInput(
      panX: frame.cameraX,
      panY: frame.cameraY,
      zoom: frame.zoom,
      dt: dt,
    );
  }

  void moveCursor(GamepadMapDirection direction) {
    if (!_isAvailable) return;
    final current = _currentCursorHex();
    if (current == null) return;
    final tile = _nextCursorTile(current, direction);
    if (tile == null) return;

    _cursorHex = CityHex(col: tile.col, row: tile.row);
    _syncCursorTile(tile);
  }

  void confirmCursor() {
    if (!_isAvailable) return;
    _dispatchCommands(
      const GamepadControlFrame(confirmPressed: true),
      currentTile: _currentCursorTile(),
    );
  }

  void cancelAction() {
    _dispatchCommands(const GamepadControlFrame(cancelPressed: true));
  }

  void inspectCursor() {
    if (!_isAvailable) return;
    final currentTile = _currentCursorTile();
    if (currentTile != null) _inspectTile(currentTile);
  }

  void toggleMoveMode() {
    _dispatchCommands(const GamepadControlFrame(moveModePressed: true));
  }

  void focusPreviousAction() {
    _dispatchCommands(const GamepadControlFrame(focusPreviousPressed: true));
  }

  void focusNextAction() {
    _dispatchCommands(const GamepadControlFrame(focusNextPressed: true));
  }

  bool get _isAvailable => _isReady() && !_isDisposed();

  bool _hasAnalogInput(GamepadControlFrame frame) {
    return frame.cameraX != 0 || frame.cameraY != 0 || frame.zoom != 0;
  }

  void _applyAnalogCameraInput({
    required double panX,
    required double panY,
    required double zoom,
    required double dt,
  }) {
    final panDelta = Vector2(
      panX * _cameraPanSpeed * dt,
      -panY * _cameraPanSpeed * dt,
    );
    if (panDelta.x != 0 || panDelta.y != 0) {
      _panByScreenDelta(panDelta);
    }

    final size = _viewportSize();
    if (zoom == 0 || size.x <= 0 || size.y <= 0) return;
    final center = Vector2(size.x / 2, size.y / 2);
    final scale = 1 + zoom * _zoomSpeed * dt;
    _setZoomAround(_currentZoom() * scale, center);
  }

  void _syncCursorTile(WorldTile tile) {
    if (_state().interactionMode == GameInteractionMode.standard) {
      unawaited(_onCommand(SelectTileCommand(tile.col, tile.row)));
      return;
    }
    _syncHoverIntent(tile);
  }

  void _dispatchCommands(GamepadControlFrame frame, {WorldTile? currentTile}) {
    if (!_isAvailable) return;
    final commands = const GamepadCommandMapper().commandsForFrame(
      frame: frame,
      state: _state(),
      currentTile: currentTile,
    );
    for (final command in commands) {
      unawaited(_onCommand(command));
    }
  }

  CityHex? _currentCursorHex() {
    final selectionHex = _selectionHex();
    final selectionKey = _selectionCursorKey();
    if (selectionHex != null && selectionKey != _cursorSelectionKey) {
      _cursorSelectionKey = selectionKey;
      _cursorHex = selectionHex;
      return selectionHex;
    }

    final cursor = _cursorHex;
    if (cursor != null && mapData.tileAt(cursor.col, cursor.row) != null) {
      return cursor;
    }
    if (selectionHex != null) {
      _cursorSelectionKey = selectionKey;
      _cursorHex = selectionHex;
      return selectionHex;
    }
    final fromViewport = _viewportCenterHex();
    if (fromViewport != null) {
      _cursorSelectionKey = null;
      _cursorHex = fromViewport;
      return fromViewport;
    }
    final first = mapData.tiles.isEmpty ? null : mapData.tiles.first;
    if (first == null) return null;
    final fallback = CityHex(col: first.col, row: first.row);
    _cursorSelectionKey = null;
    _cursorHex = fallback;
    return fallback;
  }

  WorldTile? _currentCursorTile() {
    final cursor = _currentCursorHex();
    if (cursor == null) return null;
    return mapData.tileAt(cursor.col, cursor.row);
  }

  CityHex? _selectionHex() {
    final selection = _state().selection;
    return switch (selection?.type) {
      GameSelectionType.unit when selection?.unit != null => CityHex(
        col: selection!.unit!.col,
        row: selection.unit!.row,
      ),
      GameSelectionType.city when selection?.city != null =>
        selection!.city!.center,
      GameSelectionType.tile || GameSelectionType.fieldImprovement
          when selection?.tile != null =>
        CityHex(col: selection!.tile!.col, row: selection.tile!.row),
      _ => null,
    };
  }

  String? _selectionCursorKey() {
    final selection = _state().selection;
    return switch (selection?.type) {
      GameSelectionType.unit when selection?.unit != null =>
        'unit:${selection!.unit!.id}:${selection.unit!.col}:${selection.unit!.row}',
      GameSelectionType.city when selection?.city != null =>
        'city:${selection!.city!.id}:${selection.city!.center.col}:${selection.city!.center.row}',
      GameSelectionType.tile when selection?.tile != null =>
        'tile:${selection!.tile!.col}:${selection.tile!.row}',
      GameSelectionType.fieldImprovement when selection?.tile != null =>
        'improvement:${selection!.tile!.col}:${selection.tile!.row}',
      _ => null,
    };
  }

  CityHex? _viewportCenterHex() {
    final size = _viewportSize();
    if (size.x <= 0 || size.y <= 0) return null;
    final tile = _tileAtViewportPoint(Vector2(size.x / 2, size.y / 2));
    if (tile == null) return null;
    return CityHex(col: tile.col, row: tile.row);
  }

  WorldTile? _nextCursorTile(CityHex current, GamepadMapDirection direction) {
    var candidate = current;
    final maxSteps = mapData.cols + mapData.rows;
    for (var step = 0; step < maxSteps; step += 1) {
      candidate = _stepCursor(candidate, direction);
      final tile = mapData.tileAt(candidate.col, candidate.row);
      if (tile != null) return tile;
      if (_cursorOutOfBounds(candidate)) return null;
    }
    return null;
  }

  CityHex _stepCursor(CityHex current, GamepadMapDirection direction) {
    return switch (direction) {
      GamepadMapDirection.up => CityHex(col: current.col, row: current.row - 1),
      GamepadMapDirection.down => CityHex(
        col: current.col,
        row: current.row + 1,
      ),
      GamepadMapDirection.left => CityHex(
        col: current.col - 1,
        row: current.row,
      ),
      GamepadMapDirection.right => CityHex(
        col: current.col + 1,
        row: current.row,
      ),
    };
  }

  bool _cursorOutOfBounds(CityHex cursor) {
    return cursor.col < 0 ||
        cursor.row < 0 ||
        cursor.col >= mapData.cols ||
        cursor.row >= mapData.rows;
  }
}
