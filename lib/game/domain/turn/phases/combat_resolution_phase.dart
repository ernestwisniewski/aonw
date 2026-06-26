import 'package:aonw/game/domain/reducer/combat/combat_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw/game/domain/turn/turn_phase.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';

class CombatResolutionPhase extends TurnPhase {
  const CombatResolutionPhase();

  @override
  TurnContext apply(TurnContext context) {
    final intents = context.state.intendedAttacks;
    if (intents.isEmpty) return context;

    final ordered = [...intents]..sort(_compareIntents);
    var state = context.state.copyWith(intendedAttacks: const []);
    final events = [...context.events];
    final uiEffects = [...context.uiEffects];
    final instantRuleset = context.ruleset.combat.copyWith(
      resolutionMode: CombatResolutionMode.instant,
    );

    for (final intent in ordered) {
      final transition = CombatReducer.attackHexWithEnvironment(
        state,
        AttackHexCommand(
          intent.attackerUnitId,
          intent.defenderCol,
          intent.defenderRow,
          cityConquestAction: intent.cityConquestAction,
        ),
        ReducerEnvironment(
          mapData: context.mapData,
          ruleset: context.ruleset.copyWith(combat: instantRuleset),
          context: GameCommandContext(
            actorPlayerId: intent.declaringPlayerId,
            commandTick: intent.declaredAtTick,
            combatSeedTurn: context.save?.turn ?? 0,
          ),
        ),
      );
      state = transition.state.copyWith(intendedAttacks: const []);
      events.addAll(transition.events);
      uiEffects.addAll(transition.uiEffects);
    }

    return context.copyWith(state: state, events: events, uiEffects: uiEffects);
  }

  static int _compareIntents(IntendedAttack a, IntendedAttack b) {
    final tick = a.declaredAtTick.compareTo(b.declaredAtTick);
    if (tick != 0) return tick;
    return a.attackerUnitId.compareTo(b.attackerUnitId);
  }
}
