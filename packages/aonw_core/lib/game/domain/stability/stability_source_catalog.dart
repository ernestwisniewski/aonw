import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

/// Structural classification of which content contributes positive empire
/// stability. Membership is a game rule; the per-source magnitudes are tuned in
/// `StabilityRuleset` (`stabilityPerOrderBuilding`, `stabilityPerOrderTechnology`,
/// `stabilityPerLuxuryResource`, `stabilityPerStoredArtifact`).
abstract final class StabilitySourceCatalog {
  /// Civic / administrative buildings that keep a city in order.
  static const Set<CityBuildingType> orderBuildings = {
    CityBuildingType.townHall,
    CityBuildingType.courthouse,
    CityBuildingType.governorsOffice,
    CityBuildingType.ministries,
    CityBuildingType.monument,
  };

  /// Technologies that add order and civic control to the empire.
  static const Set<TechnologyId> orderTechnologies = {
    TechnologyId.law,
    TechnologyId.civilService,
    TechnologyId.administration,
  };

  /// Luxury resources that raise contentment when present in an empire.
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
