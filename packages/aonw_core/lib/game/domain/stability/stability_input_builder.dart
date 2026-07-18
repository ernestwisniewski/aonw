import 'package:aonw_core/game/domain/artifact/cultural_victory_progress_resolver.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/outcome/domination_progress_resolver.dart';
import 'package:aonw_core/game/domain/stability/cohesion_calculator.dart';
import 'package:aonw_core/game/domain/stability/core_city_locator.dart';
import 'package:aonw_core/game/domain/stability/stability_inputs.dart';
import 'package:aonw_core/game/domain/stability/stability_ruleset.dart';
import 'package:aonw_core/game/domain/stability/stability_source_catalog.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/wonder/wonder_effect_resolver.dart';
import 'package:aonw_core/game/domain/wonder/wonder_registry.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class StabilityInputBuilder {
  static Map<String, StabilityInputs> forPlayers({
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required MapReadView mapData,
    StabilityRuleset ruleset = StabilityRuleset.standard,
    Map<String, int>? warWearinessByPlayerId,
  }) {
    return forPlayersFromCollections(
      cities: state.cities,
      artifacts: state.artifacts,
      research: state.research,
      wonderRegistry: state.wonderRegistry,
      knownPlayerIds: state.knownPlayerIds,
      playerIds: playerIds,
      mapData: mapData,
      ruleset: ruleset,
      warWearinessByPlayerId:
          warWearinessByPlayerId ?? state.playerWarWeariness,
    );
  }

  /// Builds stability inputs without depending on a persistence model.
  static Map<String, StabilityInputs> forPlayersFromCollections({
    required Iterable<GameCity> cities,
    required Iterable<WorldArtifact> artifacts,
    required ResearchState research,
    required WonderRegistry wonderRegistry,
    required Iterable<String> knownPlayerIds,
    required Iterable<String> playerIds,
    required MapReadView mapData,
    StabilityRuleset ruleset = StabilityRuleset.standard,
    Map<String, int> warWearinessByPlayerId = const {},
  }) {
    final players = orderedKnownPlayerIdsFrom(
      knownPlayerIds: knownPlayerIds,
      playerIds: playerIds,
    );
    if (players.isEmpty) return const {};
    final cityList = List<GameCity>.unmodifiable(cities);
    final artifactList = List<WorldArtifact>.unmodifiable(artifacts);
    final domination = const DominationProgressResolver().snapshot(
      playerIds: players,
      cities: cityList,
      mapCatalog: mapData,
      victoryRules: VictoryRules.standard,
    );
    return Map.unmodifiable({
      for (final playerId in players)
        playerId: forPlayerFromCollections(
          cities: cityList,
          artifacts: artifactList,
          research: research,
          wonderRegistry: wonderRegistry,
          playerId: playerId,
          mapData: mapData,
          ruleset: ruleset,
          warWeariness: warWearinessByPlayerId[playerId] ?? 0,
          controlPercent: domination.entryFor(playerId)?.controlPercent ?? 0.0,
          playerCount: players.length,
        ),
    });
  }

  static ({double controlPercent, int playerCount}) hegemonyContextFor({
    required PersistentGameState state,
    required String playerId,
    required MapReadView mapData,
  }) {
    return hegemonyContextFromCollections(
      cities: state.cities,
      knownPlayerIds: state.knownPlayerIds,
      playerId: playerId,
      mapData: mapData,
    );
  }

  /// Calculates hegemony context from explicit domain collections.
  static ({double controlPercent, int playerCount})
  hegemonyContextFromCollections({
    required Iterable<GameCity> cities,
    required Iterable<String> knownPlayerIds,
    required String playerId,
    required MapReadView mapData,
  }) {
    final players = orderedKnownPlayerIdsFrom(
      knownPlayerIds: knownPlayerIds,
      playerIds: [playerId],
    );
    if (players.isEmpty) return (controlPercent: 0.0, playerCount: 1);
    final domination = const DominationProgressResolver().snapshot(
      playerIds: players,
      cities: cities,
      mapCatalog: mapData,
      victoryRules: VictoryRules.standard,
    );
    return (
      controlPercent: domination.entryFor(playerId)?.controlPercent ?? 0.0,
      playerCount: players.length,
    );
  }

  static StabilityInputs forPlayer({
    required PersistentGameState state,
    required String playerId,
    required MapReadView mapData,
    StabilityRuleset ruleset = StabilityRuleset.standard,
    int? warWeariness,
    double controlPercent = 0.0,
    int playerCount = 1,
    bool includeLuxuries = true,
  }) {
    return forPlayerFromCollections(
      cities: state.cities,
      artifacts: state.artifacts,
      research: state.research,
      wonderRegistry: state.wonderRegistry,
      playerId: playerId,
      mapData: mapData,
      ruleset: ruleset,
      warWeariness: warWeariness ?? state.playerWarWeariness[playerId] ?? 0,
      controlPercent: controlPercent,
      playerCount: playerCount,
      includeLuxuries: includeLuxuries,
    );
  }

  /// Builds one player's inputs from explicit domain collections.
  static StabilityInputs forPlayerFromCollections({
    required Iterable<GameCity> cities,
    required Iterable<WorldArtifact> artifacts,
    required ResearchState research,
    required WonderRegistry wonderRegistry,
    required String playerId,
    required MapReadView mapData,
    StabilityRuleset ruleset = StabilityRuleset.standard,
    int warWeariness = 0,
    double controlPercent = 0.0,
    int playerCount = 1,
    bool includeLuxuries = true,
  }) {
    final cityList = List<GameCity>.unmodifiable(cities);
    final artifactList = List<WorldArtifact>.unmodifiable(artifacts);
    final metrics = _cityMetricsFor(
      cities: cityList,
      playerId: playerId,
      mapData: mapData,
      ruleset: ruleset,
      includeLuxuries: includeLuxuries,
    );
    return StabilityInputs(
      playerId: playerId,
      cityCount: metrics.cityCount,
      conqueredCityCount: metrics.conqueredCityCount,
      sumCohesionCost: metrics.sumCohesionCost,
      sumPopulationOverThreshold: metrics.sumPopulationOverThreshold,
      buildingSources:
          metrics.orderBuildingCount * ruleset.stabilityPerOrderBuilding,
      luxurySources:
          metrics.luxuryResourceCount * ruleset.stabilityPerLuxuryResource,
      techSources:
          _orderTechnologyCount(research, playerId) *
          ruleset.stabilityPerOrderTechnology,
      artifactSources:
          const CulturalVictoryProgressResolver().storedArtifactCountFor(
            playerId: playerId,
            artifacts: artifactList,
            cities: cityList,
          ) *
          ruleset.stabilityPerStoredArtifact,
      wonderSources: WonderEffectResolver.stabilityForPlayer(
        playerId: playerId,
        cities: cityList,
        registry: wonderRegistry,
      ),
      warWeariness: warWeariness,
      controlPercent: controlPercent,
      playerCount: playerCount <= 0 ? 1 : playerCount,
    );
  }

  static List<String> orderedKnownPlayerIds(
    PersistentGameState state,
    Iterable<String> playerIds,
  ) {
    return orderedKnownPlayerIdsFrom(
      knownPlayerIds: state.knownPlayerIds,
      playerIds: playerIds,
    );
  }

  static List<String> orderedKnownPlayerIdsFrom({
    required Iterable<String> knownPlayerIds,
    required Iterable<String> playerIds,
  }) {
    return <String>{
      ...playerIds,
      ...knownPlayerIds,
    }.where((playerId) => playerId.isNotEmpty).toList()..sort();
  }

  static _StabilityCityMetrics _cityMetricsFor({
    required List<GameCity> cities,
    required String playerId,
    required MapReadView mapData,
    required StabilityRuleset ruleset,
    required bool includeLuxuries,
  }) {
    final ownedCities = [
      for (final city in cities)
        if (city.ownerPlayerId == playerId) city,
    ];
    final coreCity = CoreCityLocator.coreCityFor(
      playerId: playerId,
      cities: ownedCities,
    );
    var conqueredCityCount = 0;
    var populationOverThreshold = 0;
    var cohesionCost = 0;
    var orderBuildingCount = 0;
    final luxuries = <ResourceType>{};
    for (final city in ownedCities) {
      if (city.foundingOwnerPlayerId case final founder?
          when founder != playerId) {
        conqueredCityCount += 1;
      }
      final population = city.population - ruleset.populationCostThreshold;
      if (population > 0) populationOverThreshold += population;
      if (coreCity != null) {
        cohesionCost += _cohesionCost(city, coreCity, ruleset);
      }
      orderBuildingCount += city.buildings
          .where(StabilitySourceCatalog.orderBuildings.contains)
          .length;
      if (includeLuxuries) _addLuxuries(luxuries, city, mapData);
    }
    return _StabilityCityMetrics(
      cityCount: ownedCities.length,
      conqueredCityCount: conqueredCityCount,
      sumPopulationOverThreshold: populationOverThreshold,
      sumCohesionCost: cohesionCost,
      orderBuildingCount: orderBuildingCount,
      luxuryResourceCount: luxuries.length,
    );
  }

  static int _cohesionCost(
    GameCity city,
    GameCity coreCity,
    StabilityRuleset ruleset,
  ) {
    return CohesionCalculator.cityCohesionCost(
      cityCenter: city.center.coordinate,
      nearestCoreCenter: coreCity.center.coordinate,
      isConnected: CityTerritoryRules.isConnected(
        center: city.center,
        controlledHexes: city.controlledHexes,
      ),
      ruleset: ruleset,
    );
  }

  static void _addLuxuries(
    Set<ResourceType> luxuries,
    GameCity city,
    MapReadView mapData,
  ) {
    for (final hex in city.territoryHexes) {
      final tile = mapData.tileAt(hex.col, hex.row);
      if (tile == null) continue;
      for (final resource in tile.resources) {
        if (StabilitySourceCatalog.luxuryResources.contains(resource)) {
          luxuries.add(resource);
        }
      }
    }
  }

  static int _orderTechnologyCount(ResearchState research, String playerId) {
    return research
        .forPlayer(playerId)
        .unlockedTechnologyIds
        .where(StabilitySourceCatalog.orderTechnologies.contains)
        .length;
  }
}

final class _StabilityCityMetrics {
  const _StabilityCityMetrics({
    required this.cityCount,
    required this.conqueredCityCount,
    required this.sumCohesionCost,
    required this.sumPopulationOverThreshold,
    required this.orderBuildingCount,
    required this.luxuryResourceCount,
  });

  final int cityCount;
  final int conqueredCityCount;
  final int sumCohesionCost;
  final int sumPopulationOverThreshold;
  final int orderBuildingCount;
  final int luxuryResourceCount;
}
