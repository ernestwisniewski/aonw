import 'package:aonw_flutter/features/turns/application/turn_presentation_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presents each observed turn once and in order', () {
    final initial = TurnPresentationQueue.start(7);

    expect(initial.active?.turn, 7);
    expect(initial.observe(7), same(initial));
    expect(initial.observe(6), same(initial));

    final queued = initial.observe(8).observe(9);
    expect(queued.active?.turn, 7);
    expect(queued.pending.map((item) => item.turn), [8, 9]);

    final second = queued.completeActive();
    expect(second.active?.turn, 8);
    expect(second.pending.single.turn, 9);
    final third = second.completeActive();
    expect(third.active?.turn, 9);
    expect(third.completeActive().active, isNull);
  });

  test('rejects non-positive turn numbers', () {
    expect(() => TurnPresentationQueue.start(0), throwsArgumentError);
  });
}
