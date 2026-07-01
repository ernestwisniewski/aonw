import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/stability/cohesion_calculator.dart';
import 'package:aonw_core/game/domain/stability/stability_inputs.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class StabilityInputBuilder {
  static Map<String, StabilityInputs> forPlayers({
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required MapData mapData,
    StabilityRuleset ruleset = StabilityRuleset.standard,
    Map<String, int>? warWearinessByPlayerId,
  }) {
    final orderedPlayerIds = orderedKnownPlayerIds(state, playerIds);
    if (orderedPlayerIds.isEmpty) return const {};

    final domination = const DominationProgressCalculator().snapshot(
      playerIds: orderedPlayerIds,
      state: state,
      mapData: mapData,
      victoryRules: VictoryRules.standard,
    );

    return Map.unmodifiable({
      for (final playerId in orderedPlayerIds)
        playerId: forPlayer(
          state: state,
          playerId: playerId,
          ruleset: ruleset,
          warWeariness:
              warWearinessByPlayerId?[playerId] ??
              state.playerWarWeariness[playerId] ??
              0,
          controlPercent: domination.entryFor(playerId)?.controlPercent ?? 0.0,
          playerCount: orderedPlayerIds.length,
        ),
    });
  }

  static StabilityInputs forPlayer({
    required PersistentGameState state,
    required String playerId,
    StabilityRuleset ruleset = StabilityRuleset.standard,
    int? warWeariness,
    double controlPercent = 0.0,
    int playerCount = 1,
  }) {
    final ownedCities = [
      for (final city in state.cities)
        if (city.ownerPlayerId == playerId) city,
    ]..sort(_compareCities);
    final coreCity = _canonicalCoreCity(ownedCities, playerId);

    var conqueredCityCount = 0;
    var sumPopulationOverThreshold = 0;
    var sumCohesionCost = 0;

    for (final city in ownedCities) {
      final foundingOwnerPlayerId = city.foundingOwnerPlayerId;
      if (foundingOwnerPlayerId != null &&
          foundingOwnerPlayerId != playerId) {
        conqueredCityCount += 1;
      }

      final populationOverThreshold =
          city.population - ruleset.populationCostThreshold;
      if (populationOverThreshold > 0) {
        sumPopulationOverThreshold += populationOverThreshold;
      }

      if (coreCity != null) {
        sumCohesionCost += CohesionCalculator.cityCohesionCost(
          cityCenter: city.center.coordinate,
          nearestCoreCenter: coreCity.center.coordinate,
          isConnected: CityTerritoryRules.isConnected(
            center: city.center,
            controlledHexes: city.controlledHexes,
          ),
          ruleset: ruleset,
        );
      }
    }

    return StabilityInputs(
      playerId: playerId,
      cityCount: ownedCities.length,
      conqueredCityCount: conqueredCityCount,
      sumCohesionCost: sumCohesionCost,
      sumPopulationOverThreshold: sumPopulationOverThreshold,
      buildingSources: 0,
      luxurySources: 0,
      techSources: 0,
      artifactSources: 0,
      warWeariness: warWeariness ?? state.playerWarWeariness[playerId] ?? 0,
      controlPercent: controlPercent,
      playerCount: playerCount <= 0 ? 1 : playerCount,
    );
  }

  static List<String> orderedKnownPlayerIds(
    PersistentGameState state,
    Iterable<String> playerIds,
  ) {
    return {
      ...playerIds,
      ...state.playerColors.keys,
      ...state.playerCountries.keys,
      ...state.playerGold.keys,
      ...state.playerWarWeariness.keys,
      ...state.playerStabilityNet.keys,
      ...state.fogOfWar.playerIds,
      ...state.runtimeState.submittedPlayerIds,
      ...state.runtimeState.dominationHoldTurnsByPlayerId.keys,
      ...state.runtimeState.culturalVictoryHoldTurnsByPlayerId.keys,
      for (final unit in state.units) unit.ownerPlayerId,
      for (final city in state.cities) city.ownerPlayerId,
      for (final city in state.cities) ?city.foundingOwnerPlayerId,
      for (final relation in state.runtimeState.diplomacy.relations.values)
        relation.playerAId,
      for (final relation in state.runtimeState.diplomacy.relations.values)
        relation.playerBId,
    }.where((playerId) => playerId.isNotEmpty).toList()..sort();
  }

  static GameCity? _canonicalCoreCity(
    List<GameCity> ownedCities,
    String playerId,
  ) {
    if (ownedCities.isEmpty) return null;
    for (final city in ownedCities) {
      if (city.capitalOwnerPlayerId == playerId) return city;
    }
    return ownedCities.first;
  }

  static int _compareCities(GameCity a, GameCity b) {
    final byId = a.id.compareTo(b.id);
    if (byId != 0) return byId;
    final byCol = a.center.col.compareTo(b.center.col);
    if (byCol != 0) return byCol;
    return a.center.row.compareTo(b.center.row);
  }
}
