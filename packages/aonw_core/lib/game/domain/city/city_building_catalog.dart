import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/city/city_building_definition.dart';
import 'package:aonw_core/game/domain/city/city_building_effect.dart';
import 'package:aonw_core/game/domain/city/city_building_requirement.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class CityBuildingCatalog {
  static const standard = {
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
}
