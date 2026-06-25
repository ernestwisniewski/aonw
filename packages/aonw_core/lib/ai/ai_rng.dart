class AiRng {
  static const int _mask32 = 0xFFFFFFFF;
  static const int _multiplier = 1664525;
  static const int _increment = 1013904223;

  final int state;

  const AiRng._(this.state);

  factory AiRng(int seed) => AiRng._(_normalize(seed));

  factory AiRng.fromTurn({
    required int turn,
    required String playerId,
    required int baseSeed,
  }) {
    var hash = _mix(baseSeed);
    hash = _mix(hash ^ turn);
    for (final codeUnit in playerId.codeUnits) {
      hash = _mix(hash ^ codeUnit);
    }
    return AiRng._(_normalize(hash));
  }

  AiRngInt nextInt(int maxExclusive) {
    if (maxExclusive <= 0) {
      throw RangeError.range(maxExclusive, 1, null, 'maxExclusive');
    }
    final nextState = (_multiplier * state + _increment) & _mask32;
    return AiRngInt(rng: AiRng._(nextState), value: nextState % maxExclusive);
  }

  static int _normalize(int value) => value & _mask32;

  static int _mix(int value) {
    var hash = value & _mask32;
    hash = (hash ^ (hash >>> 16)) & _mask32;
    hash = (hash * 0x7FEB352D) & _mask32;
    hash = (hash ^ (hash >>> 15)) & _mask32;
    hash = (hash * 0x846CA68B) & _mask32;
    return (hash ^ (hash >>> 16)) & _mask32;
  }

  @override
  bool operator ==(Object other) => other is AiRng && other.state == state;

  @override
  int get hashCode => state;

  @override
  String toString() => 'AiRng(state: $state)';
}

class AiRngInt {
  final AiRng rng;
  final int value;

  const AiRngInt({required this.rng, required this.value});
}
