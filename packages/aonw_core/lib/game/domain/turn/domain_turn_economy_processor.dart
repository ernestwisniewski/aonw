import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/objective/map_objective.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset/game_ruleset.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/technology/science_yield.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_context.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_orchestrator.dart';
import 'package:aonw_core/game/domain/turn/economy/turn_economy_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class DomainTurnEconomyResult {
  const DomainTurnEconomyResult({
    required this.state,
    this.events = const [],
    this.scienceGained = ScienceYieldBreakdown.empty,
  });

  final DomainState state;
  final List<GameEvent> events;
  final ScienceYieldBreakdown scienceGained;
}

/// Canonical-state adapter for the persistence-neutral turn-economy kernel.
abstract final class DomainTurnEconomyProcessor {
  static DomainTurnEconomyResult advanceForPlayers({
    required DomainState state,
    required Iterable<String> playerIds,
    required MapReadView mapData,
    GameRuleset ruleset = GameRuleset.defaults,
    FogOfWarService fogOfWarService = const FogOfWarService(),
    Iterable<GameEvent> priorEvents = const [],
    Iterable<MapObjectiveDefinition> mapObjectives = const [],
  }) {
    final context = TurnEconomyContext(
      playerIds: playerIds,
      mapData: mapData,
      ruleset: ruleset,
      fogOfWarService: fogOfWarService,
      priorEvents: priorEvents,
      mapObjectives: mapObjectives,
      baseKnownPlayerIds: _baseKnownPlayerIds(state),
      countryForPlayer: (playerId) =>
          state.playerCountries[playerId] ?? PlayerCountry.poland,
      turn: state.turn,
    );
    _validateAdvancingPlayers(state, context.playerIds);
    final result = TurnEconomyOrchestrator.advanceForPlayers(
      state: _toEconomyState(state),
      context: context,
    );
    return DomainTurnEconomyResult(
      state: _toDomainState(state, result.state),
      events: result.events,
      scienceGained: result.scienceGained,
    );
  }
}

void _validateAdvancingPlayers(DomainState state, Iterable<String> playerIds) {
  final participantIds = {
    for (final participant in state.participants) participant.id,
  };
  final unknownPlayerIds =
      playerIds.where((playerId) => !participantIds.contains(playerId)).toList()
        ..sort();
  if (unknownPlayerIds.isEmpty) return;
  throw ArgumentError.value(
    unknownPlayerIds,
    'playerIds',
    'Economy players must belong to domain participants',
  );
}

TurnEconomyState _toEconomyState(DomainState state) {
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
    diplomacy: state.diplomacy,
    resourceTradeAgreements: state.resourceTradeAgreements,
    mapObjectiveHoldStatesByObjectiveId:
        state.mapObjectiveHoldStatesByObjectiveId,
  );
}

DomainState _toDomainState(DomainState source, TurnEconomyState economy) {
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
    diplomacy: economy.diplomacy,
    resourceTradeAgreements: economy.resourceTradeAgreements,
    mapObjectiveHoldStatesByObjectiveId:
        economy.mapObjectiveHoldStatesByObjectiveId,
  );
}

Set<String> _baseKnownPlayerIds(DomainState state) {
  return {for (final participant in state.participants) participant.id}
    ..removeWhere((playerId) => playerId.isEmpty);
}
