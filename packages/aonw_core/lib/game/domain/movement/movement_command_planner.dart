import 'package:aonw_core/game/domain/diplomacy/city_entry_policy.dart';
import 'package:aonw_core/game/domain/fog/fog_visibility_query.dart';
import 'package:aonw_core/game/domain/movement/movement_command_guard.dart';
import 'package:aonw_core/game/domain/movement/movement_command_path_constraints.dart';
import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_visibility_mode.dart';
import 'package:aonw_core/game/domain/movement/movement_hidden_obstacle_rules.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_feasibility.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_visibility_rules.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

sealed class MovementPlanResolution {
  const MovementPlanResolution();
}

final class MovementPlanReady extends MovementPlanResolution {
  const MovementPlanReady(this.plan, this.knownStatePlan);

  final UnitMovementPlan plan;
  final UnitMovementPlan knownStatePlan;
}

final class MovementPlanAcceptedNoOp extends MovementPlanResolution {
  const MovementPlanAcceptedNoOp(this.knownStatePlan);

  final UnitMovementPlan knownStatePlan;
}

final class MovementPlanRejected extends MovementPlanResolution {
  const MovementPlanRejected(this.reason);

  final String reason;
}

typedef _MovementPlanCandidate = ({
  bool capacityBlocked,
  bool hiddenTargetReachedNow,
  Set<String> knownUnitIds,
  UnitMovementPlan? knownStatePlan,
  UnitMovementPlan? plan,
  GameUnit? targetBlocker,
});

/// Fog-aware path planning and hidden-dynamic-information handling.
abstract final class MovementCommandPlanner {
  static MovementPlanResolution resolve({
    required MovementCommandState state,
    required GameUnit unit,
    required MapTileView targetTile,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required MovementCommandVisibilityMode visibilityMode,
    required MovementCommandPathConstraints pathConstraints,
  }) {
    final visibility = UnitMovementVisibilityRules.visibilityForActor(
      fogOfWar: state.fogOfWar,
      actorPlayerId: actorPlayerId,
      ignoreDynamicFog: visibilityMode.ignoresDynamicFog,
    );
    bool canonicalCanEnterTile(MapTileView tile) =>
        UnitMovementVisibilityRules.canPlanThroughTile(
          unit: unit,
          tile: tile,
          visibility: visibility,
        );
    if (!visibilityMode.ignoresPathingFog &&
        !canonicalCanEnterTile(targetTile)) {
      return const MovementPlanRejected('move_path_not_found');
    }
    final foreignCityBlocked = _foreignCityBlocksTarget(
      state: state,
      unit: unit,
      targetTile: targetTile,
    );
    final hiddenForeignCity =
        foreignCityBlocked &&
        _targetIsHidden(visibility, targetTile.col, targetTile.row);
    if (foreignCityBlocked && !hiddenForeignCity) {
      return const MovementPlanRejected('move_target_is_foreign_city_center');
    }
    final canEnterTerrain = visibilityMode.ignoresPathingFog
        ? (MapTileView _) => true
        : canonicalCanEnterTile;
    bool canEnterKnownTile(MapTileView tile) {
      return !pathConstraints.excludes(tile.col, tile.row) &&
          canEnterTerrain(tile) &&
          MovementHiddenObstacleRules.canPlanThroughCity(
            cities: state.cities,
            diplomacy: state.diplomacy,
            unit: unit,
            tile: tile,
            visibility: visibility,
          );
    }

    final candidate = _planAgainstKnownState(
      state: state,
      unit: unit,
      targetTile: targetTile,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      visibility: visibility,
      canEnterTile: canEnterKnownTile,
    );
    return _resolveCandidate(
      state: state,
      unit: unit,
      candidate: candidate,
      visibility: visibility,
    );
  }

