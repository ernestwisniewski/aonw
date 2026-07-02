import 'package:aonw_core/game/domain/artifact/cultural_victory_progress.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/stability/cohesion_calculator.dart';
import 'package:aonw_core/game/domain/stability/core_city_locator.dart';
import 'package:aonw_core/game/domain/stability/stability_inputs.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:aonw_core/game/domain/stability/stability_source_catalog.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

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

    // Only controlPercent (controlled / valid tiles) is read below, and that is
    // independent of victory thresholds, so the standard rules are sufficient
    // here regardless of the match's actual VictoryRules.
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
          mapData: mapData,
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
    required MapData mapData,
    StabilityRuleset ruleset = StabilityRuleset.standard,
    int? warWeariness,
    double controlPercent = 0.0,
    int playerCount = 1,
    bool includeLuxuries = true,
  }) {
    final ownedCities = [
      for (final city in state.cities)
        if (city.ownerPlayerId == playerId) city,
    ];
    final coreCity = CoreCityLocator.coreCityFor(
      playerId: playerId,
      cities: ownedCities,
    );

    var conqueredCityCount = 0;
    var sumPopulationOverThreshold = 0;
    var sumCohesionCost = 0;
    var orderBuildingCount = 0;
    final luxuryResourceTypes = <ResourceType>{};

    for (final city in ownedCities) {
      final foundingOwnerPlayerId = city.foundingOwnerPlayerId;
      if (foundingOwnerPlayerId != null && foundingOwnerPlayerId != playerId) {
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

      for (final building in city.buildings) {
        if (StabilitySourceCatalog.orderBuildings.contains(building)) {
          orderBuildingCount += 1;
        }
      }

      // Luxuries are counted by presence on the empire's territory (a proxy for
      // the eventual connected-network semantics). Skipped by callers that want
      // to avoid the per-tile scan on a hot path (e.g. AI simulation).
      if (includeLuxuries) {
        for (final hex in city.territoryHexes) {
          final tile = mapData.tileAt(hex.col, hex.row);
          if (tile == null) continue;
          for (final resource in tile.resources) {
            if (StabilitySourceCatalog.luxuryResources.contains(resource)) {
              luxuryResourceTypes.add(resource);
            }
          }
        }
      }
    }

    final orderTechnologyCount = state.research
        .forPlayer(playerId)
        .unlockedTechnologyIds
        .where(StabilitySourceCatalog.orderTechnologies.contains)
        .length;
    final storedArtifactCount =
        CulturalVictoryProgressCalculator.storedArtifactCountFor(
          playerId: playerId,
          artifacts: state.artifacts,
          cities: state.cities,
        );

    return StabilityInputs(
      playerId: playerId,
      cityCount: ownedCities.length,
      conqueredCityCount: conqueredCityCount,
      sumCohesionCost: sumCohesionCost,
      sumPopulationOverThreshold: sumPopulationOverThreshold,
      buildingSources: orderBuildingCount * ruleset.stabilityPerOrderBuilding,
      luxurySources:
          luxuryResourceTypes.length * ruleset.stabilityPerLuxuryResource,
      techSources: orderTechnologyCount * ruleset.stabilityPerOrderTechnology,
      artifactSources: storedArtifactCount * ruleset.stabilityPerStoredArtifact,
      warWeariness: warWeariness ?? state.playerWarWeariness[playerId] ?? 0,
      controlPercent: controlPercent,
      playerCount: playerCount <= 0 ? 1 : playerCount,
    );
  }

  static List<String> orderedKnownPlayerIds(
    PersistentGameState state,
    Iterable<String> playerIds,
  ) {
    return <String>{
      ...playerIds,
      ...state.knownPlayerIds,
    }.where((playerId) => playerId.isNotEmpty).toList()..sort();
  }
}
