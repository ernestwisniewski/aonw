import 'package:aonw/game/presentation/engine/city_description_tap_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CityDescriptionTapTracker', () {
    test('detects a second tap on the same city inside the window', () {
      var now = Duration.zero;
      final tracker = CityDescriptionTapTracker(now: () => now);

      expect(tracker.registerTap('city_1'), isFalse);

      now += const Duration(milliseconds: 120);

      expect(tracker.registerTap('city_1'), isTrue);
      expect(tracker.registerTap('city_1'), isFalse);
    });

    test('ignores different cities and taps outside the window', () {
      var now = Duration.zero;
      final tracker = CityDescriptionTapTracker(now: () => now);

      expect(tracker.registerTap('city_1'), isFalse);

      now += const Duration(milliseconds: 120);

      expect(tracker.registerTap('city_2'), isFalse);

      now += const Duration(milliseconds: 500);

      expect(tracker.registerTap('city_2'), isFalse);
    });

    test('clear resets the pending double-tap sequence', () {
      var now = Duration.zero;
      final tracker = CityDescriptionTapTracker(now: () => now);

      expect(tracker.registerTap('city_1'), isFalse);
      tracker.clear();

      now += const Duration(milliseconds: 120);

      expect(tracker.registerTap('city_1'), isFalse);
    });
  });
}