  static _MovementPlanCandidate _planAgainstKnownState({
    required MovementCommandState state,
    required GameUnit unit,
    required MapTileView targetTile,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required FogVisibilityQuery visibility,
    required bool Function(MapTileView) canEnterTile,
  }) {
    final knownUnits = UnitMovementVisibilityRules.planningUnitsForActor(
      units: state.units,
      movingUnit: unit,
      actorPlayerId: actorPlayerId,
      visibility: visibility,
    ).toList(growable: false);
    final knownUnitIds = {for (final knownUnit in knownUnits) knownUnit.id};
    final targetBlocker = _unitAt(state.units, targetTile.col, targetTile.row);
    final hiddenTargetBlocker =
        targetBlocker != null &&
        targetBlocker.id != unit.id &&
        !knownUnitIds.contains(targetBlocker.id);
    final pathfinder = UnitMovementPathfinder(
      mapData: mapData,
      units: knownUnits,
      canEnterTile: canEnterTile,
    );
    final canEnterStepBeyondCapacity = _capacityExceptionFor(
      state: state,
      unit: unit,
      targetTile: targetTile,
    );
    final directPlan = _planWithBlockedTargetApproach(
      pathfinder: pathfinder,
      unit: unit,
      targetTile: targetTile,
      targetBlocker: targetBlocker,
      visibility: visibility,
      canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
    );
    return _knownStateCandidate(
      hiddenTargetBlocker: hiddenTargetBlocker,
      knownUnitIds: knownUnitIds,
      knownUnits: knownUnits,
      pathfinder: pathfinder,
      directPlan: directPlan,
      targetBlocker: targetBlocker,
      mapData: mapData,
      canEnterTile: canEnterTile,
      visibility: visibility,
      unit: unit,
      targetTile: targetTile,
      canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
    );
  }

  static MovementPlanResolution _resolveCandidate({
    required MovementCommandState state,
    required GameUnit unit,
    required _MovementPlanCandidate candidate,
    required FogVisibilityQuery visibility,
  }) {
    final plan = candidate.plan;
    if (plan == null) {
      if (candidate.hiddenTargetReachedNow) {
        return MovementPlanAcceptedNoOp(candidate.knownStatePlan!);
      }
      return _failedPlanResolution(
        capacityBlocked: candidate.capacityBlocked,
        unit: unit,
        targetBlocker: candidate.targetBlocker,
        targetBlockerKnown:
            candidate.targetBlocker == null ||
            candidate.knownUnitIds.contains(candidate.targetBlocker?.id),
      );
    }
    if (MovementHiddenObstacleRules.reachablePathHitsHiddenBlocker(
      plan: plan,
      movingUnit: unit,
      allUnits: state.units,
      cities: state.cities,
      diplomacy: state.diplomacy,
      visibility: visibility,
    )) {
      return MovementPlanAcceptedNoOp(candidate.knownStatePlan!);
    }
    return MovementPlanReady(plan, candidate.knownStatePlan!);
  }

  static bool _capacityBlocksOnlyKnownRoute({
    required UnitMovementPlan? feasiblePlan,
    required UnitMovementPathfinder pathfinder,
    required GameUnit unit,
    required MapTileView targetTile,
    required GameUnit? targetBlocker,
    required FogVisibilityQuery visibility,
    required UnitMovementCapacityException canEnterStepBeyondCapacity,
  }) {
    if (feasiblePlan != null) return false;
    final diagnosticPlan = _planWithBlockedTargetApproach(
      pathfinder: pathfinder,
      unit: unit,
      targetTile: targetTile,
      targetBlocker: targetBlocker,
      visibility: visibility,
      canEnterStepBeyondCapacity: (_) => true,
    );
    return diagnosticPlan != null &&
        !UnitMovementFeasibility.canEventuallyTraverse(
          unit: unit,
          plan: diagnosticPlan,
          canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
        );
  }

  static UnitMovementCapacityException _capacityExceptionFor({
    required MovementCommandState state,
    required GameUnit unit,
    required MapTileView targetTile,
  }) =>
      (step) => MovementCommandGuard.canCarryArtifactIntoTargetCity(
        state: state,
        unit: unit,
        targetTile: targetTile,
        step: step,
      );

