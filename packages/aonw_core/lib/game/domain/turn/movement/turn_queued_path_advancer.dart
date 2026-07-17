import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/movement/merchant_trade_route_rules.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class TurnQueuedPathAdvancer {
  static GameUnit advance({
    required GameUnit unit,
    required MapTraversalView mapData,
    required List<GameUnit> allUnits,
    required List<GameCity> cities,
  }) {
    final path = unit.queuedPath;
    if (path == null) return unit;
    if (!shouldKeep(unit) || unit.isFortified) {
      return unit.copyWithQueuedPath(null);
    }

    final targetTile = mapData.tileAt(path.targetCol, path.targetRow);
    if (targetTile == null) return unit.copyWithQueuedPath(null);
    final plan = UnitMovementPathfinder(
      mapData: mapData,
      units: allUnits,
      canEnterOccupiedTile:
          ({
            required movingUnit,
            required blockingUnit,
            required col,
            required row,
          }) => MerchantTradeRouteRules.canShareOccupiedCityTile(
            movingUnit: movingUnit,
            col: col,
            row: row,
            cities: cities,
          ),
    ).plan(unit: unit, targetTile: targetTile);
    if (plan == null) return unit.copyWithQueuedPath(null);
    return _moveAlongPlan(unit, plan);
  }

  static bool shouldKeep(GameUnit unit) {
    if (unit.isWorking) return false;
    if (unit.type != GameUnitType.merchant) return true;
    return unit.merchantTradeRoute == null;
  }

  static GameUnit _moveAlongPlan(GameUnit unit, UnitMovementPlan plan) {
    final reachable = plan.canMoveNow;
    final destination = reachable
        ? plan.steps.last
        : plan.furthestReachableStep;
    if (destination == null ||
        (destination.col == unit.col && destination.row == unit.row)) {
      return unit;
    }
    final moved = unit.copyWith(
      col: destination.col,
      row: destination.row,
      movementPoints: plan.remainingMovementPointsAfterStep(destination),
    );
    return reachable ? moved.copyWithQueuedPath(null) : moved;
  }
}
