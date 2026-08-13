import 'package:aonw_core/game/domain/movement/movement_cost.dart';
import 'package:aonw_core/game/domain/movement/movement_point_scale.dart';
import 'package:aonw_core/game/domain/terrain/tile_terrain_profile.dart';
import 'package:aonw_core/game/domain/terrain/tile_terrain_profile_rules.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class UnitMovementCostRules {
  static MovementCost costToEnterTile(
    MapTileView tile, {
    GameUnitType? unitType,
  }) {
    return costToEnter(
      TileTerrainProfileRules.fromTile(tile),
      unitType: unitType,
    );
  }

  static MovementCost costToEnter(
    TileTerrainProfile profile, {
    GameUnitType? unitType,
  }) {
    if (profile.hasMountain) return const MovementCost.blocked();
    if (unitType?.isNaval ?? false) return _navalCost(profile);

    final baseCost = _baseCost(profile.base);
    if (baseCost == null) return const MovementCost.blocked();

    var cost = baseCost;
    if (_forestAddsCost(profile)) cost += MovementPointScale.unitsPerPoint;
    if (profile.hasJungle) cost += MovementPointScale.unitsPerPoint;
    if (profile.hasWetlands) cost += MovementPointScale.unitsPerPoint;
    if (profile.hasHills) cost += MovementPointScale.unitsPerPoint;

    return MovementCost.passable(cost);
  }

  static MovementCost _navalCost(TileTerrainProfile profile) {
    return switch (profile.base) {
      TerrainType.coast || TerrainType.ocean => const MovementCost.passable(
        MovementPointScale.unitsPerPoint,
      ),
      TerrainType.grassland ||
      TerrainType.plains ||
      TerrainType.desert ||
      TerrainType.tundra ||
      TerrainType.snow ||
      TerrainType.lake ||
      TerrainType.forest ||
      TerrainType.jungle ||
      TerrainType.hills ||
      TerrainType.wetlands ||
      TerrainType.mountain ||
      TerrainType.river ||
      null => const MovementCost.blocked(),
    };
  }

  static int? _baseCost(TerrainType? terrain) {
    return switch (terrain) {
      TerrainType.grassland ||
      TerrainType.plains ||
      TerrainType.coast => MovementPointScale.unitsPerPoint,
      TerrainType.desert ||
      TerrainType.tundra ||
      TerrainType.wetlands => 2 * MovementPointScale.unitsPerPoint,
      TerrainType.snow => 3 * MovementPointScale.unitsPerPoint,
      // Ocean is open water — impassable for land units.
      TerrainType.ocean || TerrainType.lake => null,
      TerrainType.forest ||
      TerrainType.jungle ||
      TerrainType.hills ||
      TerrainType.mountain ||
      TerrainType.river ||
      null => null,
    };
  }

  static bool _forestAddsCost(TileTerrainProfile profile) {
    if (!profile.hasForest) return false;
    if (profile.base != TerrainType.snow) return true;
    return profile.hasJungle || profile.hasWetlands || profile.hasHills;
  }
}
