import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

@immutable
class WorldProjection {
  static const disabled = WorldProjection(strength: 0);

  final double strength;

  const WorldProjection({required this.strength});

  bool get isEnabled => strength > 0;

  Matrix4 matrixForSize(Vector2 size) {
    final width = size.x;
    final height = size.y;
    if (!isEnabled || width <= 0 || height <= 0) {
      return Matrix4.identity();
    }

    final clampedStrength = strength.clamp(0.0, 0.3).toDouble();
    final centerX = width / 2;
    final bottomY = height;

    return Matrix4(
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
  }

  Matrix4 inverseMatrixForSize(Vector2 size) {
    return Matrix4.inverted(matrixForSize(size));
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
