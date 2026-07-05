part of 'game_renderer.dart';

final Expando<GamepadInputSnapshot> _gamepadInputSnapshots =
    Expando<GamepadInputSnapshot>('GameRenderer.gamepadInputSnapshot');
final Expando<GamepadFrameController> _gamepadFrameControllers =
    Expando<GamepadFrameController>('GameRenderer.gamepadFrameController');
final Expando<CityHex> _gamepadCursorHexes = Expando<CityHex>(
  'GameRenderer.gamepadCursorHex',
);
const String _noGamepadCursorSelectionKey = '__none__';
final Expando<String> _gamepadCursorSelectionKeys = Expando<String>(
  'GameRenderer.gamepadCursorSelectionKey',
);

extension GameRendererGamepadInput on GameRenderer {
  static const double _cameraPanSpeed = 520.0;
  static const double _zoomSpeed = 1.35;

  set gamepadInput(GamepadInputSnapshot input) {
    _gamepadInputSnapshots[this] = input;
  }

  void _updateGamepadInput(double dt) {
    if (!_isReady || _isDisposed) return;
    final frame = _gamepadFrameController.advance(input: _gamepadInput, dt: dt);
    _applyGamepadCameraInput(frame, dt);
    _applyGamepadCursorInput(frame);
    _applyGamepadButtonInput(frame);
  }

  GamepadInputSnapshot get _gamepadInput =>
      _gamepadInputSnapshots[this] ?? GamepadInputSnapshot.empty;

  GamepadFrameController get _gamepadFrameController {
    return _gamepadFrameControllers[this] ??= GamepadFrameController();
  }

  CityHex? get _gamepadCursorHex => _gamepadCursorHexes[this];

  set _gamepadCursorHex(CityHex? value) {
    _gamepadCursorHexes[this] = value;
  }

  String? get _gamepadCursorSelectionKey {
    final key = _gamepadCursorSelectionKeys[this];
    return key == _noGamepadCursorSelectionKey ? null : key;
  }

  set _gamepadCursorSelectionKey(String? value) {
    _gamepadCursorSelectionKeys[this] = value ?? _noGamepadCursorSelectionKey;
  }

  void _applyGamepadCameraInput(GamepadControlFrame frame, double dt) {
    final panDelta = Vector2(
      frame.cameraX * _cameraPanSpeed * dt,
      -frame.cameraY * _cameraPanSpeed * dt,
    );
    if (panDelta.x != 0 || panDelta.y != 0) {
      panByScreenDelta(panDelta);
    }

    if (frame.zoom == 0 || size.x <= 0 || size.y <= 0) return;
    final center = Vector2(size.x / 2, size.y / 2);
    final scale = 1 + frame.zoom * _zoomSpeed * dt;
    setZoomAround(camera.viewfinder.zoom * scale, center);
  }

  void _applyGamepadCursorInput(GamepadControlFrame frame) {
    final direction = frame.cursorStep;
    if (direction == null) return;

    final current = _currentGamepadCursorHex();
    if (current == null) return;
    final tile = _nextCursorTile(current, direction);
    if (tile == null) return;

    _gamepadCursorHex = CityHex(col: tile.col, row: tile.row);
    _syncGamepadCursorTile(tile);
    _focusGamepadCursor(tile);
  }

  void _syncGamepadCursorTile(TileData tile) {
    if (_gamepadCursorShouldSelectTile) {
      unawaited(onCommand(SelectTileCommand(tile.col, tile.row)));
      return;
    }
    _syncHoverIntentForTile(tile);
  }

  bool get _gamepadCursorShouldSelectTile {
    return _renderState.interactionMode == GameInteractionMode.standard;
  }

  void _applyGamepadButtonInput(GamepadControlFrame frame) {
    final currentTile = frame.inspectPressed || frame.confirmPressed
        ? _currentGamepadTile()
        : null;
    if (frame.inspectPressed) {
      if (currentTile != null) _handleTileInspected(currentTile);
    }
    final commands = const GamepadCommandMapper().commandsForFrame(
      frame: frame,
      state: _renderState,
      currentTile: currentTile,
    );
    for (final command in commands) {
      unawaited(onCommand(command));
    }
  }

  CityHex? _currentGamepadCursorHex() {
    final selectionHex = _selectionHex();
    final selectionKey = _selectionCursorKey();
    if (selectionHex != null && selectionKey != _gamepadCursorSelectionKey) {
      _gamepadCursorSelectionKey = selectionKey;
      _gamepadCursorHex = selectionHex;
      return selectionHex;
    }

    final cursor = _gamepadCursorHex;
    if (cursor != null && mapData.tileAt(cursor.col, cursor.row) != null) {
      return cursor;
    }
    if (selectionHex != null) {
      _gamepadCursorSelectionKey = selectionKey;
      _gamepadCursorHex = selectionHex;
      return selectionHex;
    }
    final fromViewport = _viewportCenterHex();
    if (fromViewport != null) {
      _gamepadCursorSelectionKey = null;
      _gamepadCursorHex = fromViewport;
      return fromViewport;
    }
    final first = mapData.tiles.isEmpty ? null : mapData.tiles.first;
    if (first == null) return null;
    final fallback = CityHex(col: first.col, row: first.row);
    _gamepadCursorSelectionKey = null;
    _gamepadCursorHex = fallback;
    return fallback;
  }

  TileData? _currentGamepadTile() {
    final cursor = _currentGamepadCursorHex();
    if (cursor == null) return null;
    return mapData.tileAt(cursor.col, cursor.row);
  }

  CityHex? _selectionHex() {
    final selection = _renderState.selection;
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
    final selection = _renderState.selection;
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
    if (size.x <= 0 || size.y <= 0) return null;
    final center = Vector2(size.x / 2, size.y / 2);
    final tile = _sceneBuilder.grid.tileDataAtWorldPoint(
      camera.globalToLocal(center),
    );
    if (tile == null) return null;
    return CityHex(col: tile.col, row: tile.row);
  }

  TileData? _nextCursorTile(CityHex current, GamepadMapDirection direction) {
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

  void _focusGamepadCursor(TileData tile) {
    final position = HexGeometry.tilePosition(
      col: tile.col,
      row: tile.row,
      hexRadius: _sceneBuilder.grid.config.hexRadius,
    );
    final worldPoint = Vector2(position.x, position.y * HexGrid.perspectiveY);
    unawaited(
      _cameraController.smoothCenterOnWorldPoint(worldPoint, duration: 0.16),
    );
  }
}
