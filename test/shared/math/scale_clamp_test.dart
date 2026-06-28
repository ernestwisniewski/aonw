import 'package:aonw/shared/math/scale_clamp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('scale clamp', () {
    test('clamps marker scale to readable defaults', () {
      expect(clampMarkerScale(0.4), 1.0);
      expect(clampMarkerScale(1.7), 1.7);
      expect(clampMarkerScale(3.0), 2.4);
    });

    test('falls back for non-finite values', () {
      expect(clampMarkerScale(double.nan), 1.0);
      expect(clampFiniteScale(double.infinity, fallback: 0.5), 0.5);
    });

    test('supports custom scale bounds', () {
      expect(clampFiniteScale(0.1, min: 0.25, max: 3.0), 0.25);
      expect(clampFiniteScale(4.0, min: 0.25, max: 3.0), 3.0);
    });
  });
}