  static _MovementPlanCandidate _knownStateCandidate({
    required bool hiddenTargetBlocker,
    required Set<String> knownUnitIds,
    required List<GameUnit> knownUnits,
    required UnitMovementPathfinder pathfinder,
    required UnitMovementPlan? directPlan,
    required GameUnit? targetBlocker,
    required MapTraversalView mapData,
    required bool Function(MapTileView) canEnterTile,
    required FogVisibilityQuery visibility,
    required GameUnit unit,
    required MapTileView targetTile,
    required UnitMovementCapacityException canEnterStepBeyondCapacity,
  }) {
    if (!hiddenTargetBlocker || directPlan?.canMoveNow != true) {
      final capacityBlocked = _capacityBlocksOnlyKnownRoute(
        feasiblePlan: directPlan,
        pathfinder: pathfinder,
        unit: unit,
        targetTile: targetTile,
        targetBlocker: targetBlocker,
        visibility: visibility,
        canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
      );
      return (
        capacityBlocked: capacityBlocked,
        hiddenTargetReachedNow: false,
        knownUnitIds: knownUnitIds,
        knownStatePlan: directPlan,
        plan: directPlan,
        targetBlocker: targetBlocker,
      );
    }
    final approach = _planTowardHiddenBlockedTarget(
      pathfinder: UnitMovementPathfinder(
        mapData: mapData,
        units: [...knownUnits, targetBlocker!],
        canEnterTile: canEnterTile,
      ),
      unit: unit,
      targetTile: targetTile,
      canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
    );
    return (
      capacityBlocked: false,
      hiddenTargetReachedNow: true,
      knownUnitIds: knownUnitIds,
      knownStatePlan: directPlan,
      plan: approach,
      targetBlocker: targetBlocker,
    );
  }

  static UnitMovementPlan? _planTowardHiddenBlockedTarget({
    required UnitMovementPathfinder pathfinder,
    required GameUnit unit,
    required MapTileView targetTile,
    required UnitMovementCapacityException canEnterStepBeyondCapacity,
  }) {
    return pathfinder.planTowardBlockedTarget(
      unit: unit,
      targetTile: targetTile,
      canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
    );
  }

  static UnitMovementPlan? _planWithBlockedTargetApproach({
    required UnitMovementPathfinder pathfinder,
    required GameUnit unit,
    required MapTileView targetTile,
    required GameUnit? targetBlocker,
    required FogVisibilityQuery visibility,
    required UnitMovementCapacityException canEnterStepBeyondCapacity,
  }) {
    final direct = pathfinder.plan(
      unit: unit,
      targetTile: targetTile,
      canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
    );
    if (direct != null ||
        targetBlocker == null ||
        targetBlocker.id == unit.id) {
      return direct;
    }
    final approach = pathfinder.planTowardBlockedTarget(
      unit: unit,
      targetTile: targetTile,
      canEnterStepBeyondCapacity: canEnterStepBeyondCapacity,
    );
    if (approach == null) return null;
    final shouldApproach =
        _targetIsHidden(visibility, targetTile.col, targetTile.row) ||
        targetBlocker.ownerPlayerId != unit.ownerPlayerId ||
        approach.totalCost > unit.movementPoints;
    return shouldApproach ? approach : null;
  }

  static MovementPlanResolution _failedPlanResolution({
    required bool capacityBlocked,
    required GameUnit unit,
    required GameUnit? targetBlocker,
    required bool targetBlockerKnown,
  }) {
    if (capacityBlocked) {
      return const MovementPlanRejected('unit_movement_capacity_insufficient');
    }
    if (targetBlocker != null && targetBlocker.id != unit.id) {
      return targetBlockerKnown
          ? const MovementPlanRejected('move_target_occupied')
          : const MovementPlanRejected('move_path_not_found');
    }
    return const MovementPlanRejected('move_path_not_found');
  }

  static bool _foreignCityBlocksTarget({
    required MovementCommandState state,
    required GameUnit unit,
    required MapTileView targetTile,
  }) {
    return _foreignCityBlocksTile(
      state: state,
      unit: unit,
      col: targetTile.col,
      row: targetTile.row,
    );
  }

  static bool _foreignCityBlocksTile({
    required MovementCommandState state,
    required GameUnit unit,
    required int col,
    required int row,
  }) {
    return CityEntryPolicy.blocksCityCenterEntry(
      diplomacy: state.diplomacy,
      cities: state.cities,
      unitOwnerPlayerId: unit.ownerPlayerId,
      col: col,
      row: row,
    );
  }

  static bool _targetIsHidden(FogVisibilityQuery visibility, int col, int row) {
    return visibility.isEnabled && !visibility.canSeeDynamicAt(col, row);
  }

  static GameUnit? _unitAt(List<GameUnit> units, int col, int row) {
    for (final unit in units) {
      if (unit.occupies(col, row)) return unit;
    }
    return null;
  }
}
