import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/game/domain/turn/persistent_city_hit_point_recovery_processor.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

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

abstract final class PersistentTurnEconomyProcessor {
  static PersistentTurnEconomyResult advanceForPlayers({
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required MapData mapData,
    GameRuleset ruleset = GameRuleset.defaults,
    FogOfWarService fogOfWarService = const FogOfWarService(),
    Iterable<GameEvent> priorEvents = const [],
    Iterable<MapObjectiveDefinition> mapObjectives = const [],
  }) {
    var current = state;
    final events = <GameEvent>[];
    var scienceGained = ScienceYieldBreakdown.empty;

    for (final playerId in _orderedDistinctPlayerIds(playerIds)) {
      final afterCities = _advanceCities(
        state: current,
        playerId: playerId,
        mapData: mapData,
        ruleset: ruleset,
        priorEvents: priorEvents,
      );
      current = afterCities.state;
      events.addAll(afterCities.events);
      scienceGained = _combineScience(scienceGained, afterCities.scienceGained);

      final afterResearch = _advanceResearch(
        state: current,
        playerId: playerId,
        mapData: mapData,
        ruleset: ruleset,
        bonusScience: afterCities.scienceGained,
      );
      current = afterResearch.state;
      events.addAll(afterResearch.events);

      final afterWorkers = _advanceWorkers(
        state: current,
        playerId: playerId,
        mapData: mapData,
        ruleset: ruleset,
      );
      current = afterWorkers.state;
      events.addAll(afterWorkers.events);

      final afterCityFoundingJobs = _advanceCityFoundingJobs(
        state: current,
        playerId: playerId,
        mapData: mapData,
        ruleset: ruleset,
      );
      current = afterCityFoundingJobs.state;
      events.addAll(afterCityFoundingJobs.events);

      final afterArtifacts = _advanceArtifacts(
        state: current,
        playerId: playerId,
      );
      current = afterArtifacts.state;
      events.addAll(afterArtifacts.events);
    }

    final previousMapObjectiveHoldStates =
        current.runtimeState.mapObjectiveHoldStatesByObjectiveId;
    final mapObjectiveHoldStates = mapObjectives.isEmpty
        ? previousMapObjectiveHoldStates
        : MapObjectiveRules.advanceHoldStates(
            objectives: mapObjectives,
            cities: current.cities,
            units: current.units,
            previousHoldStatesByObjectiveId: previousMapObjectiveHoldStates,
          );
    if (mapObjectives.isNotEmpty) {
      events.addAll(
        _mapObjectiveSecuredEvents(
          objectives: mapObjectives,
          previous: previousMapObjectiveHoldStates,
          next: mapObjectiveHoldStates,
        ),
      );
    }
    final runtimeState = current.runtimeState.copyWith(
      mapObjectiveHoldStatesByObjectiveId: mapObjectiveHoldStates,
    );
    current = current.copyWith(runtimeState: runtimeState);
    current = _applyMapObjectiveGold(
      state: current,
      playerIds: playerIds,
      objectives: mapObjectives,
      holdStatesByObjectiveId: mapObjectiveHoldStates,
    );
    current = _advanceResourceTrades(state: current, playerIds: playerIds);

    final fogOfWar = fogOfWarService.recompute(
      current: current.fogOfWar,
      mapData: mapData,
      playerIds: _knownPlayerIds(current),
      units: current.units,
      cities: current.cities,
    );

    return PersistentTurnEconomyResult(
      state: current.copyWith(fogOfWar: fogOfWar),
      events: List.unmodifiable(events),
      scienceGained: scienceGained,
    );
  }

  static PersistentGameState _applyMapObjectiveGold({
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required Iterable<MapObjectiveDefinition> objectives,
    required Map<String, MapObjectiveHoldState> holdStatesByObjectiveId,
  }) {
    final eligiblePlayerIds = _orderedDistinctPlayerIds(playerIds).toSet();
    if (eligiblePlayerIds.isEmpty) return state;

    final playerGold = Map<String, int>.from(state.playerGold);
    var changed = false;
    for (final objective in objectives) {
      if (objective.goldPerTurn <= 0) continue;
      final hold = holdStatesByObjectiveId[objective.id];
      if (hold == null ||
          !eligiblePlayerIds.contains(hold.playerId) ||
          hold.holdTurns < objective.requiredHoldTurns) {
        continue;
      }
      playerGold[hold.playerId] =
          (playerGold[hold.playerId] ?? 0) + objective.goldPerTurn;
      changed = true;
    }
    return changed
        ? state.copyWith(playerGold: Map.unmodifiable(playerGold))
        : state;
  }

