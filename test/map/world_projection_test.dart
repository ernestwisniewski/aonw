import 'package:aonw/map/rendering/world_projection.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorldProjection', () {
    const projection = WorldProjection(strength: 0.16);
    final size = Vector2(1280, 720);

    test('round-trips projected points through inverse mapping', () {
      final points = [
        Vector2(100, 100),
        Vector2(640, 120),
        Vector2(1180, 360),
        Vector2(640, 710),
      ];

      for (final point in points) {
        final projected = projection.projectPoint(point, size);
        final restored = projection.unprojectPoint(projected, size);

        expect(restored.x, closeTo(point.x, 0.001));
        expect(restored.y, closeTo(point.y, 0.001));
      }
    });

    test('pushes the top of the viewport inward and leaves bottom stable', () {
      final topLeft = projection.projectPoint(Vector2.zero(), size);
      final topCenter = projection.projectPoint(Vector2(size.x / 2, 0), size);
      final bottomCenter = projection.projectPoint(
        Vector2(size.x / 2, size.y),
        size,
      );

      expect(topLeft.x, greaterThan(0));
      expect(topCenter.x, closeTo(size.x / 2, 0.001));
      expect(topCenter.y, greaterThan(0));
      expect(bottomCenter.x, closeTo(size.x / 2, 0.001));
      expect(bottomCenter.y, closeTo(size.y, 0.001));
    });
  });
}
