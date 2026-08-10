part of 'city_building_catalog.dart';

const _borderFortToWorldFairBuildings =
    <CityBuildingType, CityBuildingDefinition>{
      CityBuildingType.borderFort: CityBuildingDefinition(
        type: CityBuildingType.borderFort,
        productionCost: 30,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 0, gold: 1, defense: 4),
          ),
        ],
      ),
      CityBuildingType.airfield: CityBuildingDefinition(
        type: CityBuildingType.airfield,
        productionCost: 54,
        requirements: [
          CityResourceRequirement({ResourceType.oil, ResourceType.aluminium}),
        ],
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 3, gold: 1, defense: 2),
          ),
        ],
      ),
      CityBuildingType.artisansGuild: CityBuildingDefinition(
        type: CityBuildingType.artisansGuild,
        productionCost: 22,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 2, gold: 1, defense: 0),
          ),
        ],
      ),
      CityBuildingType.masterWorkshop: CityBuildingDefinition(
        type: CityBuildingType.masterWorkshop,
        productionCost: 34,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 3, gold: 1, defense: 0),
          ),
        ],
      ),
      CityBuildingType.steelworks: CityBuildingDefinition(
        type: CityBuildingType.steelworks,
        productionCost: 52,
        requirements: [
          CityResourceRequirement({ResourceType.iron, ResourceType.coal}),
        ],
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 5, gold: 0, defense: 1),
          ),
        ],
      ),
      CityBuildingType.railDepot: CityBuildingDefinition(
        type: CityBuildingType.railDepot,
        productionCost: 42,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 2, gold: 2, defense: 0),
          ),
        ],
      ),
      CityBuildingType.powerPlant: CityBuildingDefinition(
        type: CityBuildingType.powerPlant,
        productionCost: 62,
        requirements: [
          CityResourceRequirement({ResourceType.coal, ResourceType.oil}),
        ],
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 5, gold: 1, defense: 0),
          ),
        ],
      ),
      CityBuildingType.assemblyPlant: CityBuildingDefinition(
        type: CityBuildingType.assemblyPlant,
        productionCost: 70,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 6, gold: 1, defense: 0),
          ),
        ],
      ),
      CityBuildingType.refinery: CityBuildingDefinition(
        type: CityBuildingType.refinery,
        productionCost: 58,
        requirements: [
          CityResourceRequirement({ResourceType.oil}),
        ],
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 3, gold: 3, defense: 0),
          ),
        ],
      ),
      CityBuildingType.mapRoom: CityBuildingDefinition(
        type: CityBuildingType.mapRoom,
        productionCost: 20,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 0, gold: 1, defense: 1),
          ),
          FlatCityScienceEffect(2),
        ],
      ),
      CityBuildingType.shipyard: CityBuildingDefinition(
        type: CityBuildingType.shipyard,
        productionCost: 34,
        requirements: [CoastalAccessRequirement()],
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 3, gold: 1, defense: 0),
          ),
        ],
      ),
      CityBuildingType.dryDock: CityBuildingDefinition(
        type: CityBuildingType.dryDock,
        productionCost: 48,
        requirements: [CoastalAccessRequirement()],
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 4, gold: 1, defense: 2),
          ),
        ],
      ),
      CityBuildingType.navalAcademy: CityBuildingDefinition(
        type: CityBuildingType.navalAcademy,
        productionCost: 42,
        requirements: [CoastalAccessRequirement()],
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 2, gold: 1, defense: 3),
          ),
        ],
      ),
      CityBuildingType.harborCustoms: CityBuildingDefinition(
        type: CityBuildingType.harborCustoms,
        productionCost: 30,
        requirements: [CoastalAccessRequirement()],
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 0, gold: 4, defense: 0),
          ),
        ],
      ),
      CityBuildingType.museum: CityBuildingDefinition(
        type: CityBuildingType.museum,
        productionCost: 36,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 0, gold: 3, defense: 1),
          ),
          FlatCityScienceEffect(2),
        ],
      ),
      CityBuildingType.parliament: CityBuildingDefinition(
        type: CityBuildingType.parliament,
        productionCost: 58,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 1, gold: 5, defense: 2),
          ),
          MaxControlledHexesEffect(1),
        ],
      ),
      CityBuildingType.broadcastTower: CityBuildingDefinition(
        type: CityBuildingType.broadcastTower,
        productionCost: 48,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 0, gold: 4, defense: 2),
          ),
        ],
      ),
      CityBuildingType.worldFairGrounds: CityBuildingDefinition(
        type: CityBuildingType.worldFairGrounds,
        productionCost: 54,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 1, production: 1, gold: 5, defense: 0),
          ),
        ],
      ),
    };
