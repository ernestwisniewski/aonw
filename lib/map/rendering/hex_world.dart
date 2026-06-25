import 'dart:math' as math;
import 'dart:typed_data';

import 'package:aonw/map/rendering/map_palette.dart';
import 'package:aonw/map/rendering/world_projection.dart';
import 'package:aonw/shared/input/camera_controller.dart';
import 'package:aonw/shared/performance/dev_performance.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' hide Matrix4;

abstract class HexWorld extends FlameGame
    with ScrollDetector, CameraController {
  static const double _dragThreshold = 8.0;

  double _dragTravel = 0.0;
  bool _isDragging = false;
  DevFrameStats? _devFrameStats;
  final Map<int, Vector2> _viewportPointers = {};
  double _pinchStartDistance = 0.0;
  double _pinchStartZoom = 1.0;
  Vector2? _pinchStartWorldFocus;
  double _panZoomStartZoom = 1.0;
  Vector2? _panZoomStartWorldFocus;
  final Vector2 _panZoomAccumulatedPanDelta = Vector2.zero();
  _QueuedViewportCameraState? _queuedViewportCameraState;

  bool get isDragging => _isDragging;

  bool get hasViewportPointers => _viewportPointers.isNotEmpty;

  bool get hasMultipleViewportPointers => _viewportPointers.length >= 2;

  @protected
  WorldProjection get worldProjection => WorldProjection.disabled;

  @override
  Color backgroundColor() => MapPalette.worldBackground;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.zoom = 1.0;
    camera.viewfinder.anchor = Anchor.topLeft;
    await _addDevFpsHud();
    await DevPerformance.timeAsync(
      '$runtimeType.buildWorld',
      () => buildWorld(),
    );
  }

  @override
  void update(double dt) {
    _flushQueuedViewportCameraInput();
    final stats = DevPerformance.isEnabled ? _frameStats() : null;
    if (stats == null) {
      super.update(dt);
      return;
    }

    final stopwatch = Stopwatch()..start();
    super.update(dt);
    stopwatch.stop();
    stats.recordUpdate(
      dt,
      stopwatch.elapsed,
      sampleComponentCount: () => _countComponents(world),
    );
  }

  @override
  void render(Canvas canvas) {
    final stats = DevPerformance.isEnabled ? _frameStats() : null;
    if (stats == null) {
      _renderProjected(canvas, () => super.render(canvas));
      return;
    }

    final stopwatch = Stopwatch()..start();
    _renderProjected(canvas, () => super.render(canvas));
    stopwatch.stop();
    stats.recordRender(stopwatch.elapsed);
  }

  void _renderProjected(Canvas canvas, VoidCallback render) {
    final matrix = _worldProjectionMatrix();
    if (matrix == null) {
      render();
      return;
    }
    canvas
      ..save()
      ..transform(Float64List.fromList(matrix.storage));
    try {
      render();
    } finally {
      canvas.restore();
    }
  }

  DevFrameStats _frameStats() =>
      _devFrameStats ??= DevFrameStats(runtimeType.toString());

  @visibleForTesting
  void processDragStart() {
    _dragTravel = 0.0;
    _isDragging = false;
  }

  Future<void> _addDevFpsHud() async {
    if (!DevPerformance.isEnabled) return;
    await camera.viewport.add(
      FpsTextComponent<TextPaint>(
        decimalPlaces: 1,
        position: Vector2(8, 8),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2),
            ],
          ),
        ),
      ),
    );
  }

  @visibleForTesting
  void processDragUpdate(Vector2 delta) {
    _dragTravel += delta.length;
    if (_dragTravel >= _dragThreshold) {
      _isDragging = true;
    }
  }

  @visibleForTesting
  void processDragEnd() {
    _dragTravel = 0.0;
    _isDragging = false;
  }

  @visibleForTesting
  bool get hasQueuedViewportCameraInput => _queuedViewportCameraState != null;

  @visibleForTesting
  void flushQueuedViewportCameraInputForTesting() {
    _flushQueuedViewportCameraInput();
  }

  @override
  void onScroll(PointerScrollInfo info) {
    final delta = info.scrollDelta.global.y;
    final focalPoint = worldInputPointForWidget(info.eventPosition.widget);
    _queueZoomAround(
      _effectiveCameraZoom() * (1 - delta * CameraController.scrollSensitivity),
      focalPoint,
    );
  }

  void handleViewportPointerDown(int pointerId, Vector2 position) {
    _viewportPointers[pointerId] = position.clone();
    if (_viewportPointers.length == 1) {
      processDragStart();
    } else if (_viewportPointers.length == 2) {
      _startViewportPinch();
      processDragEnd();
    }
  }

  void handleViewportPointerMove(int pointerId, Vector2 position) {
    final previous = _viewportPointers[pointerId];
    if (previous == null) return;

    _viewportPointers[pointerId] = position.clone();
    if (_viewportPointers.length >= 2) {
      _updateViewportPinch();
      return;
    }

    final delta = position - previous;
    processDragUpdate(delta);
    if (_isDragging) {
      _queuePanByScreenDelta(delta);
    }
  }

  void handleViewportPointerUp(int pointerId) {
    _viewportPointers.remove(pointerId);
    if (_viewportPointers.isEmpty) {
      processDragEnd();
    } else if (_viewportPointers.length == 1) {
      processDragStart();
    } else {
      _startViewportPinch();
    }
  }

  void handleViewportPointerCancel(int pointerId) {
    handleViewportPointerUp(pointerId);
  }

  void handleViewportPointerHover(Vector2 position) {}

  void handleViewportPointerExit() {}

  void handleViewportLongPressStart(Vector2 position) {}

  void handleViewportLongPressMoveUpdate(Vector2 position) {}

  void handleViewportLongPressUp() {}

  void handleViewportLongPressEnd(Vector2 position) {}

  void handleViewportLongPressCancel() {}

  void handleViewportPanZoomStart(Vector2 focalPoint) {
    _panZoomStartZoom = _effectiveCameraZoom();
    _panZoomStartWorldFocus = _effectiveViewportToWorld(focalPoint);
    _panZoomAccumulatedPanDelta.setZero();
  }

  void handleViewportPanZoomUpdate({
    required Vector2 panDelta,
    required double scale,
    required Vector2 focalPoint,
  }) {
    if (scale > 0 && (scale - 1.0).abs() > 0.001) {
      _queueZoomKeepingWorldPoint(
        zoom: _panZoomStartZoom * scale,
        focalPoint: focalPoint,
        worldPoint: _panZoomStartWorldFocus ?? viewportToWorld(focalPoint),
      );
      if (panDelta.length > 0) {
        _panZoomAccumulatedPanDelta.add(panDelta);
      }
      if (_panZoomAccumulatedPanDelta.length > 0) {
        _queuePanByScreenDelta(_panZoomAccumulatedPanDelta);
      }
    } else if (panDelta.length > 0) {
      _panZoomAccumulatedPanDelta.add(panDelta);
      _queuePanByScreenDelta(panDelta);
    }
  }

  void handleViewportPanZoomEnd() {
    _panZoomStartWorldFocus = null;
    _panZoomAccumulatedPanDelta.setZero();
    processDragEnd();
  }

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

  @protected
  Vector2 worldInputPointForWidget(Vector2 widgetPoint) {
    final projection = worldProjection;
    if (!projection.isEnabled) return widgetPoint.clone();
    return projection.unprojectPoint(widgetPoint, size);
  }

  @protected
  Vector2 worldOutputPointForWidget(Vector2 widgetPoint) {
    final projection = worldProjection;
    if (!projection.isEnabled) return widgetPoint.clone();
    return projection.projectPoint(widgetPoint, size);
  }

  @visibleForTesting
  Vector2 projectWidgetPointForTesting(Vector2 widgetPoint) {
    return worldOutputPointForWidget(widgetPoint);
  }

  @visibleForTesting
  Vector2 unprojectWidgetPointForTesting(Vector2 widgetPoint) {
    return worldInputPointForWidget(widgetPoint);
  }

  Matrix4? _worldProjectionMatrix() {
    final projection = worldProjection;
    if (!projection.isEnabled || size.x <= 0 || size.y <= 0) return null;
    return projection.matrixForSize(size);
  }

  @override
  Iterable<Component> componentsAtPoint(
    Vector2 point, [
    List<Vector2>? nestedPoints,
  ]) {
    return super.componentsAtPoint(
      worldInputPointForWidget(point),
      nestedPoints,
    );
  }

  Future<void> buildWorld();

  int _countComponents(Component component) {
    var count = component.children.length;
    for (final child in component.children) {
      count += _countComponents(child);
    }
    return count;
  }
}

class _QueuedViewportCameraState {
  double zoom;
  Vector2 position;

  _QueuedViewportCameraState({required this.zoom, required this.position});
}