  static List<MapObjectiveSecuredEvent> _mapObjectiveSecuredEvents({
    required Iterable<MapObjectiveDefinition> objectives,
    required Map<String, MapObjectiveHoldState> previous,
    required Map<String, MapObjectiveHoldState> next,
  }) {
    final events = <MapObjectiveSecuredEvent>[];
    for (final objective in objectives) {
      final nextHold = next[objective.id];
      if (nextHold == null) continue;
      if (nextHold.holdTurns < objective.requiredHoldTurns) continue;
      final previousHold = previous[objective.id];
      final alreadySecured =
          previousHold != null &&
          previousHold.playerId == nextHold.playerId &&
          previousHold.holdTurns >= objective.requiredHoldTurns;
      if (alreadySecured) continue;
      events.add(
        MapObjectiveSecuredEvent(
          playerId: nextHold.playerId,
          objectiveId: objective.id,
          objectiveType: objective.type,
          col: objective.hex.col,
          row: objective.hex.row,
          holdTurns: nextHold.holdTurns,
          requiredHoldTurns: objective.requiredHoldTurns,
          victoryPoints: objective.victoryPoints,
          goldPerTurn: objective.goldPerTurn,
        ),
      );
    }
    return events;
  }

  static PersistentGameState _advanceResourceTrades({
    required PersistentGameState state,
    required Iterable<String> playerIds,
  }) {
    final activeImporterIds = _orderedDistinctPlayerIds(playerIds).toSet();
    if (activeImporterIds.isEmpty ||
        state.runtimeState.resourceTradeAgreements.isEmpty) {
      return state;
    }

    final playerGold = Map<String, int>.from(state.playerGold);
    final nextAgreements = <ResourceTradeAgreement>[];
    var changed = false;

    for (final agreement in state.runtimeState.resourceTradeAgreements) {
      if (!agreement.isActive ||
          !activeImporterIds.contains(agreement.importerPlayerId)) {
        nextAgreements.add(agreement);
        continue;
      }

      final importerGold = playerGold[agreement.importerPlayerId] ?? 0;
      if (importerGold < agreement.goldPerTurn) {
        changed = true;
        continue;
      }

      final tradeBonus = DiplomaticRelationBenefits.resourceTradeGoldBonus(
        diplomacy: state.runtimeState.diplomacy,
        playerAId: agreement.importerPlayerId,
        playerBId: agreement.exporterPlayerId,
      );
      final exporterGoldPerTurn = agreement.goldPerTurn + tradeBonus;

      if (agreement.goldPerTurn > 0) {
        playerGold[agreement.importerPlayerId] =
            importerGold - agreement.goldPerTurn;
      }
      if (exporterGoldPerTurn > 0) {
        playerGold[agreement.exporterPlayerId] =
            (playerGold[agreement.exporterPlayerId] ?? 0) + exporterGoldPerTurn;
      }

      final remainingTurns = agreement.remainingTurns - 1;
      if (remainingTurns > 0) {
        nextAgreements.add(agreement.copyWith(remainingTurns: remainingTurns));
      }
      changed = true;
    }

    if (!changed) return state;
    return state.copyWith(
      playerGold: Map.unmodifiable(playerGold),
      runtimeState: state.runtimeState.copyWith(
        resourceTradeAgreements: List.unmodifiable(nextAgreements),
      ),
    );
  }

