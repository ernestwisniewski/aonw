final class GoldAmount {
  GoldAmount(int value) : value = _validated(value);

  static final zero = GoldAmount(0);

  final int value;

  bool canFundFrom(int availableGold) => availableGold >= value;

  @override
  bool operator ==(Object other) => other is GoldAmount && other.value == value;

  @override
  int get hashCode => Object.hash(GoldAmount, value);

  @override
  String toString() => 'GoldAmount($value)';

  static int _validated(int value) {
    if (value < 0) {
      throw ArgumentError.value(
        value,
        'value',
        'Expected a non-negative gold amount',
      );
    }
    return value;
  }
}
