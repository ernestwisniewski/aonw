part of 'game_renderer.dart';

/// Public camera bridge and camera-related renderer preferences.
mixin GameRendererCamera on HexWorld {
  GameRenderer get _cameraRenderer => this as GameRenderer;

  double get defaultZoom => _cameraRenderer.mapData.defaultZoom;

  @override
  void setZoom(double zoom) {
    _cameraRenderer._setFastCameraRendering(true);
    super.setZoom(zoom);
    _cameraRenderer._publishZoom();
    if (!_cameraRenderer._isReady) return;
    _cameraRenderer._syncMarkerDensityForZoom();
  }

  @override
  void panByScreenDelta(Vector2 screenDelta) {
    _cameraRenderer._setFastCameraRendering(true);
    super.panByScreenDelta(screenDelta);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final renderer = _cameraRenderer;
    if (!renderer._isReady || renderer._isDisposed) return;
    renderer
      .._applyDeferredInitialFocusIfReady()
      .._syncMarkerDensityForZoom(force: true);
  }

  bool get moveCameraForUnitMovement =>
      _cameraRenderer._moveCameraForUnitMovement;

  set moveCameraForUnitMovement(bool value) {
    final renderer = _cameraRenderer;
    if (renderer._moveCameraForUnitMovement == value) return;
    renderer._moveCameraForUnitMovement = value;
  }

  bool get followUnitMovementCamera =>
      _cameraRenderer._followUnitMovementCamera;

  set followUnitMovementCamera(bool value) {
    final renderer = _cameraRenderer;
    if (renderer._followUnitMovementCamera == value) return;
    renderer._followUnitMovementCamera = value;
  }

  bool get followEnemyUnitCamera => _cameraRenderer._followEnemyUnitCamera;

  set followEnemyUnitCamera(bool value) {
    final renderer = _cameraRenderer;
    if (renderer._followEnemyUnitCamera != value) {
      renderer._followEnemyUnitCamera = value;
    }
  }

  bool get cinematicCameraEnabled => _cameraRenderer._cinematicCameraEnabled;

  set cinematicCameraEnabled(bool value) {
    final renderer = _cameraRenderer;
    if (renderer._cinematicCameraEnabled == value) return;
    renderer
      .._cinematicCameraEnabled = value
      .._lastSyncedHoverHex = null
      .._refreshHoverIntent();
  }

  @override
  WorldProjection get worldProjection => _cameraRenderer._cinematicCameraEnabled
      ? GameRenderer._roundEarthProjection
      : WorldProjection.disabled;
}
