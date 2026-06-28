import 'dart:math' as math;

import 'package:aonw/shared/theme/hud_canvas_shapes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HudCanvasShapes', () {
    test('hexOutlinePath builds a point-top decorative hex', () {
      const center = Offset(20, 30);
      const radius = 12.0;
      final path = HudCanvasShapes.hexOutlinePath(center, radius);
      final bounds = path.getBounds();
      final halfWidth = math.sqrt(3) / 2 * radius;

      expect(bounds.left, closeTo(center.dx - halfWidth, 0.01));
      expect(bounds.right, closeTo(center.dx + halfWidth, 0.01));
      expect(bounds.top, closeTo(center.dy - radius, 0.01));
      expect(bounds.bottom, closeTo(center.dy + radius, 0.01));
    });
  });
}
