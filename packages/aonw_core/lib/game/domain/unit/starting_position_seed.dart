abstract final class StartingPositionSeed {
  static int fromParts(Iterable<Object?> parts) {
    var seed = 0;
    for (final part in parts) {
      seed = switch (part) {
        null => _mix(seed, 0),
        final int value => _mix(seed, value),
        final DateTime value => _mix(
          seed,
          value.toUtc().microsecondsSinceEpoch,
        ),
        final String value => _mixString(seed, value),
        final Object value => _mixString(seed, value.toString()),
      };
    }
    return seed;
  }

  static int _mixString(int seed, String value) {
    var mixed = seed;
    for (final codeUnit in value.codeUnits) {
      mixed = _mix(mixed, codeUnit);
    }
    return mixed;
  }

  static int _mix(int seed, int value) {
    const mask32 = 0xFFFFFFFF;
    var hash = (seed ^ value) & mask32;
    hash = (hash ^ (hash >>> 16)) & mask32;
    hash = (hash * 0x7FEB352D) & mask32;
    hash = (hash ^ (hash >>> 15)) & mask32;
    hash = (hash * 0x846CA68B) & mask32;
    return (hash ^ (hash >>> 16)) & mask32;
  }
}
