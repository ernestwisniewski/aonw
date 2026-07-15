import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/city/city_building_requirement.dart';
import 'package:aonw_core/game/domain/city/city_resource_inventory.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class CityBuildingRequirementRules {
  static const _coastalTerrains = {TerrainType.coast, TerrainType.ocean};

  static bool meetsRequirements({
    required GameCity city,
    required CityBuildingType buildingType,
    required MapTileLookup mapTiles,
    CityRuleset ruleset = CityRulesets.standard,
    ResearchState research = ResearchState.empty,
  }) {
    final definition = ruleset.buildingDefinitionFor(buildingType);
    return definition.requirements.every(
      (requirement) => _meetsRequirement(
        requirement,
        city: city,
        mapTiles: mapTiles,
        research: research,
      ),
    );
  }

  static bool hasCoastalAccess(GameCity city, MapTileLookup mapTiles) {
    for (final hex in city.territoryHexes) {
      final tile = mapTiles.tileAt(hex.col, hex.row);
      if (tile == null) continue;
      if (tile.terrains.any(_coastalTerrains.contains)) {
        return true;
      }
    }
    return false;
  }

  static bool controlsRequiredResource({
    required GameCity city,
    required Set<ResourceType> resources,
    required MapTileLookup mapTiles,
    ResearchState research = ResearchState.empty,
  }) {
    return CityResourceInventoryRules.forCity(
      city,
      mapTiles,
      research: research,
    ).controlsAny(resources);
  }

  static bool _meetsRequirement(
    CityBuildingRequirement requirement, {
    required GameCity city,
    required MapTileLookup mapTiles,
    required ResearchState research,
  }) {
    return switch (requirement) {
      CoastalAccessRequirement() => hasCoastalAccess(city, mapTiles),
      CityResourceRequirement(:final resources) => controlsRequiredResource(
        city: city,
        resources: resources,
        mapTiles: mapTiles,
        research: research,
      ),
    };
  }
}
