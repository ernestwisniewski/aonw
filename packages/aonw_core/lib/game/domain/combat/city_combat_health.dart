import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat/combat_stats.dart';

abstract final class CityCombatHealth {
  static int currentHp(GameCity city, {required CombatStats effectiveStats}) {
    final maxHp = effectiveStats.hp;
    if (maxHp <= 0) return 0;
    final hp = city.hitPoints ?? maxHp;
    return hp.clamp(0, maxHp).toInt();
  }

  static int clampHp(int hp, {required CombatStats effectiveStats}) {
    final maxHp = effectiveStats.hp;
    if (maxHp <= 0) return 0;
    return hp.clamp(0, maxHp).toInt();
  }

  static int? storedHp(int hp, {required CombatStats effectiveStats}) {
    final clamped = clampHp(hp, effectiveStats: effectiveStats);
    return clamped >= effectiveStats.hp ? null : clamped;
  }

  static int capturedHp({required CombatStats effectiveStats}) {
    final maxHp = effectiveStats.hp;
    if (maxHp <= 0) return 0;
    return (maxHp / 2).ceil().clamp(1, maxHp).toInt();
  }
}
