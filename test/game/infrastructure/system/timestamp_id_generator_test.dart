import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/infrastructure/system/timestamp_id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimestampIdGenerator', () {
    test('formats ids from the injected clock', () {
      final generator = TimestampIdGenerator(
        clock: _FixedClock(DateTime(2026, 4, 25, 9, 8, 7, 6)),
      );

      expect(generator.nextId(), '20260425_090807_006');
    });
  });
}

class _FixedClock extends Clock {
  final DateTime value;

  const _FixedClock(this.value);

  @override
  DateTime now() => value;
}
