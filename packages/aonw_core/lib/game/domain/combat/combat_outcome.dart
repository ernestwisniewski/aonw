import 'package:aonw_core/game/domain/combat/combat_step.dart';
import 'package:aonw_core/util/collection_equality.dart';

class CombatOutcome {
  final String attackerUnitId;
  final String defenderUnitId;
  final int attackerHpAfter;
  final int defenderHpAfter;
  final bool attackerKilled;
  final bool defenderKilled;
  final bool defenderRetreated;
  final List<CombatStep> steps;

  CombatOutcome({
    required this.attackerUnitId,
    required this.defenderUnitId,
    required this.attackerHpAfter,
    required this.defenderHpAfter,
    required this.attackerKilled,
    required this.defenderKilled,
    this.defenderRetreated = false,
    List<CombatStep> steps = const [],
  }) : steps = List.unmodifiable(steps);

  @override
  bool operator ==(Object other) {
    return other is CombatOutcome &&
        other.attackerUnitId == attackerUnitId &&
        other.defenderUnitId == defenderUnitId &&
        other.attackerHpAfter == attackerHpAfter &&
        other.defenderHpAfter == defenderHpAfter &&
        other.attackerKilled == attackerKilled &&
        other.defenderKilled == defenderKilled &&
        other.defenderRetreated == defenderRetreated &&
        listEquals(other.steps, steps);
  }

  @override
  int get hashCode => Object.hash(
    attackerUnitId,
    defenderUnitId,
    attackerHpAfter,
    defenderHpAfter,
    attackerKilled,
    defenderKilled,
    defenderRetreated,
    Object.hashAll(steps),
  );
}
