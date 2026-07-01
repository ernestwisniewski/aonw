import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';

abstract final class HegemonyPressureCalculator {
  static double hStar({
    required int playerCount,
    required StabilityRuleset ruleset,
  }) {
    final count = playerCount <= 0 ? 1 : playerCount;
    return ruleset.hegemonyK * (100.0 / count);
  }

  static double pressureAbove({
    required double controlPercent,
    required int playerCount,
    required StabilityRuleset ruleset,
  }) {
    final threshold = hStar(playerCount: playerCount, ruleset: ruleset);
    final delta = controlPercent - threshold;
    return delta <= 0 ? 0.0 : delta;
  }

  static int hegemonyTax({
    required double controlPercent,
    required int playerCount,
    required StabilityRuleset ruleset,
  }) {
    final above = pressureAbove(
      controlPercent: controlPercent,
      playerCount: playerCount,
      ruleset: ruleset,
    );
    return (above / ruleset.hegemonyTaxPointsPerCost).floor();
  }
}
