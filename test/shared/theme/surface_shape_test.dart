import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SurfaceShape', () {
    test('radius values match the current warm HUD theme', () {
      expect(SurfaceShape.frame.radius, 2);
      expect(SurfaceShape.card.radius, 10);
      expect(SurfaceShape.pill.radius, 999);
      expect(SurfaceShape.chip.radius, 14);
      expect(SurfaceShape.button.radius, 12);
    });

    test('borderRadius produces circular radii', () {
      expect(SurfaceShape.card.borderRadius, BorderRadius.circular(10));
      expect(SurfaceShape.pill.borderRadius, BorderRadius.circular(999));
    });
  });
}
