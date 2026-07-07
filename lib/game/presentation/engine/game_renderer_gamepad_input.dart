part of 'game_renderer.dart';

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

  void applyGamepadAnalogFrame(GamepadControlFrame frame, double dt) {
    if (!_isReady || _isDisposed || !_hasAnalogInput(frame)) return;
    _applyGamepadCameraInput(frame, dt);
  }

  void moveGamepadCursor(GamepadMapDirection direction) {
    if (!_isReady || _isDisposed) return;
    _moveGamepadCursor(direction);
  }

  void confirmGamepadCursor() {
    if (!_isReady || _isDisposed) return;
    final currentTile = _currentGamepadTile();
    _dispatchGamepadCommands(
      const GamepadControlFrame(confirmPressed: true),
      currentTile: currentTile,
    );
  }

  void cancelGamepadAction() {
    _dispatchGamepadCommands(const GamepadControlFrame(cancelPressed: true));
  }

  void inspectGamepadCursor() {
    if (!_isReady || _isDisposed) return;
    final currentTile = _currentGamepadTile();
    if (currentTile != null) _handleTileInspected(currentTile);
  }

  void toggleGamepadMoveMode() {
    _dispatchGamepadCommands(const GamepadControlFrame(moveModePressed: true));
  }

  void focusPreviousGamepadAction() {
    _dispatchGamepadCommands(
      const GamepadControlFrame(focusPreviousPressed: true),
    );
  }

  void focusNextGamepadAction() {
    _dispatchGamepadCommands(const GamepadControlFrame(focusNextPressed: true));
  }

  bool _hasAnalogInput(GamepadControlFrame frame) {
    return frame.cameraX != 0 || frame.cameraY != 0 || frame.zoom != 0;
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
    _applyAnalogCameraInput(
      panX: frame.cameraX,
      panY: frame.cameraY,
      zoom: frame.zoom,
      dt: dt,
    );
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
      panByScreenDelta(panDelta);
    }

    if (zoom == 0 || size.x <= 0 || size.y <= 0) return;
    final center = Vector2(size.x / 2, size.y / 2);
    final scale = 1 + zoom * _zoomSpeed * dt;
    setZoomAround(camera.viewfinder.zoom * scale, center);
  }

  void _moveGamepadCursor(GamepadMapDirection direction) {
    final current = _currentGamepadCursorHex();
    if (current == null) return;
    final tile = _nextCursorTile(current, direction);
    if (tile == null) return;

    _gamepadCursorHex = CityHex(col: tile.col, row: tile.row);
    _syncGamepadCursorTile(tile);
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

  void _dispatchGamepadCommands(
    GamepadControlFrame frame, {
    TileData? currentTile,
  }) {
    if (!_isReady || _isDisposed) return;
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
}
