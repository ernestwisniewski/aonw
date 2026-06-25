import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/infrastructure/system/system_clock.dart';

final class TimestampIdGenerator implements IdGenerator {
  final Clock clock;

  const TimestampIdGenerator({this.clock = const SystemClock()});

  @override
  String nextId() {
    final now = clock.now();
    return '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}'
        '_${now.millisecond.toString().padLeft(3, '0')}';
  }
}
