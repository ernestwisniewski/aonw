import 'package:aonw/game/presentation/engine/map_hex_double_tap_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes only a rapid second tap on the same hex', () {
    var now = Duration.zero;
    final tracker = MapHexDoubleTapTracker(now: () => now);

    expect(tracker.registerTap(1, 2), isFalse);
    now += const Duration(milliseconds: 200);
    expect(tracker.registerTap(1, 2), isTrue);
    expect(tracker.registerTap(1, 2), isFalse);

    now += const Duration(milliseconds: 400);
    expect(tracker.registerTap(1, 2), isFalse);
    now += const Duration(milliseconds: 100);
    expect(tracker.registerTap(2, 2), isFalse);
  });
}
