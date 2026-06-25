import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersonaWeights', () {
    test('identity has neutral weights', () {
      const weights = PersonaWeights.identity;

      expect(weights.aggression, 1.0);
      expect(weights.expansion, 1.0);
      expect(weights.economy, 1.0);
      expect(weights.science, 1.0);
    });

    test('multiply composes component-wise', () {
      const left = PersonaWeights(
        aggression: 1.2,
        expansion: 1.1,
        economy: 0.9,
        science: 1.0,
      );
      const right = PersonaWeights(
        aggression: 1.5,
        expansion: 1.0,
        economy: 1.0,
        science: 1.2,
      );

      final result = left.multiply(right);

      expect(result.aggression, closeTo(1.8, 1e-9));
      expect(result.expansion, closeTo(1.1, 1e-9));
      expect(result.economy, closeTo(0.9, 1e-9));
      expect(result.science, closeTo(1.2, 1e-9));
    });
  });
}
