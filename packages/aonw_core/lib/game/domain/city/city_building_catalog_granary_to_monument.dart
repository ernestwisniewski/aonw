part of 'city_building_catalog.dart';

const _granaryToMonumentBuildings = <CityBuildingType, CityBuildingDefinition>{
  CityBuildingType.granary: CityBuildingDefinition(
    type: CityBuildingType.granary,
    productionCost: 6,
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 2, production: 0, gold: 0, defense: 0),
      ),
    ],
  ),
  CityBuildingType.waterMill: CityBuildingDefinition(
    type: CityBuildingType.waterMill,
    productionCost: 15,
    effects: [
      RiverHexCityYieldEffect(
        yieldPerRiverHex: TileYield(
          food: 1,
          production: 0,
          gold: 0,
          defense: 0,
        ),
        maxApplications: 3,
      ),
    ],
  ),
  CityBuildingType.workshop: CityBuildingDefinition(
    type: CityBuildingType.workshop,
    productionCost: 15,
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 0, production: 2, gold: 0, defense: 0),
      ),
    ],
  ),
  CityBuildingType.storehouse: CityBuildingDefinition(
    type: CityBuildingType.storehouse,
    productionCost: 12,
    effects: [FoodDepositMultiplierEffect(1.2)],
  ),
  CityBuildingType.housing: CityBuildingDefinition(
    type: CityBuildingType.housing,
    productionCost: 18,
    effects: [MaxControlledHexesEffect(2)],
  ),
  CityBuildingType.merchantHall: CityBuildingDefinition(
    type: CityBuildingType.merchantHall,
    productionCost: 12,
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 0, production: 0, gold: 2, defense: 0),
      ),
    ],
  ),
  CityBuildingType.stonemason: CityBuildingDefinition(
    type: CityBuildingType.stonemason,
    productionCost: 15,
    requirements: [
      CityResourceRequirement({ResourceType.marble}),
    ],
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 0, production: 1, gold: 0, defense: 1),
      ),
    ],
  ),
  CityBuildingType.barracks: CityBuildingDefinition(
    type: CityBuildingType.barracks,
    productionCost: 16,
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 0, production: 1, gold: 0, defense: 1),
      ),
    ],
  ),
  CityBuildingType.marketplace: CityBuildingDefinition(
    type: CityBuildingType.marketplace,
    productionCost: 20,
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 0, production: 0, gold: 4, defense: 0),
      ),
    ],
  ),
  CityBuildingType.port: CityBuildingDefinition(
    type: CityBuildingType.port,
    productionCost: 18,
    requirements: [CoastalAccessRequirement()],
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 1, production: 0, gold: 2, defense: 0),
      ),
    ],
  ),
  CityBuildingType.aqueduct: CityBuildingDefinition(
    type: CityBuildingType.aqueduct,
    productionCost: 20,
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 2, production: 0, gold: 0, defense: 0),
      ),
      MaxControlledHexesEffect(1),
    ],
  ),
  CityBuildingType.forge: CityBuildingDefinition(
    type: CityBuildingType.forge,
    productionCost: 22,
    requirements: [
      CityResourceRequirement({ResourceType.iron}),
    ],
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 0, production: 3, gold: 0, defense: 0),
      ),
    ],
  ),
  CityBuildingType.stable: CityBuildingDefinition(
    type: CityBuildingType.stable,
    productionCost: 18,
    requirements: [
      CityResourceRequirement({ResourceType.horses}),
    ],
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 1, production: 1, gold: 0, defense: 0),
      ),
    ],
  ),
  CityBuildingType.bank: CityBuildingDefinition(
    type: CityBuildingType.bank,
    productionCost: 22,
    requirements: [
      CityResourceRequirement({
        ResourceType.gold,
        ResourceType.silver,
        ResourceType.gems,
      }),
    ],
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 0, production: 0, gold: 5, defense: 0),
      ),
    ],
  ),
  CityBuildingType.buildersGuild: CityBuildingDefinition(
    type: CityBuildingType.buildersGuild,
    productionCost: 21,
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 0, production: 2, gold: 0, defense: 0),
      ),
      MaxControlledHexesEffect(1),
    ],
  ),
  CityBuildingType.factory: CityBuildingDefinition(
    type: CityBuildingType.factory,
    productionCost: 30,
    requirements: [
      CityResourceRequirement({ResourceType.coal, ResourceType.oil}),
    ],
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 0, production: 4, gold: 0, defense: 0),
      ),
    ],
  ),
  CityBuildingType.lighthouse: CityBuildingDefinition(
    type: CityBuildingType.lighthouse,
    productionCost: 20,
    requirements: [CoastalAccessRequirement()],
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 1, production: 0, gold: 3, defense: 0),
      ),
    ],
  ),
  CityBuildingType.trainingGrounds: CityBuildingDefinition(
    type: CityBuildingType.trainingGrounds,
    productionCost: 22,
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 0, production: 1, gold: 0, defense: 2),
      ),
    ],
  ),
  CityBuildingType.townHall: CityBuildingDefinition(
    type: CityBuildingType.townHall,
    productionCost: 24,
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 0, production: 0, gold: 2, defense: 1),
      ),
      MaxControlledHexesEffect(1),
    ],
  ),
  CityBuildingType.monument: CityBuildingDefinition(
    type: CityBuildingType.monument,
    productionCost: 15,
    effects: [
      FlatCityYieldEffect(
        TileYield(food: 0, production: 0, gold: 1, defense: 1),
      ),
    ],
  ),
};
