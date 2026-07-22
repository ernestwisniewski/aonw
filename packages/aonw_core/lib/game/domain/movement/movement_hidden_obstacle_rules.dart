import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/diplomacy/city_entry_policy.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/fog/fog_visibility_query.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

/// Keeps path planning independent of hidden dynamic obstacles.
abstract final class MovementHiddenObstacleRules {
  static bool canPlanThroughCity({
    required Iterable<GameCity> cities,
    required DiplomacyState diplomacy,
    required GameUnit unit,
    required MapTileView tile,
    required FogVisibilityQuery visibility,
  }) {
    if (!_cityBlocks(
      cities: cities,
      diplomacy: diplomacy,
      unit: unit,
      col: tile.col,
      row: tile.row,
    )) {
      return true;
    }
    return visibility.isEnabled &&
        !visibility.canSeeDynamicAt(tile.col, tile.row);
  }

  static bool reachablePathHitsHiddenBlocker({
    required UnitMovementPlan plan,
    required GameUnit movingUnit,
    required Iterable<GameUnit> allUnits,
    required Iterable<GameCity> cities,
    required DiplomacyState diplomacy,
    required FogVisibilityQuery visibility,
  }) {
    if (!visibility.isEnabled) return false;
    final reachableSteps = plan.canMoveNow ? plan.steps : plan.reachableSteps;
    for (final step in reachableSteps.skip(1)) {
      if (_hiddenUnitOccupies(
            allUnits: allUnits,
            movingUnit: movingUnit,
            visibility: visibility,
            col: step.col,
            row: step.row,
          ) ||
          !visibility.canSeeDynamicAt(step.col, step.row) &&
              _cityBlocks(
                cities: cities,
                diplomacy: diplomacy,
                unit: movingUnit,
                col: step.col,
                row: step.row,
              )) {
        return true;
      }
    }
    return false;
  }

  static bool _hiddenUnitOccupies({
    required Iterable<GameUnit> allUnits,
    required GameUnit movingUnit,
    required FogVisibilityQuery visibility,
    required int col,
    required int row,
  }) {
    for (final candidate in allUnits) {
      if (candidate.id == movingUnit.id ||
          candidate.ownerPlayerId == movingUnit.ownerPlayerId ||
          visibility.canSeeDynamicAt(candidate.col, candidate.row)) {
        continue;
      }
      if (candidate.occupies(col, row)) return true;
    }
    return false;
  }

  static bool _cityBlocks({
    required Iterable<GameCity> cities,
    required DiplomacyState diplomacy,
    required GameUnit unit,
    required int col,
    required int row,
  }) {
    return CityEntryPolicy.blocksCityCenterEntry(
      diplomacy: diplomacy,
      cities: cities,
      unitOwnerPlayerId: unit.ownerPlayerId,
      col: col,
      row: row,
    );
  }
}
