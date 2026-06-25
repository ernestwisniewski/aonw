import 'package:aonw/game/application/ports/clock.dart';

final class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
