import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/objective/map_objective.dart';
import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/game/domain/state/persistent_game_state.dart';
import 'package:aonw_core/game/domain/technology/science_yield.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_context.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_orchestrator.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

class PersistentTurnEconomyResult {
  final PersistentGameState state;
  final List<GameEvent> events;
  final ScienceYieldBreakdown scienceGained;

  const PersistentTurnEconomyResult({
    required this.state,
    this.events = const [],
    this.scienceGained = ScienceYieldBreakdown.empty,
  });
}

/// Compatibility adapter for callers that still own persistent game state.
abstract final class PersistentTurnEconomyProcessor {
  static PersistentTurnEconomyResult advanceForPlayers({
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required MapReadView mapData,
    GameRuleset ruleset = GameRuleset.defaults,
    FogOfWarService fogOfWarService = const FogOfWarService(),
    Iterable<GameEvent> priorEvents = const [],
    Iterable<MapObjectiveDefinition> mapObjectives = const [],
    int? turn,
  }) {
    final result = TurnEconomyOrchestrator.advanceForPlayers(
      state: _toEconomyState(state),
      context: TurnEconomyContext(
        playerIds: playerIds,
        mapData: mapData,
        ruleset: ruleset,
        fogOfWarService: fogOfWarService,
        priorEvents: priorEvents,
        mapObjectives: mapObjectives,
        baseKnownPlayerIds: state.knownPlayerIds,
        countryForPlayer: state.countryForPlayer,
        turn: turn,
      ),
    );
    return PersistentTurnEconomyResult(
      state: _toPersistentState(state, result.state),
      events: result.events,
      scienceGained: result.scienceGained,
    );
  }
}

TurnEconomyState _toEconomyState(PersistentGameState state) {
  final runtime = state.runtimeState;
  return TurnEconomyState(
    playerGold: state.playerGold,
    playerWarWeariness: state.playerWarWeariness,
    playerStabilityNet: state.playerStabilityNet,
    units: state.units,
    cities: state.cities,
    artifacts: state.artifacts,
    fieldImprovements: state.fieldImprovements,
    fogOfWar: state.fogOfWar,
    research: state.research,
    wonderRegistry: state.wonderRegistry,
    diplomacy: runtime.diplomacy,
    resourceTradeAgreements: runtime.resourceTradeAgreements,
    mapObjectiveHoldStatesByObjectiveId:
        runtime.mapObjectiveHoldStatesByObjectiveId,
  );
}

PersistentGameState _toPersistentState(
  PersistentGameState source,
  TurnEconomyState economy,
) {
  return source.copyWith(
    playerGold: economy.playerGold,
    playerWarWeariness: economy.playerWarWeariness,
    playerStabilityNet: economy.playerStabilityNet,
    units: economy.units,
    cities: economy.cities,
    artifacts: economy.artifacts,
    fieldImprovements: economy.fieldImprovements,
    fogOfWar: economy.fogOfWar,
    research: economy.research,
    wonderRegistry: economy.wonderRegistry,
    runtimeState: source.runtimeState.copyWith(
      diplomacy: economy.diplomacy,
      resourceTradeAgreements: economy.resourceTradeAgreements,
      mapObjectiveHoldStatesByObjectiveId:
          economy.mapObjectiveHoldStatesByObjectiveId,
    ),
  );
}
