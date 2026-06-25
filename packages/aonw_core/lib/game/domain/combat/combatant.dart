import 'package:aonw_core/game/domain/combat/combat_modifier.dart';
import 'package:aonw_core/game/domain/combat/combat_stats.dart';
import 'package:aonw_core/util/collection_equality.dart';

class Combatant {
  final String unitId;
  final String ownerPlayerId;
  final CombatStats baseStats;
  final List<CombatModifier> modifiers;
  final int currentHp;

  Combatant({
    required this.unitId,
    required this.ownerPlayerId,
    required this.baseStats,
    List<CombatModifier> modifiers = const [],
    int? currentHp,
  }) : modifiers = List.unmodifiable(modifiers),
       currentHp = currentHp ?? baseStats.applyAll(modifiers).hp;

  CombatStats get effective => baseStats.applyAll(modifiers);

  int get maxHp => effective.hp;

  @override
  bool operator ==(Object other) {
    return other is Combatant &&
        other.unitId == unitId &&
        other.ownerPlayerId == ownerPlayerId &&
        other.baseStats == baseStats &&
        listEquals(other.modifiers, modifiers) &&
        other.currentHp == currentHp;
  }

  @override
  int get hashCode => Object.hash(
    unitId,
    ownerPlayerId,
    baseStats,
    Object.hashAll(modifiers),
    currentHp,
  );
}
