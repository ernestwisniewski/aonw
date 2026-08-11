import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

@immutable
class WorldProjection {
  static const disabled = WorldProjection(strength: 0);
  static const int _matrixCacheLimit = 8;
  static final Map<({double strength, double width, double height}), _Matrices>
  _matrixCache = {};

  final double strength;

  const WorldProjection({required this.strength});

  bool get isEnabled => strength > 0;

  Matrix4 matrixForSize(Vector2 size) {
    final width = size.x;
    final height = size.y;
    if (!isEnabled || width <= 0 || height <= 0) {
      return Matrix4.identity();
    }

    return _matricesFor(size).forward;
  }

  Matrix4 inverseMatrixForSize(Vector2 size) {
    final width = size.x;
    final height = size.y;
    if (!isEnabled || width <= 0 || height <= 0) {
      return Matrix4.identity();
    }
    return _matricesFor(size).inverse;
  }

  _Matrices _matricesFor(Vector2 size) {
    final clampedStrength = strength.clamp(0.0, 0.3).toDouble();
    final key = (strength: clampedStrength, width: size.x, height: size.y);
    final cached = _matrixCache[key];
    if (cached != null) return cached;
    if (_matrixCache.length >= _matrixCacheLimit) _matrixCache.clear();

    final width = size.x;
    final height = size.y;
    final centerX = width / 2;
    final bottomY = height;

    final forward = Matrix4(
      1,
      0,
      0,
      0,
      -centerX * clampedStrength / bottomY,
      1 - clampedStrength,
      0,
      -clampedStrength / bottomY,
      0,
      0,
      1,
      0,
      centerX * clampedStrength,
      bottomY * clampedStrength,
      0,
      1 + clampedStrength,
    );
    final matrices = _Matrices(
      forward: forward,
      inverse: Matrix4.inverted(forward),
    );
    _matrixCache[key] = matrices;
    return matrices;
  }

  Vector2 projectPoint(Vector2 point, Vector2 size) {
    return _transformPoint(matrixForSize(size), point);
  }

  Vector2 unprojectPoint(Vector2 point, Vector2 size) {
    return _transformPoint(inverseMatrixForSize(size), point);
  }

  static Vector2 _transformPoint(Matrix4 matrix, Vector2 point) {
    final projected = matrix.perspectiveTransform(Vector3(point.x, point.y, 0));
    return Vector2(projected.x, projected.y);
  }
}

class _Matrices {
  const _Matrices({required this.forward, required this.inverse});

  final Matrix4 forward;
  final Matrix4 inverse;
}
