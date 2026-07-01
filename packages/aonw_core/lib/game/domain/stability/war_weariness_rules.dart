import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';

abstract final class WarWearinessRules {
  static int next({
    required int current,
    required bool atWar,
    required int attacksThisTurn,
    required int citiesLost,
    required bool signedPeace,
    required StabilityRuleset ruleset,
  }) {
    var value = current;
    if (atWar) {
      final chargeableAttacks =
          attacksThisTurn - ruleset.warWearinessAttackFreePerTurn;
      if (chargeableAttacks > 0) value += chargeableAttacks;
      value += citiesLost * ruleset.warWearinessPerCityLost;
    } else {
      value -= signedPeace
          ? ruleset.warWearinessTreatyDecay
          : ruleset.warWearinessPeaceDecay;
    }

    if (value < 0) return 0;
    if (value > ruleset.warWearinessCap) return ruleset.warWearinessCap;
    return value;
  }
}
