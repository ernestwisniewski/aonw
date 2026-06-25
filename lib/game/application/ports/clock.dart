abstract class Clock {
  const Clock();

  DateTime now();

  DateTime nowUtc() => now().toUtc();
}
