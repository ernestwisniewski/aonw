import 'package:aonw_core/game/domain/city/city_economy_breakdown.dart';
import 'package:aonw_core/game/domain/city/city_production_queue.dart';
import 'package:aonw_core/game/domain/city/city_production_target.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/city_yield_calculator.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_cost_rules.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_effect_summary.dart';
import 'package:aonw_core/game/domain/technology/technology_ruleset.dart';
import 'package:aonw_core/game/domain/technology/technology_rulesets.dart';
import 'package:aonw_core/game/domain/terrain/tile_terrain_profile_rules.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/map_player_capacity.dart';

class CityUnitSupplyBreakdown {
  const CityUnitSupplyBreakdown({
    required this.playerId,
    required this.capacity,
    required this.rawCapacity,
    required this.mapCapacity,
    required this.unitSupplyUsed,
    required this.queuedSupplyUsed,
    required this.citySupplyById,
    required this.usedSupplyByType,
  });

  final String playerId;
  final int capacity;
  final int rawCapacity;
  final int mapCapacity;
  final int unitSupplyUsed;
  final int queuedSupplyUsed;
  final Map<String, int> citySupplyById;
  final Map<GameUnitType, int> usedSupplyByType;

  int get used => unitSupplyUsed + queuedSupplyUsed;

  int get available {
    final remaining = capacity - used;
    return remaining < 0 ? 0 : remaining;
  }

  bool canQueue(GameUnitType type) {
    return used + CityUnitSupplyRules.supplyCostForType(type) <= capacity;
  }
}

abstract final class CityUnitSupplyRules {
  static const double targetLandUnitDensity = 0.22;
  static const int minimumMapCapacity = 12;
  static const int maximumMapCapacity = 28;

  static int supplyCostForType(GameUnitType type) {
    return switch (type) {
      GameUnitType.commander => 0,
      GameUnitType.settler => 1,
      GameUnitType.warrior ||
      GameUnitType.archer ||
      GameUnitType.worker ||
      GameUnitType.merchant ||
      GameUnitType.scout ||
      GameUnitType.spearman ||
      GameUnitType.scoutShip => 1,
      GameUnitType.cavalry ||
      GameUnitType.catapult ||
      GameUnitType.heavyInfantry ||
      GameUnitType.fieldCannon ||
      GameUnitType.rifleman ||
      GameUnitType.warship ||
      GameUnitType.reconPlane => 2,
      GameUnitType.tank => 3,
    };
  }

  static int maxCapacityForMap(MapData mapData) {
    final playerSlots = MapPlayerCapacityRules.maxPlayersForMapData(
      mapData,
    ).clamp(1, MapPlayerCapacityRules.absoluteMaxPlayers).toInt();
    final playableLandTiles = _playableLandTileCount(mapData);
    if (playableLandTiles <= 0) return minimumMapCapacity;

    final playableLandPerPlayer = playableLandTiles / playerSlots;
    final targetCapacity = (playableLandPerPlayer * targetLandUnitDensity)
        .round();
    return targetCapacity.clamp(minimumMapCapacity, maximumMapCapacity).toInt();
  }

  static CityUnitSupplyBreakdown forPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
    required MapData mapData,
    CityRuleset cityRuleset = CityRulesets.standard,
    ResearchState research = ResearchState.empty,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    String? replacingCityId,
  }) {
    final ownCities = [
      for (final city in cities)
        if (city.ownerPlayerId == playerId) city,
    ];
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: playerId,
      research: research,
      ruleset: technologyRuleset,
    );
    final citySupplyById = <String, int>{};
    var rawCapacity = 0;

    for (final city in ownCities) {
      final cityYield = CityYieldCalculator.totalFor(
        city,
        mapData,
        fieldImprovements: fieldImprovements,
        units: units,
        ruleset: cityRuleset,
      );
      final economy = CityEconomyBreakdown.from(
        city: city,
        tileYield: cityYield,
        mapData: mapData,
        ruleset: cityRuleset,
        technologyEffects: technologyEffects,
      );
      final citySupply = city.population + economy.netYield.food;
      final normalized = citySupply < 0 ? 0 : citySupply;
      citySupplyById[city.id] = normalized;
      rawCapacity += normalized;
    }
    final mapCapacity = maxCapacityForMap(mapData);
    final capacity = rawCapacity < mapCapacity ? rawCapacity : mapCapacity;

    var unitSupplyUsed = 0;
    final usedSupplyByType = <GameUnitType, int>{};
    for (final unit in units) {
      if (unit.ownerPlayerId != playerId) continue;
      final cost = supplyCostForType(unit.type);
      if (cost <= 0) continue;
      unitSupplyUsed += cost;
      usedSupplyByType[unit.type] = (usedSupplyByType[unit.type] ?? 0) + cost;
    }

    var queuedSupplyUsed = 0;
    for (final city in ownCities) {
      if (city.id == replacingCityId) continue;
      final queuedType = _queuedUnitType(city.productionQueue);
      if (queuedType == null) continue;
      queuedSupplyUsed += supplyCostForType(queuedType);
    }

    return CityUnitSupplyBreakdown(
      playerId: playerId,
      capacity: capacity,
      rawCapacity: rawCapacity,
      mapCapacity: mapCapacity,
      unitSupplyUsed: unitSupplyUsed,
      queuedSupplyUsed: queuedSupplyUsed,
      citySupplyById: Map.unmodifiable(citySupplyById),
      usedSupplyByType: Map.unmodifiable(usedSupplyByType),
    );
  }

  static bool canQueueUnit({
    required String playerId,
    required GameUnitType unitType,
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
    required MapData mapData,
    CityRuleset cityRuleset = CityRulesets.standard,
    ResearchState research = ResearchState.empty,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    String? replacingCityId,
    int reservedSupply = 0,
  }) {
    final breakdown = forPlayer(
      playerId: playerId,
      cities: cities,
      units: units,
      fieldImprovements: fieldImprovements,
      mapData: mapData,
      cityRuleset: cityRuleset,
      research: research,
      technologyRuleset: technologyRuleset,
      replacingCityId: replacingCityId,
    );
    return breakdown.used + reservedSupply + supplyCostForType(unitType) <=
        breakdown.capacity;
  }

  static GameUnitType? _queuedUnitType(CityProductionQueue? queue) {
    return switch (queue?.target) {
      UnitProductionTarget(:final unitType) => unitType,
      _ => null,
    };
  }

  static int _playableLandTileCount(MapData mapData) {
    var count = 0;
    for (final tile in mapData.tiles) {
      final profile = TileTerrainProfileRules.fromTile(tile);
      final movement = UnitMovementCostRules.costToEnter(profile);
      if (!movement.blocked) count++;
    }
    return count;
  }
}
