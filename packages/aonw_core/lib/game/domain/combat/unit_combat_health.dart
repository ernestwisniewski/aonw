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

  /// Returns the canonical persisted representation of combat HP.
  ///
  /// Full health is represented by `null`, matching newly created units and
  /// avoiding two serialized forms for the same domain state.
  static int? storedHp(int hp, {required CombatStats effectiveStats}) {
    return storedHpForMax(hp, maxHp: effectiveStats.hp);
  }

  static int? storedHpForMax(int hp, {required int maxHp}) {
    if (maxHp <= 0) return null;
    final clamped = hp.clamp(0, maxHp).toInt();
    return clamped >= maxHp ? null : clamped;
  }
}
