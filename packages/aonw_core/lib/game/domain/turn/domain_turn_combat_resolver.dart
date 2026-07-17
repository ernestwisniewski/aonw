import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_context.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_orchestrator.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainTurnCombatResult {
  const DomainTurnCombatResult({required this.state, this.events = const []});

  final DomainState state;
  final List<GameEvent> events;
}

/// Canonical-state adapter for the persistence-neutral turn-combat kernel.
abstract final class DomainTurnCombatResolver {
  static DomainTurnCombatResult resolve({
    required DomainState state,
    MapTileLookup? mapTiles,
    GameRuleset ruleset = GameRuleset.defaults,
  }) {
    if (state.intendedAttacks.isEmpty || state.units.isEmpty) {
      return DomainTurnCombatResult(state: state);
    }
    final resolution = TurnCombatOrchestrator.resolve(
      state: TurnCombatState(
        units: state.units,
        cities: state.cities,
        artifacts: state.artifacts,
        intendedAttacks: state.intendedAttacks,
        diplomacy: state.diplomacy,
        resourceTradeAgreements: state.resourceTradeAgreements,
      ),
      context: TurnCombatContext(
        turn: state.turn,
        researchForPlayer: state.research.forPlayer,
        mapTiles: mapTiles,
        ruleset: ruleset,
      ),
    );
    final combatState = resolution.state;
    return DomainTurnCombatResult(
      state: state.copyWith(
        units: combatState.units,
        cities: combatState.cities,
        artifacts: combatState.artifacts,
        diplomacy: combatState.diplomacy,
        resourceTradeAgreements: combatState.resourceTradeAgreements,
      ),
      events: resolution.events,
    );
  }
}
