import 'package:aonw_core/game/domain/combat/combat_ruleset.dart';
import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class UnitCombatStats {
  static CombatStats derive(
    GameUnit unit, {
    CombatRuleset ruleset = CombatRuleset.standard,
  }) {
    if (unit.type == GameUnitType.commander) {
      return _commanderStats(unit, ruleset);
    }
    return ruleset.baseStatsFor(unit.type);
  }

  static CombatStats _commanderStats(
    GameUnit commander,
    CombatRuleset ruleset,
  ) {
    var stats = ruleset.commanderBaseStats;
    for (final troop in commander.army) {
      final troopStats = ruleset.statsForTroop(troop.type);
      stats = stats.copyWith(
        attack: stats.attack + troopStats.attack * troop.count,
        defense: stats.defense + troopStats.defense * troop.count,
        hp: stats.hp + troopStats.hp * troop.count,
      );
    }
    return stats;
  }
}
