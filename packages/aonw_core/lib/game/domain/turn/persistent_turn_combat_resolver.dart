import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/game/domain/state/persistent_game_state.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_context.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_orchestrator.dart';
import 'package:aonw_core/game/domain/turn/combat/turn_combat_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

class PersistentTurnCombatResult {
  final PersistentGameState state;
  final List<GameEvent> events;

  const PersistentTurnCombatResult({
    required this.state,
    this.events = const [],
  });
}

/// Persistence adapter for the neutral turn-combat kernel.
abstract final class PersistentTurnCombatResolver {
  static PersistentTurnCombatResult resolve({
    required int turn,
    required PersistentGameState state,
    MapTileLookup? mapTiles,
    GameRuleset ruleset = GameRuleset.defaults,
  }) {
    if (state.runtimeState.intendedAttacks.isEmpty || state.units.isEmpty) {
      return PersistentTurnCombatResult(state: state);
    }
    final resolution = TurnCombatOrchestrator.resolve(
      state: TurnCombatState(
        units: state.units,
        cities: state.cities,
        artifacts: state.artifacts,
        intendedAttacks: state.runtimeState.intendedAttacks,
        diplomacy: state.runtimeState.diplomacy,
        resourceTradeAgreements: state.runtimeState.resourceTradeAgreements,
      ),
      context: TurnCombatContext(
        turn: turn,
        researchForPlayer: state.research.forPlayer,
        mapTiles: mapTiles,
        ruleset: ruleset,
      ),
    );
    final combatState = resolution.state;
    return PersistentTurnCombatResult(
      state: state.copyWith(
        units: combatState.units,
        cities: combatState.cities,
        artifacts: combatState.artifacts,
        runtimeState: state.runtimeState.copyWith(
          diplomacy: combatState.diplomacy,
          resourceTradeAgreements: combatState.resourceTradeAgreements,
        ),
      ),
      events: [...resolution.events],
    );
  }
}
