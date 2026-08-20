import 'package:aonw/shared/assets/sprite_frame_id.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
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

  static const Map<TerrainType, SpriteFrameId> _terrainIcons = {
    TerrainType.ocean: SpriteFrameId('map.terrain.ocean'),
    TerrainType.coast: SpriteFrameId('map.terrain.coast'),
    TerrainType.lake: SpriteFrameId('map.terrain.lake'),
    TerrainType.plains: SpriteFrameId('map.terrain.plains'),
    TerrainType.grassland: SpriteFrameId('map.terrain.grassland'),
    TerrainType.desert: SpriteFrameId('map.terrain.desert'),
    TerrainType.tundra: SpriteFrameId('map.terrain.tundra'),
    TerrainType.snow: SpriteFrameId('map.terrain.snow'),
    TerrainType.mountain: SpriteFrameId('map.terrain.mountain'),
    TerrainType.hills: SpriteFrameId('map.terrain.hills'),
    TerrainType.wetlands: SpriteFrameId('map.terrain.wetlands'),
    TerrainType.jungle: SpriteFrameId('map.terrain.jungle'),
    TerrainType.forest: SpriteFrameId('map.terrain.forest'),
    TerrainType.river: SpriteFrameId('map.terrain.river'),
  };

  static const Map<ResourceType, SpriteFrameId> resourceIcons = {
    // Bonus
    ResourceType.wheat: SpriteFrameId('map.resource.wheat'),
    ResourceType.fish: SpriteFrameId('map.resource.fish'),
    ResourceType.deer: SpriteFrameId('map.resource.deer'),
    ResourceType.sheep: SpriteFrameId('map.resource.sheep'),
    ResourceType.rice: SpriteFrameId('map.resource.rice'),
    ResourceType.cow: SpriteFrameId('map.resource.cow'),
    ResourceType.apple: SpriteFrameId('map.resource.apple'),
    ResourceType.banana: SpriteFrameId('map.resource.banana'),
    ResourceType.citrus: SpriteFrameId('map.resource.citrus'),
    // Luxury
    ResourceType.gold: SpriteFrameId('map.resource.gold'),
    ResourceType.silver: SpriteFrameId('map.resource.silver'),
    ResourceType.gems: SpriteFrameId('map.resource.gems'),
    ResourceType.silk: SpriteFrameId('map.resource.silk'),
    ResourceType.spices: SpriteFrameId('map.resource.spices'),
    ResourceType.cotton: SpriteFrameId('map.resource.cotton'),
    ResourceType.grapes: SpriteFrameId('map.resource.grapes'),
    ResourceType.ivory: SpriteFrameId('map.resource.ivory'),
    ResourceType.pearls: SpriteFrameId('map.resource.pearls'),
    ResourceType.coffee: SpriteFrameId('map.resource.coffee'),
    ResourceType.cocoa: SpriteFrameId('map.resource.cocoa'),
    ResourceType.tobacco: SpriteFrameId('map.resource.tobacco'),
    ResourceType.sugar: SpriteFrameId('map.resource.sugar'),
    // Strategic
    ResourceType.iron: SpriteFrameId('map.resource.iron'),
    ResourceType.coal: SpriteFrameId('map.resource.coal'),
    ResourceType.oil: SpriteFrameId('map.resource.oil'),
    ResourceType.aluminium: SpriteFrameId('map.resource.aluminium'),
    ResourceType.uranium: SpriteFrameId('map.resource.uranium'),
    ResourceType.horses: SpriteFrameId('map.resource.horses'),
    ResourceType.marble: SpriteFrameId('map.resource.marble'),
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

  static SpriteFrameId icon(TerrainType terrain) {
    return _terrainIcons[terrain]!;
  }

  /// Returns the resource icon asset path, or null if no resource.
  static SpriteFrameId? resourceIcon(ResourceType? resource) {
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
