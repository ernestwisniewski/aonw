import 'package:aonw_core/map/domain/terrain_type.dart';

enum ResourceCategory { bonus, luxury, strategic }

enum ResourceEconomyMode { localYield, presenceGate, stockpiled }

final class ResourceDefinition {
  const ResourceDefinition({
    required this.type,
    required this.category,
    required this.economyMode,
  });

  final ResourceType type;
  final ResourceCategory category;
  final ResourceEconomyMode economyMode;
}

abstract final class ResourceCatalog {
  static const Map<ResourceType, ResourceDefinition> standard = {
    ResourceType.wheat: ResourceDefinition(
      type: ResourceType.wheat,
      category: ResourceCategory.bonus,
      economyMode: ResourceEconomyMode.localYield,
    ),
    ResourceType.fish: ResourceDefinition(
      type: ResourceType.fish,
      category: ResourceCategory.bonus,
      economyMode: ResourceEconomyMode.localYield,
    ),
    ResourceType.deer: ResourceDefinition(
      type: ResourceType.deer,
      category: ResourceCategory.bonus,
      economyMode: ResourceEconomyMode.localYield,
    ),
    ResourceType.sheep: ResourceDefinition(
      type: ResourceType.sheep,
      category: ResourceCategory.bonus,
      economyMode: ResourceEconomyMode.localYield,
    ),
    ResourceType.rice: ResourceDefinition(
      type: ResourceType.rice,
      category: ResourceCategory.bonus,
      economyMode: ResourceEconomyMode.localYield,
    ),
    ResourceType.cow: ResourceDefinition(
      type: ResourceType.cow,
      category: ResourceCategory.bonus,
      economyMode: ResourceEconomyMode.localYield,
    ),
    ResourceType.apple: ResourceDefinition(
      type: ResourceType.apple,
      category: ResourceCategory.bonus,
      economyMode: ResourceEconomyMode.localYield,
    ),
    ResourceType.banana: ResourceDefinition(
      type: ResourceType.banana,
      category: ResourceCategory.bonus,
      economyMode: ResourceEconomyMode.localYield,
    ),
    ResourceType.citrus: ResourceDefinition(
      type: ResourceType.citrus,
      category: ResourceCategory.bonus,
      economyMode: ResourceEconomyMode.localYield,
    ),
    ResourceType.gold: ResourceDefinition(
      type: ResourceType.gold,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.silver: ResourceDefinition(
      type: ResourceType.silver,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.gems: ResourceDefinition(
      type: ResourceType.gems,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.silk: ResourceDefinition(
      type: ResourceType.silk,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.spices: ResourceDefinition(
      type: ResourceType.spices,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.cotton: ResourceDefinition(
      type: ResourceType.cotton,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.grapes: ResourceDefinition(
      type: ResourceType.grapes,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.ivory: ResourceDefinition(
      type: ResourceType.ivory,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.pearls: ResourceDefinition(
      type: ResourceType.pearls,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.coffee: ResourceDefinition(
      type: ResourceType.coffee,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.cocoa: ResourceDefinition(
      type: ResourceType.cocoa,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.tobacco: ResourceDefinition(
      type: ResourceType.tobacco,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.sugar: ResourceDefinition(
      type: ResourceType.sugar,
      category: ResourceCategory.luxury,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.iron: ResourceDefinition(
      type: ResourceType.iron,
      category: ResourceCategory.strategic,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.coal: ResourceDefinition(
      type: ResourceType.coal,
      category: ResourceCategory.strategic,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.oil: ResourceDefinition(
      type: ResourceType.oil,
      category: ResourceCategory.strategic,
      economyMode: ResourceEconomyMode.stockpiled,
    ),
    ResourceType.aluminium: ResourceDefinition(
      type: ResourceType.aluminium,
      category: ResourceCategory.strategic,
      economyMode: ResourceEconomyMode.stockpiled,
    ),
    ResourceType.uranium: ResourceDefinition(
      type: ResourceType.uranium,
      category: ResourceCategory.strategic,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.horses: ResourceDefinition(
      type: ResourceType.horses,
      category: ResourceCategory.strategic,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
    ResourceType.marble: ResourceDefinition(
      type: ResourceType.marble,
      category: ResourceCategory.bonus,
      economyMode: ResourceEconomyMode.presenceGate,
    ),
  };

  static ResourceDefinition definitionFor(ResourceType type) =>
      standard[type] ??
      (throw StateError('Missing resource definition for ${type.name}.'));

  static bool isStrategic(ResourceType type) =>
      definitionFor(type).category == ResourceCategory.strategic;

  static bool isStockpiled(ResourceType type) =>
      definitionFor(type).economyMode == ResourceEconomyMode.stockpiled;

  static Iterable<ResourceType> get strategicResources =>
      ResourceType.values.where(
        (resource) =>
            definitionFor(resource).category == ResourceCategory.strategic,
      );

  static Iterable<ResourceType> get stockpiledResources =>
      ResourceType.values.where(
        (resource) =>
            definitionFor(resource).economyMode ==
            ResourceEconomyMode.stockpiled,
      );
}
