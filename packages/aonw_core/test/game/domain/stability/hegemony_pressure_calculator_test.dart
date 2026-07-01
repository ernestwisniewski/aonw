import 'package:aonw_core/game/domain/stability/hegemony_pressure_calculator.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:test/test.dart';

void main() {
  const ruleset = StabilityRuleset.standard;

  test('threshold scales with player count', () {
    expect(
      HegemonyPressureCalculator.hStar(playerCount: 4, ruleset: ruleset),
      closeTo(40.0, 0.0001),
    );
    expect(
      HegemonyPressureCalculator.hStar(playerCount: 8, ruleset: ruleset),
      closeTo(20.0, 0.0001),
    );
  });

  test('no pressure below threshold', () {
    expect(
      HegemonyPressureCalculator.pressureAbove(
        controlPercent: 30,
        playerCount: 4,
        ruleset: ruleset,
      ),
      0.0,
    );
  });

  test('pressure is control percent above the threshold', () {
    expect(
      HegemonyPressureCalculator.pressureAbove(
        controlPercent: 55,
        playerCount: 4,
        ruleset: ruleset,
      ),
      closeTo(15.0, 0.0001),
    );
  });

  test('hegemony tax is one per taxable band above the threshold', () {
    expect(
      HegemonyPressureCalculator.hegemonyTax(
        controlPercent: 55,
        playerCount: 4,
        ruleset: ruleset,
      ),
      3,
    );
    expect(
      HegemonyPressureCalculator.hegemonyTax(
        controlPercent: 30,
        playerCount: 4,
        ruleset: ruleset,
      ),
      0,
    );
  });

  test('player count of zero does not divide by zero', () {
    expect(
      HegemonyPressureCalculator.hStar(playerCount: 0, ruleset: ruleset),
      closeTo(160.0, 0.0001),
    );
  });

  test('tax points per cost of zero yields no tax instead of crashing', () {
    expect(
      HegemonyPressureCalculator.hegemonyTax(
        controlPercent: 90,
        playerCount: 4,
        ruleset: ruleset.copyWith(hegemonyTaxPointsPerCost: 0),
      ),
      0,
    );
  });
}