  static PersistentTurnEconomyResult _advanceCities({
    required PersistentGameState state,
    required String playerId,
    required MapData mapData,
    required GameRuleset ruleset,
    required Iterable<GameEvent> priorEvents,
  }) {
    final result = CityTurnProcessor.advanceForPlayer(
      playerId: playerId,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      mapData: mapData,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: ruleset.city,
      research: state.research,
      technologyRuleset: ruleset.technology,
      paceBalance: ruleset.paceBalance,
    );
    final nextCities = PersistentCityHitPointRecoveryProcessor.recoverForPlayer(
      cities: result.cities,
      artifacts: state.artifacts,
      events: priorEvents,
      combatRuleset: ruleset.combat,
      playerId: playerId,
    );
    final nextFieldImprovements = List<FieldImprovement>.unmodifiable(
      result.fieldImprovements,
    );
    final nextUnits = List<GameUnit>.unmodifiable(result.units);
    final unitUpkeep = UnitUpkeepRules.forPlayer(
      playerId: playerId,
      units: nextUnits,
      cities: nextCities,
    );

    return PersistentTurnEconomyResult(
      state: state.copyWith(
        units: nextUnits,
        cities: nextCities,
        fieldImprovements: nextFieldImprovements,
        playerGold: _addGoldDelta(
          state.playerGold,
          playerId,
          result.goldGained - unitUpkeep.total,
        ),
      ),
      events: _eventsFromCityTurn(
        previousCities: state.cities,
        cityEvents: result.events,
        updatedCities: nextCities,
      ),
      scienceGained: result.scienceGained,
    );
  }

  static PersistentTurnEconomyResult _advanceResearch({
    required PersistentGameState state,
    required String playerId,
    required MapData mapData,
    required GameRuleset ruleset,
    ScienceYieldBreakdown bonusScience = ScienceYieldBreakdown.empty,
  }) {
    final result = ResearchTurnProcessor.advanceForPlayer(
      playerId: playerId,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      research: state.research,
      mapData: mapData,
      ruleset: ruleset.technology,
      cityRuleset: ruleset.city,
      bonusScience: bonusScience,
      paceBalance: ruleset.paceBalance,
    );

    return PersistentTurnEconomyResult(
      state: state.copyWith(research: result.research),
      events: [
        if (result.scienceYield.total > 0)
          ResearchPointsGainedEvent(
            playerId: playerId,
            points: result.scienceYield.total,
          ),
        if (result.completedTechnologyId != null)
          TechnologyResearchedEvent(
            playerId: playerId,
            technologyId: result.completedTechnologyId!,
          ),
        if (result.completedTechnologyId != null)
          ...StrategicResourceDiscoveryRules.eventsForTechnology(
            playerId: playerId,
            technologyId: result.completedTechnologyId!,
            state: state,
            mapData: mapData,
          ),
      ],
    );
  }

  static PersistentTurnEconomyResult _advanceWorkers({
    required PersistentGameState state,
    required String playerId,
    required MapData mapData,
    required GameRuleset ruleset,
  }) {
    final result = WorkerTurnProcessor.advanceForPlayer(
      playerId: playerId,
      units: state.units,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      mapData: mapData,
    );
    final nextCities = List<GameCity>.unmodifiable(result.cities);
    final nextUnits = List<GameUnit>.unmodifiable(result.units);
    final nextFieldImprovements = List<FieldImprovement>.unmodifiable(
      result.fieldImprovements,
    );

    return PersistentTurnEconomyResult(
      state: state.copyWith(
        cities: nextCities,
        units: nextUnits,
        fieldImprovements: nextFieldImprovements,
      ),
      events: [
        ..._completedJobEvents(
          playerId: playerId,
          previousUnits: state.units,
          updatedUnits: nextUnits,
        ),
        ..._claimedHexEvents(
          previousCities: state.cities,
          updatedCities: nextCities,
        ),
      ],
    );
  }

  static PersistentTurnEconomyResult _advanceCityFoundingJobs({
    required PersistentGameState state,
    required String playerId,
    required MapData mapData,
    required GameRuleset ruleset,
  }) {
    final result = CityFoundingJobProcessor.advanceForPlayer(
      playerId: playerId,
      units: state.units,
      cities: state.cities,
      mapData: mapData,
      countryForPlayer: state.countryForPlayer,
      cityRuleset: ruleset.city,
    );
    final nextCities = List<GameCity>.unmodifiable(result.cities);
    final nextUnits = List<GameUnit>.unmodifiable(result.units);

    return PersistentTurnEconomyResult(
      state: state.copyWith(cities: nextCities, units: nextUnits),
      events: result.events,
    );
  }

  static PersistentTurnEconomyResult _advanceArtifacts({
    required PersistentGameState state,
    required String playerId,
  }) {
    final result = PersistentArtifactTurnProcessor.advanceForPlayers(
      state: state,
      playerIds: [playerId],
    );
    return PersistentTurnEconomyResult(state: result.state);
  }

