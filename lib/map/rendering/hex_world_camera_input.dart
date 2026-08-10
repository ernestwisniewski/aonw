part of 'hex_world.dart';

extension _HexWorldCameraInput on HexWorld {
  void _startViewportPinch() {
    _pinchStartZoom = _effectiveCameraZoom();
    _pinchStartDistance = _currentViewportPinchDistance();
    final focus = _currentViewportPinchFocus();
    _pinchStartWorldFocus = focus == null
        ? null
        : _effectiveViewportToWorld(focus);
  }

  void _updateViewportPinch() {
    if (_pinchStartDistance < 1.0) return;
    final current = _currentViewportPinchDistance();
    if (current < 1.0) return;
    final focus = _currentViewportPinchFocus();
    if (focus == null) return;
    _queueZoomKeepingWorldPoint(
      zoom: _pinchStartZoom * (current / _pinchStartDistance),
      focalPoint: focus,
      worldPoint: _pinchStartWorldFocus ?? viewportToWorld(focus),
    );
  }

  double _currentViewportPinchDistance() {
    final positions = _viewportPointers.values.take(2).toList();
    if (positions.length < 2) return 0.0;
    final dx = positions[0].x - positions[1].x;
    final dy = positions[0].y - positions[1].y;
    return math.sqrt(dx * dx + dy * dy);
  }

  Vector2? _currentViewportPinchFocus() {
    final positions = _viewportPointers.values.take(2).toList();
    if (positions.length < 2) return null;
    return (positions[0] + positions[1]) / 2;
  }

  void _queuePanByScreenDelta(Vector2 screenDelta) {
    final state = _queuedCameraState();
    state.position -= screenDelta / state.zoom;
  }

  void _queueZoomAround(double zoom, Vector2 focalPoint) {
    _queueZoomKeepingWorldPoint(
      zoom: zoom,
      focalPoint: focalPoint,
      worldPoint: _effectiveViewportToWorld(focalPoint),
    );
  }

  void _queueZoomKeepingWorldPoint({
    required double zoom,
    required Vector2 focalPoint,
    required Vector2 worldPoint,
  }) {
    final clampedZoom = zoom
        .clamp(CameraController.minZoom, CameraController.maxZoom)
        .toDouble();
    _queuedCameraState()
      ..zoom = clampedZoom
      ..position = worldPoint - focalPoint / clampedZoom;
  }

  void _flushQueuedViewportCameraInput() {
    final state = _queuedViewportCameraState;
    if (state == null) return;

    _queuedViewportCameraState = null;

    final currentZoom = camera.viewfinder.zoom;
    final zoomChanged = (state.zoom - currentZoom).abs() > 0.0000001;
    if (zoomChanged) {
      setZoom(state.zoom);
      camera.viewfinder.position = state.position;
      return;
    }

    final screenDelta =
        (camera.viewfinder.position - state.position) * state.zoom;
    if (screenDelta.length > 0) {
      panByScreenDelta(screenDelta);
    }
  }

  _QueuedViewportCameraState _queuedCameraState() {
    return _queuedViewportCameraState ??= _QueuedViewportCameraState(
      zoom: camera.viewfinder.zoom,
      position: camera.viewfinder.position.clone(),
    );
  }

  double _effectiveCameraZoom() =>
      _queuedViewportCameraState?.zoom ?? camera.viewfinder.zoom;

  Vector2 _effectiveCameraPosition() {
    return _queuedViewportCameraState?.position.clone() ??
        camera.viewfinder.position.clone();
  }

  Vector2 _effectiveViewportToWorld(Vector2 viewportPoint) {
    return _effectiveCameraPosition() + viewportPoint / _effectiveCameraZoom();
  }
}

class _QueuedViewportCameraState {
  double zoom;
  Vector2 position;

  _QueuedViewportCameraState({required this.zoom, required this.position});
}
