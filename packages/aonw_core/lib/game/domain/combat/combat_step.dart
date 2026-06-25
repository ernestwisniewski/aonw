import 'package:aonw_core/game/domain/combat/combat_modifier.dart';
import 'package:aonw_core/util/collection_equality.dart';

sealed class CombatStep {
  const CombatStep();
}

final class AttackStep extends CombatStep {
  final int damage;
  final List<CombatModifier> active;

  AttackStep({required this.damage, List<CombatModifier> active = const []})
    : active = List.unmodifiable(active);

  @override
  bool operator ==(Object other) {
    return other is AttackStep &&
        other.damage == damage &&
        listEquals(other.active, active);
  }

  @override
  int get hashCode => Object.hash(damage, Object.hashAll(active));
}

final class RetaliationStep extends CombatStep {
  final int damage;
  final List<CombatModifier> active;

  RetaliationStep({
    required this.damage,
    List<CombatModifier> active = const [],
  }) : active = List.unmodifiable(active);

  @override
  bool operator ==(Object other) {
    return other is RetaliationStep &&
        other.damage == damage &&
        listEquals(other.active, active);
  }

  @override
  int get hashCode => Object.hash(damage, Object.hashAll(active));
}

final class ModifierAppliedStep extends CombatStep {
  final CombatModifier modifier;

  const ModifierAppliedStep(this.modifier);

  @override
  bool operator ==(Object other) {
    return other is ModifierAppliedStep && other.modifier == modifier;
  }

  @override
  int get hashCode => modifier.hashCode;
}

final class RollStep extends CombatStep {
  final int seed;
  final int value;

  const RollStep({required this.seed, required this.value});

  @override
  bool operator ==(Object other) {
    return other is RollStep && other.seed == seed && other.value == value;
  }

  @override
  int get hashCode => Object.hash(seed, value);
}
