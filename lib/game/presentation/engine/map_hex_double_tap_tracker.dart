typedef MapInteractionClock = Duration Function();

/// Recognizes a rapid second tap on the same map hex.
///
/// Selection remains command-driven. The tracker only distinguishes a direct
/// terrain-selection gesture from ordinary, independently timed map taps.
final class MapHexDoubleTapTracker {
  MapHexDoubleTapTracker({
    required MapInteractionClock now,
    this.doubleTapWindow = const Duration(milliseconds: 360),
  }) : _now = now;

  factory MapHexDoubleTapTracker.withStopwatch({
    Duration doubleTapWindow = const Duration(milliseconds: 360),
  }) {
    final stopwatch = Stopwatch()..start();
    return MapHexDoubleTapTracker(
      now: () => stopwatch.elapsed,
      doubleTapWindow: doubleTapWindow,
    );
  }

  final Duration doubleTapWindow;
  final MapInteractionClock _now;

  ({int col, int row})? _lastHex;
  Duration? _lastTapAt;

  bool registerTap(int col, int row) {
    final now = _now();
    final lastTapAt = _lastTapAt;
    final doubleTap =
        _lastHex == (col: col, row: row) &&
        lastTapAt != null &&
        now - lastTapAt <= doubleTapWindow;
    _lastHex = (col: col, row: row);
    _lastTapAt = doubleTap ? null : now;
    return doubleTap;
  }

  void clear() {
    _lastHex = null;
    _lastTapAt = null;
  }
}
