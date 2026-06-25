import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/combat_tactics.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class AiMilitaryAssessment {
  const AiMilitaryAssessment();

  bool isMilitaryUnit(GameUnit unit) => AiUnitRoles.isMilitaryUnit(unit);

  bool canServeAsMilitaryUnit(
    GameUnit unit,
    CombatRuleset ruleset, {
    bool requireAttack = false,
  }) {
    if (unit.isWorker ||
        unit.type == GameUnitType.settler ||
        unit.hasSettlers) {
      return false;
    }
    final stats = UnitCombatStats.derive(unit, ruleset: ruleset);
    return requireAttack
        ? stats.attack > 0
        : stats.attack > 0 || stats.defense > 0;
  }

  bool canServeAsMilitaryUnitInContext(
    GameUnit unit,
    AiContext context, {
    bool requireAttack = false,
  }) {
    return canServeAsMilitaryUnit(
      unit,
      context.ruleset.combat,
      requireAttack: requireAttack,
    );
  }

  bool isMilitaryType(
    GameUnitType type,
    CombatRuleset ruleset, {
    bool requireAttack = false,
  }) {
    if (type == GameUnitType.worker || type == GameUnitType.settler) {
      return false;
    }
    final stats = ruleset.baseStatsFor(type);
    return requireAttack
        ? stats.attack > 0
        : stats.attack > 0 || stats.defense > 0;
  }

  bool isMilitaryTypeInContext(
    GameUnitType type,
    AiContext context, {
    bool requireAttack = false,
  }) {
    return isMilitaryType(
      type,
      context.ruleset.combat,
      requireAttack: requireAttack,
    );
  }

  List<GameUnit> ownMilitaryUnits(
    GameView view,
    CombatRuleset ruleset, {
    bool requireAttack = true,
  }) {
    return [
      for (final unit in view.ownUnits)
        if (canServeAsMilitaryUnit(unit, ruleset, requireAttack: requireAttack))
          unit,
    ];
  }

  int ownMilitaryCount(
    GameView view,
    CombatRuleset ruleset, {
    bool requireAttack = false,
  }) {
    var count = 0;
    for (final unit in view.ownUnits) {
      if (canServeAsMilitaryUnit(unit, ruleset, requireAttack: requireAttack)) {
        count += 1;
      }
    }
    return count;
  }

  int ownMilitaryCountWithQueues(
    GameView view,
    CombatRuleset ruleset, {
    bool requireAttack = false,
  }) {
    var count = ownMilitaryCount(view, ruleset, requireAttack: requireAttack);
    for (final city in view.ownCities) {
      final target = city.productionQueue?.target;
      if (target is UnitProductionTarget &&
          isMilitaryType(
            target.unitType,
            ruleset,
            requireAttack: requireAttack,
          )) {
        count += 1;
      }
    }
    return count;
  }

  bool isOnlyMilitaryUnit(
    GameUnit unit,
    GameView view,
    CombatRuleset ruleset, {
    bool requireAttack = false,
  }) {
    var count = 0;
    for (final own in view.ownUnits) {
      if (!canServeAsMilitaryUnit(own, ruleset, requireAttack: requireAttack)) {
        continue;
      }
      count += 1;
      if (count > 1 || own.id != unit.id) return false;
    }
    return count == 1;
  }

  bool isLastMilitaryReserveUnit(
    GameUnit unit,
    GameView view,
    CombatRuleset ruleset, {
    bool requireAttack = true,
  }) {
    if (view.ownCities.isEmpty ||
        !canServeAsMilitaryUnit(unit, ruleset, requireAttack: requireAttack)) {
      return false;
    }
    final military = ownMilitaryUnits(
      view,
      ruleset,
      requireAttack: requireAttack,
    );
    return military.length == 1 && military.single.id == unit.id;
  }

  bool hasClearVisibleMilitaryAdvantage(
    GameView view,
    CombatRuleset ruleset,
    String enemyPlayerId, {
    bool targetableOnly = false,
    bool includeDefensiveUnits = false,
  }) {
    final ownMilitary = ownMilitaryUnits(view, ruleset).length;
    final enemyMilitary = _visibleEnemyMilitaryCount(
      targetableOnly
          ? view.visibleTargetableEnemyUnits
          : view.visibleEnemyUnits,
      ruleset,
      enemyPlayerId,
      includeDefensiveUnits: includeDefensiveUnits,
    );
    if (enemyMilitary <= 0) return false;
    return ownMilitary >= enemyMilitary + 2 ||
        (ownMilitary >= 3 && ownMilitary / enemyMilitary >= 2);
  }

  bool isThreateningOwnCity(
    GameUnit enemy,
    GameView view, {
    required int maxDistance,
  }) {
    for (final city in view.ownCities) {
      final distance = HexDistance.between(
        HexCoordinate(col: enemy.col, row: enemy.row),
        city.center.toCoordinate(),
      );
      if (distance <= maxDistance) return true;
    }
    return false;
  }

  bool lastMilitarySurvivesAttack({
    required GameUnit attacker,
    required GameUnit defender,
    required CombatRuleset ruleset,
    CombatStats? attackerStats,
    CombatStats? defenderStats,
    int? currentHp,
  }) {
    final effectiveAttackerStats =
        attackerStats ?? UnitCombatStats.derive(attacker, ruleset: ruleset);
    final effectiveDefenderStats =
        defenderStats ?? UnitCombatStats.derive(defender, ruleset: ruleset);
    final defenderHp = UnitCombatHealth.currentHp(
      defender,
      effectiveStats: effectiveDefenderStats,
    );
    final minimumAttackDamage = _damageWithVariance(
      attack: effectiveAttackerStats.attack,
      defense: effectiveDefenderStats.defense,
      variance: -ruleset.varianceRange,
    );
    if (defenderHp <= minimumAttackDamage) return true;
    if (effectiveAttackerStats.range > 1 ||
        effectiveDefenderStats.attack <= 0) {
      return true;
    }

    final attackerHp =
        currentHp ??
        UnitCombatHealth.currentHp(
          attacker,
          effectiveStats: effectiveAttackerStats,
        );
    final maximumRetaliationDamage = _damageWithVariance(
      attack: effectiveDefenderStats.attack,
      defense: effectiveAttackerStats.defense,
      variance: ruleset.varianceRange,
    );
    return attackerHp > maximumRetaliationDamage;
  }

  bool isSafeLastMilitaryAttack(AiAttackEvaluation evaluation) {
    if (evaluation.defenderKilled ||
        evaluation.capturesCity ||
        evaluation.targetIsCivilian) {
      return true;
    }
    if (evaluation.rangedAttack && evaluation.attackerDamage == 0) {
      return true;
    }
    if (evaluation.defenderRetreated && evaluation.attackerDamage == 0) {
      return true;
    }
    return evaluation.defenderDamage >= evaluation.attackerDamage + 2 &&
        evaluation.attackerHpAfter * 5 >= evaluation.attackerHpBefore * 3;
  }

  int _visibleEnemyMilitaryCount(
    Iterable<GameUnit> units,
    CombatRuleset ruleset,
    String enemyPlayerId, {
    required bool includeDefensiveUnits,
  }) {
    var count = 0;
    for (final unit in units) {
      if (unit.ownerPlayerId != enemyPlayerId) continue;
      final stats = UnitCombatStats.derive(unit, ruleset: ruleset);
      if (stats.attack > 0 || (includeDefensiveUnits && stats.defense > 0)) {
        count += 1;
      }
    }
    return count;
  }

  int _damageWithVariance({
    required int attack,
    required int defense,
    required int variance,
  }) {
    if (attack <= 0) return 0;
    final raw = attack - defense + variance;
    return raw < 1 ? 1 : raw;
  }
}
