import 'package:aonw/map/domain/terrain_type.dart';

abstract final class HexResourceGroups {
  static const foodCity = {
    ResourceType.wheat,
    ResourceType.rice,
    ResourceType.cow,
    ResourceType.sheep,
  };

  static const portHeart = {ResourceType.fish, ResourceType.pearls};

  static const industrial = {
    ResourceType.iron,
    ResourceType.coal,
    ResourceType.marble,
  };

  static const wilds = {
    ResourceType.deer,
    ResourceType.banana,
    ResourceType.cocoa,
  };

  static const desertTrade = {
    ResourceType.gold,
    ResourceType.silver,
    ResourceType.spices,
    ResourceType.cotton,
    ResourceType.sugar,
  };

  static const coldStrategic = {
    ResourceType.oil,
    ResourceType.uranium,
    ResourceType.coal,
  };

  static const plainLuxury = {
    ResourceType.gold,
    ResourceType.silk,
    ResourceType.spices,
  };

  static const borderland = {ResourceType.iron, ResourceType.horses};

  static const hillWealth = {ResourceType.gold, ResourceType.gems};

  static const exotic = {
    ResourceType.banana,
    ResourceType.cocoa,
    ResourceType.spices,
  };

  static const strategic = {
    ResourceType.iron,
    ResourceType.coal,
    ResourceType.oil,
    ResourceType.aluminium,
    ResourceType.uranium,
    ResourceType.horses,
    ResourceType.marble,
  };

  static bool hasAny(Set<ResourceType> resources, Set<ResourceType> expected) {
    return resources.any(expected.contains);
  }
}
