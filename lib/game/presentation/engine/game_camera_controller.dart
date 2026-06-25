import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

/// Controls the in-game camera: zoom, positioning, and restoring saved state.
class GameCameraController {
  final CameraComponent _camera;
  final MapData _mapData;
  bool _reduceMotion;
  static final ComponentKey _shakeEffectKey = ComponentKey.named(
    'camera-shake',
  );
  _SmoothCameraMotion? _smoothMotion;
  Vector2? Function()? _trackedWorldPoint;

  GameCameraController({
    required CameraComponent camera,
    required MapData mapData,
    bool reduceMotion = false,
  }) : _camera = camera,
       _mapData = mapData,
       _reduceMotion = reduceMotion;

  double get defaultZoom => _mapData.defaultZoom;

  bool get reduceMotion => _reduceMotion;

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    if (_reduceMotion) {
      _camera.viewfinder.removeWhere((component) {
        return component.key == _shakeEffectKey;
      });
      _trackedWorldPoint = null;
      _cancelSmoothMotion();
    }
  }

  void hideMap() {
    _camera.viewfinder.position = Vector2(-100000, -100000);
    _camera.viewfinder.zoom = defaultZoom;
  }

  void jumpToTile(int col, int row) {
    centerOnWorldPoint(_tileCenter(col, row));
  }

  Future<void> smoothToTile(
    int col,
    int row, {
    double duration = 0.48,
    Curve curve = Curves.easeInOutCubic,
  }) {
    return smoothCenterOnWorldPoint(
      _tileCenter(col, row),
      duration: duration,
      curve: curve,
    );
  }

  Vector2 _tileCenter(int col, int row) {
    final pos = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: MapConfig.defaultConfig.hexRadius,
    );
    return Vector2(pos.x, pos.y * HexGrid.perspectiveY - 12);
  }

  void centerOnWorldPoint(Vector2 worldPoint) {
    _trackedWorldPoint = null;
    _cancelSmoothMotion();
    _camera.viewfinder.position = _cameraPositionFor(worldPoint);
  }

  Future<void> smoothCenterOnWorldPoint(
    Vector2 worldPoint, {
    double duration = 0.48,
    Curve curve = Curves.easeInOutCubic,
  }) {
    _trackedWorldPoint = null;
    if (_reduceMotion || duration <= 0) {
      centerOnWorldPoint(worldPoint);
      return Future<void>.value();
    }
    final target = _cameraPositionFor(worldPoint);
    final viewfinder = _camera.viewfinder;
    if ((viewfinder.position - target).length < 0.001) {
      return Future<void>.value();
    }

    _cancelSmoothMotion();
    final completer = Completer<void>();
    _smoothMotion = _SmoothCameraMotion(
      start: viewfinder.position.clone(),
      target: target,
      duration: duration,
      curve: curve,
      completer: completer,
    );
    return completer.future;
  }

  void followWorldPoint(Vector2? Function() point) {
    _cancelSmoothMotion();
    _trackedWorldPoint = point;
  }

  void stopFollowingWorldPoint() {
    _trackedWorldPoint = null;
  }

  void update(double dt) {
    final trackedWorldPoint = _trackedWorldPoint?.call();
    if (trackedWorldPoint != null) {
      final target = _cameraPositionFor(trackedWorldPoint);
      final current = _camera.viewfinder.position;
      final delta = target - current;
      // Sub-pixel residual: snap so the camera doesn't asymptotically chase
      // a stationary follow point.
      if (delta.length < 0.5) {
        _camera.viewfinder.position = target;
        return;
      }
      // Time-correct exponential smoothing: equivalent to lerp(current, target, ~0.30)
      // at 60fps — frame-rate independent.
      const followHalfLifeSeconds = 0.10;
      final t = 1.0 - math.pow(0.5, dt / followHalfLifeSeconds).toDouble();
      _camera.viewfinder.position = current + delta * t;
      return;
    }

    final motion = _smoothMotion;
    if (motion == null) return;
    motion.elapsed += dt;
    final progress = (motion.elapsed / motion.duration).clamp(0.0, 1.0);
    final eased = motion.curve.transform(progress);
    _camera.viewfinder.position =
        motion.start + (motion.target - motion.start) * eased;
    if (progress >= 1) {
      _camera.viewfinder.position = motion.target;
      _smoothMotion = null;
      if (!motion.completer.isCompleted) {
        scheduleMicrotask(motion.completer.complete);
      }
    }
  }

  Vector2 _cameraPositionFor(Vector2 worldPoint) {
    final halfViewport = _camera.viewport.size / (2 * _camera.viewfinder.zoom);
    return worldPoint - halfViewport;
  }

  void _cancelSmoothMotion() {
    final motion = _smoothMotion;
    _smoothMotion = null;
    if (motion != null && !motion.completer.isCompleted) {
      scheduleMicrotask(motion.completer.complete);
    }
  }

  void shake({double intensity = 8.0, double duration = 0.28}) {
    if (_reduceMotion) return;
    if (intensity <= 0 || duration <= 0) return;

    final viewfinder = _camera.viewfinder;
    final stepDuration = duration / 4;
    final effect = SequenceEffect([
      MoveEffect.by(
        Vector2(intensity, 0),
        EffectController(duration: stepDuration),
      ),
      MoveEffect.by(
        Vector2(-intensity * 2, 0),
        EffectController(duration: stepDuration),
      ),
      MoveEffect.by(
        Vector2(intensity * 1.5, 0),
        EffectController(duration: stepDuration),
      ),
      MoveEffect.by(
        Vector2(-intensity * 0.5, 0),
        EffectController(duration: stepDuration),
      ),
    ], key: _shakeEffectKey);
    unawaited(Future<void>.value(viewfinder.add(effect)));
  }

  void restore(CameraState? state) {
    if (state == null) return;
    _trackedWorldPoint = null;
    _cancelSmoothMotion();
    _camera.viewfinder.position = Vector2(state.x, state.y);
    _camera.viewfinder.zoom = state.zoom;
  }
}

class _SmoothCameraMotion {
  _SmoothCameraMotion({
    required this.start,
    required this.target,
    required this.duration,
    required this.curve,
    required this.completer,
  });

  final Vector2 start;
  final Vector2 target;
  final double duration;
  final Curve curve;
  final Completer<void> completer;
  double elapsed = 0;
}
