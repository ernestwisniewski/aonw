part of 'city_building_catalog.dart';

const _archiveToConscriptionBuildings =
    <CityBuildingType, CityBuildingDefinition>{
      CityBuildingType.archive: CityBuildingDefinition(
        type: CityBuildingType.archive,
        productionCost: 15,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 0, gold: 1, defense: 0),
          ),
          FlatCityScienceEffect(2),
        ],
      ),
      CityBuildingType.academy: CityBuildingDefinition(
        type: CityBuildingType.academy,
        productionCost: 22,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 1, gold: 1, defense: 0),
          ),
          FlatCityScienceEffect(3),
        ],
      ),
      CityBuildingType.university: CityBuildingDefinition(
        type: CityBuildingType.university,
        productionCost: 36,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 0, gold: 3, defense: 0),
          ),
          FlatCityScienceEffect(3),
        ],
      ),
      CityBuildingType.observatory: CityBuildingDefinition(
        type: CityBuildingType.observatory,
        productionCost: 30,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 0, gold: 2, defense: 1),
          ),
          FlatCityScienceEffect(3),
        ],
      ),
      CityBuildingType.laboratory: CityBuildingDefinition(
        type: CityBuildingType.laboratory,
        productionCost: 46,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 2, gold: 2, defense: 0),
          ),
          FlatCityScienceEffect(4),
        ],
      ),
      CityBuildingType.reactor: CityBuildingDefinition(
        type: CityBuildingType.reactor,
        productionCost: 80,
        requirements: [
          CityResourceRequirement({ResourceType.uranium}),
        ],
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 6, gold: 2, defense: 1),
          ),
          FlatCityScienceEffect(3),
        ],
      ),
      CityBuildingType.courthouse: CityBuildingDefinition(
        type: CityBuildingType.courthouse,
        productionCost: 22,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 0, gold: 1, defense: 2),
          ),
        ],
      ),
      CityBuildingType.court: CityBuildingDefinition(
        type: CityBuildingType.court,
        productionCost: 28,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 0, gold: 2, defense: 2),
          ),
        ],
      ),
      CityBuildingType.governorsOffice: CityBuildingDefinition(
        type: CityBuildingType.governorsOffice,
        productionCost: 32,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 1, gold: 2, defense: 1),
          ),
          MaxControlledHexesEffect(1),
        ],
      ),
      CityBuildingType.surveyorsOffice: CityBuildingDefinition(
        type: CityBuildingType.surveyorsOffice,
        productionCost: 20,
        effects: [MaxControlledHexesEffect(2), FlatCityScienceEffect(2)],
      ),
      CityBuildingType.planningOffice: CityBuildingDefinition(
        type: CityBuildingType.planningOffice,
        productionCost: 30,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 1, gold: 1, defense: 0),
          ),
          MaxControlledHexesEffect(2),
        ],
      ),
      CityBuildingType.apothecary: CityBuildingDefinition(
        type: CityBuildingType.apothecary,
        productionCost: 18,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 1, production: 0, gold: 0, defense: 1),
          ),
          FlatCityScienceEffect(1),
        ],
      ),
      CityBuildingType.publicBaths: CityBuildingDefinition(
        type: CityBuildingType.publicBaths,
        productionCost: 28,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 2, production: 0, gold: 1, defense: 0),
          ),
        ],
      ),
      CityBuildingType.hospital: CityBuildingDefinition(
        type: CityBuildingType.hospital,
        productionCost: 42,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 3, production: 0, gold: 1, defense: 1),
          ),
          FlatCityScienceEffect(2),
        ],
      ),
      CityBuildingType.ministries: CityBuildingDefinition(
        type: CityBuildingType.ministries,
        productionCost: 48,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 1, gold: 4, defense: 1),
          ),
        ],
      ),
      CityBuildingType.walls: CityBuildingDefinition(
        type: CityBuildingType.walls,
        productionCost: 18,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 0, gold: 0, defense: 4),
          ),
        ],
      ),
      CityBuildingType.armory: CityBuildingDefinition(
        type: CityBuildingType.armory,
        productionCost: 26,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 2, gold: 0, defense: 2),
          ),
        ],
      ),
      CityBuildingType.siegeWorkshop: CityBuildingDefinition(
        type: CityBuildingType.siegeWorkshop,
        productionCost: 36,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 3, gold: 0, defense: 1),
          ),
        ],
      ),
      CityBuildingType.citadel: CityBuildingDefinition(
        type: CityBuildingType.citadel,
        productionCost: 46,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 1, gold: 0, defense: 6),
          ),
        ],
      ),
      CityBuildingType.warCollege: CityBuildingDefinition(
        type: CityBuildingType.warCollege,
        productionCost: 42,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 2, gold: 1, defense: 3),
          ),
        ],
      ),
      CityBuildingType.conscriptionOffice: CityBuildingDefinition(
        type: CityBuildingType.conscriptionOffice,
        productionCost: 34,
        effects: [
          FlatCityYieldEffect(
            TileYield(food: 0, production: 3, gold: 0, defense: 1),
          ),
        ],
      ),
    };
