import 'package:aonw_core/game/domain/city/city_building_requirement_rules.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/hex/hex_neighbors.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield_rules.dart';
import 'package:aonw_core/game/domain/wonder/wonder_requirement.dart';
import 'package:aonw_core/game/domain/wonder/wonder_ruleset.dart';
import 'package:aonw_core/game/domain/wonder/wonder_type.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class WonderRequirementRules {
  static bool meetsRequirements({
    required GameCity city,
    required WonderType wonderType,
    required MapData mapData,
    WonderRuleset ruleset = WonderRuleset.standard,
    ResearchState research = ResearchState.empty,
  }) {
    return missingRequirements(
      city: city,
      wonderType: wonderType,
      mapData: mapData,
      ruleset: ruleset,
      research: research,
    ).isEmpty;
  }

  static List<WonderRequirement> missingRequirements({
    required GameCity city,
    required WonderType wonderType,
    required MapData mapData,
    WonderRuleset ruleset = WonderRuleset.standard,
    ResearchState research = ResearchState.empty,
  }) {
    final definition = ruleset.definitionFor(wonderType);
    return [
      for (final requirement in definition.requirements)
        if (!_meetsRequirement(
          requirement,
          city: city,
          mapData: mapData,
          research: research,
        ))
          requirement,
    ];
  }

  static bool _meetsRequirement(
    WonderRequirement requirement, {
    required GameCity city,
    required MapData mapData,
    required ResearchState research,
  }) {
    return switch (requirement) {
      WonderCoastalAccessRequirement() =>
        CityBuildingRequirementRules.hasCoastalAccess(city, mapData),
      WonderResourceRequirement(:final resources) =>
        CityBuildingRequirementRules.controlsRequiredResource(
          city: city,
          resources: resources,
          mapData: mapData,
          research: research,
        ),
      WonderAdjacentRiverRequirement() => _hasAdjacentRiver(city, mapData),
      WonderAdjacentMountainRequirement() => _hasAdjacentMountain(
        city,
        mapData,
      ),
      WonderHostTerrainRequirement(:final allowedTerrains) => _hasHostTerrain(
        city,
        mapData,
        allowedTerrains,
      ),
    };
  }

  static bool _hasAdjacentRiver(GameCity city, MapData mapData) {
    for (final neighbor in HexNeighbors.existingAround(
      city.center.coordinate,
      mapData,
    )) {
      final tile = mapData.tileAt(neighbor.col, neighbor.row);
      if (tile != null && TileYieldRules.hasRiver(tile)) return true;
    }
    return false;
  }

  static bool _hasAdjacentMountain(GameCity city, MapData mapData) {
    for (final neighbor in HexNeighbors.existingAround(
      city.center.coordinate,
      mapData,
    )) {
      final tile = mapData.tileAt(neighbor.col, neighbor.row);
      if (tile != null &&
          TileYieldRules.baseTerrainFor(tile) == TerrainType.mountain) {
        return true;
      }
    }
    return false;
  }

  static bool _hasHostTerrain(
    GameCity city,
    MapData mapData,
    Set<TerrainType> allowedTerrains,
  ) {
    final tile = mapData.tileAt(city.center.col, city.center.row);
    if (tile == null) return false;
    return allowedTerrains.contains(TileYieldRules.baseTerrainFor(tile));
  }
}
