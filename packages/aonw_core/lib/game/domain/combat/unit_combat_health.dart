import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class UnitCombatHealth {
  static int currentHp(GameUnit unit, {required CombatStats effectiveStats}) {
    final maxHp = effectiveStats.hp;
    if (maxHp <= 0) return 0;
    final hp = unit.hitPoints ?? maxHp;
    return hp.clamp(0, maxHp).toInt();
  }

  static int clampHp(int hp, {required CombatStats effectiveStats}) {
    final maxHp = effectiveStats.hp;
    if (maxHp <= 0) return 0;
    return hp.clamp(0, maxHp).toInt();
  }
}
