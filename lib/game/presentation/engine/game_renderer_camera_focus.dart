part of 'game_renderer.dart';

extension GameRendererCameraFocus on GameRenderer {
  bool followPlayerCamera(String playerId, {bool immediate = false}) {
    if (_isDisposed || !_isReady || playerId.isEmpty) return false;
    final focusPoint = _playerCameraFocusPoint(playerId);
    if (focusPoint == null) {
      _cameraController.stopFollowingWorldPoint();
      return false;
    }
    if (immediate) {
      _cameraController.centerOnWorldPoint(focusPoint);
    }
    _cameraController.followWorldPoint(() => _playerCameraFocusPoint(playerId));
    return true;
  }

  void stopFollowingCameraTarget() {
    if (_isDisposed || !_isReady) return;
    _cameraController.stopFollowingWorldPoint();
  }

  void _focusInitialActivePlayer() {
    if (!focusActivePlayerOnFirstState || _didFocusInitialPlayer) return;
    final playerId = _renderState.activePlayerId;
    if (playerId.isEmpty || playerId == GameRenderer._loadingPlayerId) return;

    for (final unit in _renderState.units) {
      if (unit.ownerPlayerId == playerId) {
        _focusInitialPoint(
          UnitMarkerLayer.worldPositionFor(
            unit.col,
            unit.row,
            onCity: _unitIsOnKnownCity(unit),
          ),
        );
        return;
      }
    }
    for (final city in _renderState.cities) {
      if (city.ownerPlayerId == playerId) {
        _focusInitialPoint(
          CityMarkerLayer.worldPositionFor(city.center.col, city.center.row),
        );
        return;
      }
    }
    _markInitialCameraFocusReady();
  }

  void _focusInitialPoint(Vector2 worldPoint) {
    _cameraController.centerOnWorldPoint(worldPoint);
    _didFocusInitialPlayer = true;
    if (_cameraViewportReady) {
      _deferredInitialFocusPoint = null;
      _markInitialCameraFocusReady();
    } else {
      _deferredInitialFocusPoint = worldPoint;
    }
  }

  void _applyDeferredInitialFocusIfReady() {
    final worldPoint = _deferredInitialFocusPoint;
    if (worldPoint == null || !_cameraViewportReady) return;
    _deferredInitialFocusPoint = null;
    _cameraController.centerOnWorldPoint(worldPoint);
    _markInitialCameraFocusReady();
  }

  bool get _cameraViewportReady {
    final size = camera.viewport.size;
    return size.x > 0 && size.y > 0;
  }

  void _markInitialCameraFocusReady() {
    if (_initialCameraFocusReadyNotifier.value) return;
    _initialCameraFocusReadyNotifier.value = true;
  }

  void _focusActiveSelection() {
    final selection = _renderState.selection;
    final key = _selectionFocusKey(selection);
    if (!_didPrimeSelectionFocus) {
      _lastFocusedSelectionKey = key;
      _didPrimeSelectionFocus = true;
      return;
    }

    if (key == null) {
      _lastFocusedSelectionKey = null;
      return;
    }
    if (_lastFocusedSelectionKey == key) return;

    if (_focusSelection(selection)) {
      _lastFocusedSelectionKey = key;
    }
  }

  String? _selectionFocusKey(GameSelection? selection) {
    return switch (selection?.type) {
      GameSelectionType.unit =>
        selection?.unit == null ? null : 'unit:${selection!.unit!.id}',
      GameSelectionType.city =>
        selection?.city == null ? null : 'city:${selection!.city!.id}',
      GameSelectionType.fieldImprovement ||
      GameSelectionType.tile ||
      null => null,
    };
  }

  bool _focusSelection(GameSelection? selection) {
    switch (selection?.type) {
      case GameSelectionType.unit:
        final unit = _renderState.selectedUnit ?? selection?.unit;
        if (unit == null) return false;
        _focusUnit(unit);
        return true;
      case GameSelectionType.city:
        final city = selection?.city;
        if (city == null) return false;
        _focusCity(city);
        return true;
      case GameSelectionType.fieldImprovement || GameSelectionType.tile || null:
        return false;
    }
  }

  void _focusUnit(GameUnit unit) {
    if (!MapFocusVisibility.canFocusUnit(_renderState, unit)) return;
    unawaited(
      _cameraController.smoothCenterOnWorldPoint(
        duration: GameRenderer._selectionCameraTransitionDuration,
        _selectedUnitWorldPosition(unit),
      ),
    );
  }

  Vector2 _selectedUnitWorldPosition(GameUnit unit) {
    return UnitMarkerLayer.worldPositionFor(
      unit.col,
      unit.row,
      onCity: _unitIsOnKnownCity(unit),
    );
  }

  bool _unitIsOnKnownCity(GameUnit unit) {
    return _renderState.citiesKnownToActivePlayer.any(
      (city) => city.occupiesCenter(unit.col, unit.row),
    );
  }

  Vector2? _playerCameraFocusPoint(String playerId) {
    for (final unit in _renderState.units) {
      if (unit.ownerPlayerId == playerId) {
        return _selectedUnitWorldPosition(unit);
      }
    }
    for (final city in _renderState.cities) {
      if (city.ownerPlayerId == playerId) {
        return CityMarkerLayer.worldPositionFor(
          city.center.col,
          city.center.row,
        );
      }
    }
    return null;
  }

  void _focusCity(GameCity city) {
    if (!MapFocusVisibility.canFocusCity(_renderState, city)) return;
    unawaited(
      _cameraController.smoothCenterOnWorldPoint(
        duration: GameRenderer._selectionCameraTransitionDuration,
        CityMarkerLayer.worldPositionFor(city.center.col, city.center.row),
      ),
    );
  }

  bool _canAutoFocusMapTarget(int col, int row) {
    return MapFocusVisibility.canAutoFocusAt(_renderState, col, row);
  }
}
