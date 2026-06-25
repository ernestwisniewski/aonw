import 'package:aonw_core/game/domain/terrain/tile_terrain_profile.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class TileTerrainProfileRules {
  static TileTerrainProfile fromTile(TileData tile) =>
      fromTerrains(tile.terrains);

  static TileTerrainProfile fromTerrains(Iterable<TerrainType> terrains) {
    TerrainType? base;
    final features = <TerrainType>{};
    final modifiers = <TerrainType>{};
    final blockers = <TerrainType>{};

    for (final terrain in terrains) {
      if (_isBlocker(terrain)) {
        blockers.add(terrain);
        continue;
      }
      if (_isModifier(terrain)) {
        modifiers.add(terrain);
        continue;
      }
      if (_isFeature(terrain)) {
        features.add(terrain);
        continue;
      }
      if (_isBase(terrain)) {
        // Any land terrain beats open water: if a tile has ocean/lake + any
        // other base terrain, the land terrain wins so movement treats it as
        // passable.
        if (base == null ||
            (_isOpenWaterBase(base) && !_isOpenWaterBase(terrain))) {
          base = terrain;
        }
      }
    }

    base ??= _defaultBaseForFeatureOnly(features);

    return TileTerrainProfile(
      base: base,
      features: Set.unmodifiable(features),
      modifiers: Set.unmodifiable(modifiers),
      blockers: Set.unmodifiable(blockers),
    );
  }

  static bool _isBase(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.grassland ||
      TerrainType.plains ||
      TerrainType.desert ||
      TerrainType.tundra ||
      TerrainType.snow ||
      TerrainType.coast ||
      TerrainType.lake ||
      TerrainType.ocean => true,
      TerrainType.forest ||
      TerrainType.jungle ||
      TerrainType.hills ||
      TerrainType.wetlands ||
      TerrainType.mountain ||
      TerrainType.river => false,
    };
  }

  static bool _isFeature(TerrainType terrain) {
    return switch (terrain) {
      TerrainType.forest ||
      TerrainType.jungle ||
      TerrainType.hills ||
      TerrainType.wetlands => true,
      TerrainType.grassland ||
      TerrainType.plains ||
      TerrainType.desert ||
      TerrainType.tundra ||
      TerrainType.snow ||
      TerrainType.coast ||
      TerrainType.lake ||
      TerrainType.ocean ||
      TerrainType.mountain ||
      TerrainType.river => false,
    };
  }

  static bool _isModifier(TerrainType terrain) => terrain == TerrainType.river;

  static bool _isBlocker(TerrainType terrain) =>
      terrain == TerrainType.mountain;

  static TerrainType? _defaultBaseForFeatureOnly(Set<TerrainType> features) {
    if (features.contains(TerrainType.forest) ||
        features.contains(TerrainType.jungle) ||
        features.contains(TerrainType.wetlands)) {
      return TerrainType.grassland;
    }
    if (features.contains(TerrainType.hills)) {
      return TerrainType.plains;
    }
    return null;
  }

  static bool _isOpenWaterBase(TerrainType terrain) {
    return terrain == TerrainType.ocean || terrain == TerrainType.lake;
  }
}
