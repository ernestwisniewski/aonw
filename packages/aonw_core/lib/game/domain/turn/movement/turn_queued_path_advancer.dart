import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/movement/merchant_trade_route_rules.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/movement/movement_hidden_obstacle_rules.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_feasibility.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_visibility_rules.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class TurnQueuedPathAdvance {
  const TurnQueuedPathAdvance({required this.unit, this.execution});

  final GameUnit unit;
  final MovementCommandExecution? execution;
}

abstract final class TurnQueuedPathAdvancer {
  static TurnQueuedPathAdvance advance({
    required GameUnit unit,
    required MapTraversalView mapData,
    required List<GameUnit> allUnits,
    required List<GameCity> cities,
    required DiplomacyState diplomacy,
    required FogOfWarState fogOfWar,
  }) {
    final path = unit.queuedPath;
    if (path == null) return TurnQueuedPathAdvance(unit: unit);
    if (!shouldKeep(unit) || unit.isFortified) {
      return TurnQueuedPathAdvance(unit: unit.copyWithQueuedPath(null));
    }

    final targetTile = mapData.tileAt(path.targetCol, path.targetRow);
    if (targetTile == null) {
      return TurnQueuedPathAdvance(unit: unit.copyWithQueuedPath(null));
    }
    final visibility = UnitMovementVisibilityRules.visibilityForActor(
      fogOfWar: fogOfWar,
      actorPlayerId: unit.ownerPlayerId,
    );
    final plan = UnitMovementPathfinder(
      mapData: mapData,
      units: UnitMovementVisibilityRules.planningUnitsForActor(
        units: allUnits,
        movingUnit: unit,
        actorPlayerId: unit.ownerPlayerId,
        visibility: visibility,
      ),
      canEnterTile: (tile) => MovementHiddenObstacleRules.canPlanThroughCity(
        cities: cities,
        diplomacy: diplomacy,
        unit: unit,
        tile: tile,
        visibility: visibility,
      ),
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
    if (plan == null) {
      return TurnQueuedPathAdvance(unit: unit.copyWithQueuedPath(null));
    }
    if (!UnitMovementFeasibility.canEventuallyTraverse(
      unit: unit,
      plan: plan,
    )) {
      return TurnQueuedPathAdvance(unit: unit.copyWithQueuedPath(null));
    }
    if (MovementHiddenObstacleRules.reachablePathHitsHiddenBlocker(
      plan: plan,
      movingUnit: unit,
      allUnits: allUnits,
      cities: cities,
      diplomacy: diplomacy,
      visibility: visibility,
    )) {
      return TurnQueuedPathAdvance(unit: unit);
    }
    return _moveAlongPlan(unit, plan);
  }

  static bool shouldKeep(GameUnit unit) {
    if (unit.isWorking) return false;
    if (unit.type != GameUnitType.merchant) return true;
    return unit.merchantTradeRoute == null;
  }

  static TurnQueuedPathAdvance _moveAlongPlan(
    GameUnit unit,
    UnitMovementPlan plan,
  ) {
    final reachable = plan.canMoveNow;
    final destination = reachable
        ? plan.steps.last
        : plan.furthestReachableStep;
    if (destination == null ||
        (destination.col == unit.col && destination.row == unit.row)) {
      return TurnQueuedPathAdvance(unit: unit);
    }
    final moved = unit.copyWith(
      col: destination.col,
      row: destination.row,
      movementPoints: plan.remainingMovementPointsAfterStep(destination),
    );
    final updated = reachable ? moved.copyWithQueuedPath(null) : moved;
    return TurnQueuedPathAdvance(
      unit: updated,
      execution: MovementCommandExecution(
        unitId: unit.id,
        fromCol: unit.col,
        fromRow: unit.row,
        steps: reachable ? plan.steps.skip(1) : plan.reachableSteps.skip(1),
      ),
    );
  }
}
