import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class StabilitySourceCatalog {
  static const Set<CityBuildingType> orderBuildings = {
    CityBuildingType.townHall,
    CityBuildingType.courthouse,
    CityBuildingType.governorsOffice,
    CityBuildingType.ministries,
    CityBuildingType.monument,
  };

  static const Set<TechnologyId> orderTechnologies = {
    TechnologyId.law,
    TechnologyId.civilService,
    TechnologyId.administration,
  };

  static const Set<ResourceType> luxuryResources = {
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
}
