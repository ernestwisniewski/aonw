import 'package:aonw/game/presentation/formatters/game_value_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('percent formatter', () {
    test('formats fraction values as percentages by default', () {
      expect(percent(0.125), '13%');
    });

    test('formats existing percent values with optional symbol', () {
      expect(percent(72.4, false), '72%');
      expect(percent(72.4, false, false), '72');
    });
  });
}
