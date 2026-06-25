import 'package:aonw_core/game/domain/city/field_improvement_definition.dart';
import 'package:aonw_core/game/domain/city/field_improvement_requirement.dart';
import 'package:aonw_core/game/domain/city/field_improvement_type.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class FieldImprovementCatalog {
  static const standard = {
    FieldImprovementType.fishingBoats: FieldImprovementDefinition(
      type: FieldImprovementType.fishingBoats,
      tileYield: TileYield(food: 2, production: 0, gold: 0, defense: 0),
      buildTurns: 3,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({ResourceType.fish}),
      ],
    ),
    FieldImprovementType.pasture: FieldImprovementDefinition(
      type: FieldImprovementType.pasture,
      tileYield: TileYield(food: 1, production: 1, gold: 0, defense: 0),
      buildTurns: 3,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({ResourceType.cow, ResourceType.sheep}),
      ],
    ),
    FieldImprovementType.camp: FieldImprovementDefinition(
      type: FieldImprovementType.camp,
      tileYield: TileYield(food: 1, production: 1, gold: 0, defense: 0),
      buildTurns: 3,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({ResourceType.deer}),
      ],
    ),
    FieldImprovementType.quarry: FieldImprovementDefinition(
      type: FieldImprovementType.quarry,
      tileYield: TileYield(food: 0, production: 2, gold: 0, defense: 0),
      buildTurns: 3,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({ResourceType.marble}),
      ],
    ),
    FieldImprovementType.orchard: FieldImprovementDefinition(
      type: FieldImprovementType.orchard,
      tileYield: TileYield(food: 1, production: 0, gold: 1, defense: 0),
      buildTurns: 3,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({
          ResourceType.apple,
          ResourceType.banana,
          ResourceType.citrus,
        }),
      ],
    ),
    FieldImprovementType.plantation: FieldImprovementDefinition(
      type: FieldImprovementType.plantation,
      tileYield: TileYield(food: 1, production: 0, gold: 2, defense: 0),
      buildTurns: 4,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({
          ResourceType.silk,
          ResourceType.spices,
          ResourceType.cotton,
          ResourceType.coffee,
          ResourceType.cocoa,
          ResourceType.tobacco,
          ResourceType.sugar,
        }),
      ],
    ),
    FieldImprovementType.vineyard: FieldImprovementDefinition(
      type: FieldImprovementType.vineyard,
      tileYield: TileYield(food: 1, production: 0, gold: 2, defense: 0),
      buildTurns: 3,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({ResourceType.grapes}),
      ],
    ),
    FieldImprovementType.tradingPost: FieldImprovementDefinition(
      type: FieldImprovementType.tradingPost,
      tileYield: TileYield(food: 0, production: 0, gold: 3, defense: 0),
      buildTurns: 3,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({ResourceType.ivory}),
      ],
    ),
    FieldImprovementType.prospectorCamp: FieldImprovementDefinition(
      type: FieldImprovementType.prospectorCamp,
      tileYield: TileYield(food: 0, production: 1, gold: 2, defense: 0),
      buildTurns: 4,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({
          ResourceType.gold,
          ResourceType.silver,
          ResourceType.gems,
        }),
      ],
    ),
    FieldImprovementType.horseRanch: FieldImprovementDefinition(
      type: FieldImprovementType.horseRanch,
      tileYield: TileYield(food: 1, production: 1, gold: 0, defense: 0),
      buildTurns: 3,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({ResourceType.horses}),
      ],
    ),
    FieldImprovementType.pearlDivers: FieldImprovementDefinition(
      type: FieldImprovementType.pearlDivers,
      tileYield: TileYield(food: 1, production: 0, gold: 3, defense: 0),
      buildTurns: 4,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({ResourceType.pearls}),
      ],
    ),
    FieldImprovementType.coalShaft: FieldImprovementDefinition(
      type: FieldImprovementType.coalShaft,
      tileYield: TileYield(food: 0, production: 3, gold: 0, defense: 0),
      buildTurns: 4,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({ResourceType.coal}),
      ],
    ),
    FieldImprovementType.oilWell: FieldImprovementDefinition(
      type: FieldImprovementType.oilWell,
      tileYield: TileYield(food: 0, production: 2, gold: 2, defense: 0),
      buildTurns: 5,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({ResourceType.oil}),
      ],
    ),
    FieldImprovementType.bauxiteMine: FieldImprovementDefinition(
      type: FieldImprovementType.bauxiteMine,
      tileYield: TileYield(food: 0, production: 3, gold: 1, defense: 0),
      buildTurns: 5,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({ResourceType.aluminium}),
      ],
    ),
    FieldImprovementType.uraniumMine: FieldImprovementDefinition(
      type: FieldImprovementType.uraniumMine,
      tileYield: TileYield(food: 0, production: 2, gold: 2, defense: 0),
      buildTurns: 5,
      resourceSpecialist: true,
      requirements: [
        RequiresAnyResource({ResourceType.uranium}),
      ],
    ),
    FieldImprovementType.riverFarm: FieldImprovementDefinition(
      type: FieldImprovementType.riverFarm,
      tileYield: TileYield(food: 2, production: 0, gold: 0, defense: 0),
      buildTurns: 2,
      requirements: [
        RequiresAnyBaseTerrain({TerrainType.grassland, TerrainType.plains}),
        RequiresRiver(),
      ],
    ),
    FieldImprovementType.farm: FieldImprovementDefinition(
      type: FieldImprovementType.farm,
      tileYield: TileYield(food: 1, production: 0, gold: 0, defense: 0),
      buildTurns: 2,
      requirements: [
        RequiresAnyBaseTerrain({TerrainType.grassland, TerrainType.plains}),
      ],
    ),
    FieldImprovementType.mine: FieldImprovementDefinition(
      type: FieldImprovementType.mine,
      tileYield: TileYield(food: 0, production: 2, gold: 0, defense: 0),
      buildTurns: 3,
      requirements: [
        RequiresAnyBaseTerrain({TerrainType.hills}),
      ],
    ),
    FieldImprovementType.lumberMill: FieldImprovementDefinition(
      type: FieldImprovementType.lumberMill,
      tileYield: TileYield(food: 0, production: 1, gold: 0, defense: 0),
      buildTurns: 2,
      requirements: [
        RequiresAnyBaseTerrain({TerrainType.forest}),
      ],
    ),
  };
}
