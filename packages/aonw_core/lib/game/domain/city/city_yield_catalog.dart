import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class CityYieldCatalog {
  static const standardCityCenter = TileYield(
    food: 2,
    production: 1,
    gold: 0,
    defense: 0,
  );

  static const standardRiver = TileYield(
    food: 1,
    production: 0,
    gold: 0,
    defense: 0,
  );

  static const standardTerrainYields = {
    TerrainType.grassland: TileYield(
      food: 2,
      production: 0,
      gold: 0,
      defense: 0,
    ),
    TerrainType.plains: TileYield(food: 1, production: 1, gold: 0, defense: 0),
    TerrainType.forest: TileYield(food: 1, production: 1, gold: 0, defense: 0),
    TerrainType.hills: TileYield(food: 0, production: 2, gold: 0, defense: 0),
    TerrainType.tundra: TileYield(food: 1, production: 0, gold: 0, defense: 0),
    TerrainType.jungle: TileYield(food: 1, production: 0, gold: 0, defense: 0),
    TerrainType.wetlands: TileYield(
      food: 2,
      production: 0,
      gold: 0,
      defense: 0,
    ),
    TerrainType.coast: TileYield(food: 1, production: 0, gold: 0, defense: 0),
    TerrainType.lake: TileYield(food: 1, production: 0, gold: 0, defense: 0),
    TerrainType.desert: TileYield.zero,
    TerrainType.snow: TileYield.zero,
    TerrainType.mountain: TileYield.zero,
    TerrainType.ocean: TileYield.zero,
    TerrainType.river: TileYield.zero,
  };

  static const standardResourceYields = {
    ResourceType.wheat: TileYield(food: 2, production: 0, gold: 0, defense: 0),
    ResourceType.fish: TileYield(food: 2, production: 0, gold: 0, defense: 0),
    ResourceType.rice: TileYield(food: 2, production: 0, gold: 0, defense: 0),
    ResourceType.apple: TileYield(food: 2, production: 0, gold: 0, defense: 0),
    ResourceType.banana: TileYield(food: 2, production: 0, gold: 0, defense: 0),
    ResourceType.citrus: TileYield(food: 2, production: 0, gold: 0, defense: 0),
    ResourceType.deer: TileYield(food: 1, production: 1, gold: 0, defense: 0),
    ResourceType.cow: TileYield(food: 1, production: 1, gold: 0, defense: 0),
    ResourceType.sheep: TileYield(food: 1, production: 1, gold: 0, defense: 0),
    ResourceType.iron: TileYield(food: 0, production: 2, gold: 0, defense: 0),
    ResourceType.marble: TileYield(food: 0, production: 2, gold: 0, defense: 0),
    ResourceType.gold: TileYield.zero,
    ResourceType.silver: TileYield.zero,
    ResourceType.gems: TileYield.zero,
    ResourceType.silk: TileYield.zero,
    ResourceType.spices: TileYield.zero,
    ResourceType.cotton: TileYield.zero,
    ResourceType.grapes: TileYield.zero,
    ResourceType.ivory: TileYield.zero,
    ResourceType.pearls: TileYield.zero,
    ResourceType.coffee: TileYield.zero,
    ResourceType.cocoa: TileYield.zero,
    ResourceType.tobacco: TileYield.zero,
    ResourceType.sugar: TileYield.zero,
    ResourceType.coal: TileYield.zero,
    ResourceType.oil: TileYield.zero,
    ResourceType.aluminium: TileYield.zero,
    ResourceType.uranium: TileYield.zero,
    ResourceType.horses: TileYield.zero,
  };
}
