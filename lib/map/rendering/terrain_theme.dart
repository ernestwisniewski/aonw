import 'package:aonw/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';

abstract final class TerrainTheme {
  // Darkening factors for side walls (lerp toward tintColor).
  // Stronger contrast between faces gives a clear isometric 3-D look.
  static const double rightWallFactor = 0.30; // right face — medium dark
  static const double bottomWallFactor = 0.50; // bottom face — darkest
  static const double leftWallFactor = 0.18; // left face — lightest

  static const Map<TerrainType, Color> _baseColors = {
    TerrainType.ocean: Color(0xFF1a6691),
    TerrainType.coast: Color(0xFF4a9fc4),
    TerrainType.lake: Color(0xFF2f86a8),
    TerrainType.plains: Color(0xFFc8b560),
    TerrainType.grassland: Color(0xFF5a8a3c),
    TerrainType.desert: Color(0xFFd4a84b),
    TerrainType.tundra: Color(0xFF8da89a),
    TerrainType.snow: Color(0xFFe8e8f0),
    TerrainType.mountain: Color(0xFF7a7a7a),
    TerrainType.hills: Color(0xFFa0956e),
    TerrainType.wetlands: Color(0xFF4d6f45),
    TerrainType.jungle: Color(0xFF2d6b2a),
    TerrainType.forest: Color(0xFF3d7a40),
    TerrainType.river: Color(0xFF3a8fbf),
  };

  static const Map<TerrainType, String> _terrainIcons = {
    TerrainType.ocean: 'assets/icons/terrain_ocean.png',
    TerrainType.coast: 'assets/icons/terrain_coast.png',
    TerrainType.lake: 'assets/icons/terrain_coast.png',
    TerrainType.plains: 'assets/icons/terrain_plains.png',
    TerrainType.grassland: 'assets/icons/terrain_grassland.png',
    TerrainType.desert: 'assets/icons/terrain_desert.png',
    TerrainType.tundra: 'assets/icons/terrain_tundra.png',
    TerrainType.snow: 'assets/icons/terrain_snow.png',
    TerrainType.mountain: 'assets/icons/terrain_mountain.png',
    TerrainType.hills: 'assets/icons/terrain_hills.png',
    TerrainType.wetlands: 'assets/icons/terrain_river.png',
    TerrainType.jungle: 'assets/icons/terrain_jungle.png',
    TerrainType.forest: 'assets/icons/terrain_forest.png',
    TerrainType.river: 'assets/icons/terrain_river.png',
  };

  static const Map<ResourceType, String> resourceIcons = {
    // Bonus
    ResourceType.wheat: 'assets/icons/wheat.png',
    ResourceType.fish: 'assets/icons/fish.png',
    ResourceType.deer: 'assets/icons/deer.png',
    ResourceType.sheep: 'assets/icons/sheep.png',
    ResourceType.rice: 'assets/icons/rice.png',
    ResourceType.cow: 'assets/icons/cow.png',
    ResourceType.apple: 'assets/icons/apple.png',
    ResourceType.banana: 'assets/icons/bananas.png',
    ResourceType.citrus: 'assets/icons/citrus.png',
    // Luxury
    ResourceType.gold: 'assets/icons/gold.png',
    ResourceType.silver: 'assets/icons/silver.png',
    ResourceType.gems: 'assets/icons/gems.png',
    ResourceType.silk: 'assets/icons/silk.png',
    ResourceType.spices: 'assets/icons/spices.png',
    ResourceType.cotton: 'assets/icons/cotton.png',
    ResourceType.grapes: 'assets/icons/grapes.png',
    ResourceType.ivory: 'assets/icons/ivory.png',
    ResourceType.pearls: 'assets/icons/pearls.png',
    ResourceType.coffee: 'assets/icons/coffee.png',
    ResourceType.cocoa: 'assets/icons/cocoa.png',
    ResourceType.tobacco: 'assets/icons/tobbacco.png',
    ResourceType.sugar: 'assets/icons/sugar.png',
    // Strategic
    ResourceType.iron: 'assets/icons/ironore.png',
    ResourceType.coal: 'assets/icons/coal.png',
    ResourceType.oil: 'assets/icons/oil.png',
    ResourceType.aluminium: 'assets/icons/aluminium.png',
    ResourceType.uranium: 'assets/icons/uranium.png',
    ResourceType.horses: 'assets/icons/horse.png',
    ResourceType.marble: 'assets/icons/marble.png',
  };

  /// Dot color shown on the tile when a resource is present (map view mode).
  static const Map<ResourceType, Color> resourceDotColors = {
    // Bonus — warm/natural tones
    ResourceType.wheat: Color(0xFFf5e642),
    ResourceType.fish: Color(0xFF42c5f5),
    ResourceType.deer: Color(0xFF8bc34a),
    ResourceType.sheep: Color(0xFFe0e0e0),
    ResourceType.rice: Color(0xFFc8e6c9),
    ResourceType.cow: Color(0xFFa5795a),
    ResourceType.apple: Color(0xFFe53935),
    ResourceType.banana: Color(0xFFffee58),
    ResourceType.citrus: Color(0xFFffa726),
    // Luxury — gold/jewel tones
    ResourceType.gold: Color(0xFFffd700),
    ResourceType.silver: Color(0xFFc0c0c0),
    ResourceType.gems: Color(0xFFce93d8),
    ResourceType.silk: Color(0xFFf48fb1),
    ResourceType.spices: Color(0xFFff8a65),
    ResourceType.cotton: Color(0xFFe1f5fe),
    ResourceType.grapes: Color(0xFF9c27b0),
    ResourceType.ivory: Color(0xFFfff8e1),
    ResourceType.pearls: Color(0xFFe0f7fa),
    ResourceType.coffee: Color(0xFF6d4c41),
    ResourceType.cocoa: Color(0xFF5d4037),
    ResourceType.tobacco: Color(0xFF827717),
    ResourceType.sugar: Color(0xFFfff9c4),
    // Strategic — industrial tones
    ResourceType.iron: Color(0xFF90a4ae),
    ResourceType.coal: Color(0xFF424242),
    ResourceType.oil: Color(0xFF212121),
    ResourceType.aluminium: Color(0xFF78909c),
    ResourceType.uranium: Color(0xFF76ff03),
    ResourceType.horses: Color(0xFF8d6e63),
    ResourceType.marble: Color(0xFFf5f5f5),
  };

  static Color topColor(TerrainType terrain, ResourceType? resource) {
    return _baseColors[terrain]!;
  }

  static String icon(TerrainType terrain) {
    return _terrainIcons[terrain]!;
  }

  /// Returns the resource icon asset path, or null if no resource.
  static String? resourceIcon(ResourceType? resource) {
    if (resource == null) return null;
    return resourceIcons[resource];
  }

  /// Returns the resource dot color, or null if no resource.
  static Color? resourceDotColor(ResourceType? resource) {
    if (resource == null) return null;
    return resourceDotColors[resource];
  }

  /// Derives a side wall color by lerping [topColor] toward [tintColor].
  /// [factor] is a value from [rightWallFactor], [bottomWallFactor], [leftWallFactor].
  /// Defaults to black to preserve the original darkening behaviour.
  static Color sideColor(
    Color topColor,
    double factor, {
    Color tintColor = Colors.black,
  }) {
    return Color.lerp(topColor, tintColor, factor)!;
  }
}
