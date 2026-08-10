import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/map_validation/map_validation_model.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/terrain.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

const _foodResources = <ResourceType>{
  ResourceType.wheat,
  ResourceType.fish,
  ResourceType.deer,
  ResourceType.sheep,
  ResourceType.rice,
  ResourceType.cow,
  ResourceType.apple,
  ResourceType.banana,
  ResourceType.citrus,
};

const _luxuryResources = <ResourceType>{
  ResourceType.gold,
  ResourceType.silver,
  ResourceType.gems,
  ResourceType.silk,
  ResourceType.spices,
  ResourceType.cotton,
  ResourceType.grapes,
  ResourceType.ivory,
  ResourceType.pearls,
  ResourceType.coffee,
  ResourceType.cocoa,
  ResourceType.tobacco,
  ResourceType.sugar,
};

const _strategicResources = <ResourceType>{
  ResourceType.iron,
  ResourceType.coal,
  ResourceType.oil,
  ResourceType.aluminium,
  ResourceType.uranium,
  ResourceType.horses,
  ResourceType.marble,
};

abstract final class MapResourceAnalyzer {
  static int passableTileCount(WorldMap mapData) =>
      mapData.tiles.where(isPassable).length;

  static MapResourceSummary summary(WorldMap mapData) {
    var resourceTiles = 0;
    var foodResources = 0;
    var luxuryResources = 0;
    var strategicResources = 0;
    for (final tile in mapData.tiles) {
      if (tile.resources.isNotEmpty) resourceTiles++;
      for (final resource in tile.resources) {
        if (isFoodResource(resource)) foodResources++;
        if (_luxuryResources.contains(resource)) luxuryResources++;
        if (_strategicResources.contains(resource)) strategicResources++;
      }
    }
    return MapResourceSummary(
      resourceTiles: resourceTiles,
      foodResources: foodResources,
      luxuryResources: luxuryResources,
      strategicResources: strategicResources,
    );
  }

  static bool isPassable(WorldTile tile) {
    return !UnitMovementCostRules.costToEnter(
      TileTerrainProfileRules.fromTile(tile),
    ).blocked;
  }

  static bool isFoodResource(ResourceType resource) =>
      _foodResources.contains(resource);
}
