import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class MarkerHealthFraction {
  static double forUnit(GameUnit unit) {
    final stats = UnitCombatStats.derive(unit);
    final maxHp = stats.hp;
    if (maxHp <= 0) return 1.0;

    final currentHp = UnitCombatHealth.currentHp(unit, effectiveStats: stats);
    return (currentHp / maxHp).clamp(0.0, 1.0).toDouble();
  }

  static double forCity(
    GameCity city, {
    CombatRuleset ruleset = CombatRuleset.standard,
  }) {
    final stats = ruleset.cityBaseStats;
    final maxHp = stats.hp;
    if (maxHp <= 0) return 1.0;

    final currentHp = CityCombatHealth.currentHp(city, effectiveStats: stats);
    return (currentHp / maxHp).clamp(0.0, 1.0).toDouble();
  }
}