  static Map<String, int> _addGoldDelta(
    Map<String, int> playerGold,
    String playerId,
    int amount,
  ) {
    if (playerId.isEmpty || amount == 0) return playerGold;
    final nextGold = (playerGold[playerId] ?? 0) + amount;
    return {...playerGold, playerId: nextGold < 0 ? 0 : nextGold};
  }

  static ScienceYieldBreakdown _combineScience(
    ScienceYieldBreakdown total,
    ScienceYieldBreakdown addition,
  ) {
    if (addition.total <= 0) return total;
    if (total.total <= 0) return addition;

    final byCityId = <String, int>{...total.byCityId};
    for (final entry in addition.byCityId.entries) {
      byCityId[entry.key] = (byCityId[entry.key] ?? 0) + entry.value;
    }

    return ScienceYieldBreakdown(
      total: total.total + addition.total,
      byCityId: Map.unmodifiable(byCityId),
      sources: List.unmodifiable([...total.sources, ...addition.sources]),
    );
  }

  static List<GameEvent> _eventsFromCityTurn({
    required List<GameCity> previousCities,
    required List<CityTurnEvent> cityEvents,
    required List<GameCity> updatedCities,
  }) {
    final previousCityById = {for (final city in previousCities) city.id: city};
    final updatedCityById = {for (final city in updatedCities) city.id: city};
    final events = <GameEvent>[];

    for (final cityEvent in cityEvents) {
      switch (cityEvent.type) {
        case CityTurnEventType.builtBuilding:
          final previousCity = previousCityById[cityEvent.cityId];
          final updatedCity = updatedCityById[cityEvent.cityId];
          if (previousCity == null || updatedCity == null) break;
          final newBuildings = updatedCity.buildings.difference(
            previousCity.buildings,
          );
          final buildingType = newBuildings.firstOrNull;
          if (buildingType != null) {
            events.add(
              CityBuiltBuildingEvent(
                cityId: cityEvent.cityId,
                buildingType: buildingType,
              ),
            );
          }
        case CityTurnEventType.producedUnit:
          final producedUnit = cityEvent.producedUnit;
          if (producedUnit != null) {
            events.add(
              CityProducedUnitEvent(
                cityId: cityEvent.cityId,
                unitType: producedUnit.type,
                producedUnitId: producedUnit.id,
              ),
            );
          }
        case CityTurnEventType.grew:
          break;
        case CityTurnEventType.claimedHex:
          final hex = cityEvent.hex;
          if (hex != null) {
            events.add(
              CityClaimedHexEvent(
                cityId: cityEvent.cityId,
                col: hex.col,
                row: hex.row,
              ),
            );
          }
      }
    }

    return events;
  }

  static List<GameEvent> _completedJobEvents({
    required String playerId,
    required List<GameUnit> previousUnits,
    required List<GameUnit> updatedUnits,
  }) {
    final updatedById = {for (final unit in updatedUnits) unit.id: unit};
    return [
      for (final previous in previousUnits)
        if (previous.ownerPlayerId == playerId &&
            previous.workerJob != null &&
            updatedById[previous.id]?.workerJob == null)
          WorkerCompletedJobEvent(unitId: previous.id),
    ];
  }

  static List<GameEvent> _claimedHexEvents({
    required List<GameCity> previousCities,
    required List<GameCity> updatedCities,
  }) {
    final previousById = {for (final city in previousCities) city.id: city};
    final events = <GameEvent>[];
    for (final city in updatedCities) {
      final previous = previousById[city.id];
      if (previous == null) continue;
      final previousHexes = previous.controlledHexes.toSet();
      for (final hex in city.controlledHexes) {
        if (previousHexes.contains(hex)) continue;
        events.add(
          CityClaimedHexEvent(cityId: city.id, col: hex.col, row: hex.row),
        );
      }
    }
    return events;
  }

  static List<String> _orderedDistinctPlayerIds(Iterable<String> playerIds) {
    return {
      for (final playerId in playerIds)
        if (playerId.isNotEmpty) playerId,
    }.toList()..sort();
  }

  static Set<String> _knownPlayerIds(PersistentGameState state) {
    return {
      ...state.playerColors.keys,
      ...state.playerGold.keys,
      ...state.fogOfWar.playerIds,
      for (final unit in state.units) unit.ownerPlayerId,
      for (final city in state.cities) city.ownerPlayerId,
    };
  }
}
