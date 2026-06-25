import 'package:aonw_core/game/domain/movement/movement_cost.dart';
import 'package:aonw_core/game/domain/terrain/tile_terrain_profile.dart';
import 'package:aonw_core/game/domain/terrain/tile_terrain_profile_rules.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class UnitMovementCostRules {
  static MovementCost costToEnterTile(TileData tile, {GameUnitType? unitType}) {
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
    if (_forestAddsCost(profile)) cost += 1;
    if (profile.hasJungle) cost += 1;
    if (profile.hasWetlands) cost += 1;
    if (profile.hasHills) cost += 1;

    return MovementCost.passable(cost);
  }

  static MovementCost _navalCost(TileTerrainProfile profile) {
    return switch (profile.base) {
      TerrainType.coast || TerrainType.ocean => const MovementCost.passable(1),
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
      TerrainType.grassland || TerrainType.plains || TerrainType.coast => 1,
      TerrainType.desert || TerrainType.tundra || TerrainType.wetlands => 2,
      TerrainType.snow => 3,
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
