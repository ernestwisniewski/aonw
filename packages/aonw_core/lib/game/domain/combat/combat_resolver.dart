import 'package:aonw_core/game/domain/combat/combat_outcome.dart';
import 'package:aonw_core/game/domain/combat/combat_rng.dart';
import 'package:aonw_core/game/domain/combat/combat_ruleset.dart';
import 'package:aonw_core/game/domain/combat/combat_step.dart';
import 'package:aonw_core/game/domain/combat/combatant.dart';

abstract final class CombatResolver {
  static CombatOutcome resolve({
    required Combatant attacker,
    required Combatant defender,
    required CombatRng rng,
    CombatRuleset ruleset = CombatRuleset.standard,
    bool defenderCanRetreat = false,
  }) {
    final steps = <CombatStep>[
      for (final modifier in attacker.modifiers) ModifierAppliedStep(modifier),
      for (final modifier in defender.modifiers) ModifierAppliedStep(modifier),
    ];
    final attackerStats = attacker.effective;
    final defenderStats = defender.effective;

    final attackVariance = rng.signed(ruleset.varianceRange);
    steps.add(RollStep(seed: rng.seed, value: attackVariance));
    final attackDamage = _damage(
      attack: attackerStats.attack,
      defense: defenderStats.defense,
      variance: attackVariance,
    );
    var defenderHpAfter = defender.currentHp - attackDamage;
    var defenderKilled = defenderHpAfter <= 0;
    var defenderRetreated = false;
    steps.add(AttackStep(damage: attackDamage, active: attacker.modifiers));

    if (_shouldRetreat(
      defenderHpAfter: defenderHpAfter,
      defenderMaxHp: defender.maxHp,
      defenderMobility: defenderStats.mobility,
      defenderCanRetreat: defenderCanRetreat,
      thresholdPercent: ruleset.retreatThresholdPercent,
    )) {
      defenderHpAfter = defenderHpAfter < 1 ? 1 : defenderHpAfter;
      defenderKilled = false;
      defenderRetreated = true;
    }

    var attackerHpAfter = attacker.currentHp;
    var attackerKilled = false;
    if (!defenderKilled &&
        !defenderRetreated &&
        attackerStats.range <= 1 &&
        defenderStats.attack > 0) {
      final retaliationVariance = rng.signed(ruleset.varianceRange);
      steps.add(RollStep(seed: rng.seed, value: retaliationVariance));
      final retaliationDamage = _damage(
        attack: defenderStats.attack,
        defense: attackerStats.defense,
        variance: retaliationVariance,
      );
      attackerHpAfter -= retaliationDamage;
      attackerKilled = attackerHpAfter <= 0;
      steps.add(
        RetaliationStep(damage: retaliationDamage, active: defender.modifiers),
      );
    }

    return CombatOutcome(
      attackerUnitId: attacker.unitId,
      defenderUnitId: defender.unitId,
      attackerHpAfter: attackerHpAfter,
      defenderHpAfter: defenderHpAfter,
      attackerKilled: attackerKilled,
      defenderKilled: defenderKilled,
      defenderRetreated: defenderRetreated,
      steps: steps,
    );
  }

  static int _damage({
    required int attack,
    required int defense,
    required int variance,
  }) {
    if (attack <= 0) return 0;
    final raw = attack - defense + variance;
    return raw < 1 ? 1 : raw;
  }

  static bool _shouldRetreat({
    required int defenderHpAfter,
    required int defenderMaxHp,
    required int defenderMobility,
    required bool defenderCanRetreat,
    required int thresholdPercent,
  }) {
    if (!defenderCanRetreat || defenderMobility < 1 || defenderMaxHp <= 0) {
      return false;
    }
    if (defenderHpAfter <= 0) return false;
    return defenderHpAfter * 100 < defenderMaxHp * thresholdPercent;
  }
}
