class CombatRng {
  final int seed;
  int _state;

  CombatRng(int seed)
    : seed = _normalize(seed),
      _state = _normalize(seed) == 0 ? 0x9E3779B9 : _normalize(seed);

  factory CombatRng.fromTurn({
    required int turn,
    required String attackerId,
    required String defenderId,
  }) {
    var hash = 0x811C9DC5;
    hash = _mixInt(hash, turn);
    hash = _mixString(hash, attackerId);
    hash = _mixString(hash, defenderId);
    return CombatRng(hash);
  }

  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be greater than zero');
    }
    return _nextUint32() % max;
  }

  int signed(int magnitude) {
    if (magnitude <= 0) return 0;
    return nextInt(magnitude * 2 + 1) - magnitude;
  }

  int _nextUint32() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = _normalize(x);
    return _state;
  }

  static int _normalize(int value) => value & 0xFFFFFFFF;

  static int _mixInt(int hash, int value) {
    var next = hash;
    for (var shift = 0; shift < 32; shift += 8) {
      next ^= (value >> shift) & 0xFF;
      next = (next * 0x01000193) & 0xFFFFFFFF;
    }
    return next;
  }

  static int _mixString(int hash, String value) {
    var next = hash;
    for (final codeUnit in value.codeUnits) {
      next ^= codeUnit & 0xFF;
      next = (next * 0x01000193) & 0xFFFFFFFF;
      next ^= (codeUnit >> 8) & 0xFF;
      next = (next * 0x01000193) & 0xFFFFFFFF;
    }
    return next;
  }
}
