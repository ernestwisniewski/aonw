enum TerrainType {
  ocean,
  coast,
  lake,
  plains,
  grassland,
  desert,
  tundra,
  snow,
  mountain,
  hills,
  wetlands,
  jungle,
  forest,
  river;

  static TerrainType fromString(String value) {
    return TerrainType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => throw ArgumentError('Unknown terrain type: $value'),
    );
  }

  static TerrainType fromName(String name) => fromString(name);
}

/// Resources that can appear on a hex tile, grouped by category.
enum ResourceType {
  // Bonus.
  wheat,
  fish,
  deer,
  sheep,
  rice,
  cow,
  apple,
  banana,
  citrus,

  // Luxury.
  gold,
  silver,
  gems,
  silk,
  spices,
  cotton,
  grapes,
  ivory,
  pearls,
  coffee,
  cocoa,
  tobacco,
  sugar,

  // Strategic.
  iron,
  coal,
  oil,
  aluminium,
  uranium,
  horses,
  marble;

  static ResourceType fromString(String value) {
    return ResourceType.values.firstWhere(
      (r) => r.name == value,
      orElse: () => throw ArgumentError('Unknown resource type: $value'),
    );
  }

  static ResourceType fromName(String name) => fromString(name);
}
