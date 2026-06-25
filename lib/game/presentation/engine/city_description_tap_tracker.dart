typedef InteractionClock = Duration Function();

final class CityDescriptionTapTracker {
  CityDescriptionTapTracker({
    required InteractionClock now,
    this.doubleTapWindow = const Duration(milliseconds: 360),
  }) : _now = now;

  factory CityDescriptionTapTracker.withStopwatch({
    Duration doubleTapWindow = const Duration(milliseconds: 360),
  }) {
    final stopwatch = Stopwatch()..start();
    return CityDescriptionTapTracker(
      now: () => stopwatch.elapsed,
      doubleTapWindow: doubleTapWindow,
    );
  }

  final Duration doubleTapWindow;
  final InteractionClock _now;

  String? _lastTappedCityId;
  Duration? _lastTapAt;

  bool registerTap(String cityId) {
    final now = _now();
    final lastTapAt = _lastTapAt;
    final doubleTap =
        _lastTappedCityId == cityId &&
        lastTapAt != null &&
        now - lastTapAt <= doubleTapWindow;
    _lastTappedCityId = cityId;
    _lastTapAt = doubleTap ? null : now;
    return doubleTap;
  }

  void clear() {
    _lastTappedCityId = null;
    _lastTapAt = null;
  }
}
