import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:test/test.dart';

void main() {
  test('copyWith preserves unchanged stability tuning', () {
    final copy = StabilityRuleset.standard.copyWith();

    expect(copy, StabilityRuleset.standard);
  });

  test('copyWith replaces selected stability tuning', () {
    final copy = StabilityRuleset.standard.copyWith(
      baseOrder: 9,
      hegemonyTaxPointsPerCost: 4,
    );

    expect(copy.baseOrder, 9);
    expect(copy.hegemonyTaxPointsPerCost, 4);
    expect(copy.costPerCity, StabilityRuleset.standard.costPerCity);
  });
}
