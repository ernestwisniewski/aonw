import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/turn/combat/city_combat_resolver.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_context.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_effects.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_state.dart';
import 'package:aonw_core/game/domain/turn/combat/unit_combat_resolver.dart';

abstract final class TurnCombatOrchestrator {
  static TurnCombatResolution resolve({
    required TurnCombatState state,
    required TurnCombatContext context,
  }) {
    final effects = TurnCombatEffects.fromState(state);
    final ordered = [...state.intendedAttacks]..sort(_compareIntents);
    for (final intent in ordered) {
      final attackerIndex = effects.unitIndexById(intent.attackerUnitId);
      if (attackerIndex == null) continue;
      final defenderIndex = effects.unitIndexAt(
        intent.defenderCol,
        intent.defenderRow,
        excludingUnitId: intent.attackerUnitId,
      );
      if (defenderIndex == null) {
        CityTurnCombatResolver.resolve(
          intent: intent,
          attackerIndex: attackerIndex,
          context: context,
          effects: effects,
        );
        continue;
      }
      UnitTurnCombatResolver.resolve(
        attackerIndex: attackerIndex,
        defenderIndex: defenderIndex,
        context: context,
        effects: effects,
      );
    }
    return effects.resolution();
  }

  static int _compareIntents(IntendedAttack a, IntendedAttack b) {
    final tick = a.declaredAtTick.compareTo(b.declaredAtTick);
    if (tick != 0) return tick;
    return a.attackerUnitId.compareTo(b.attackerUnitId);
  }
}
