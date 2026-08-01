import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/movement/movement_command_executor.dart';
import 'package:aonw_core/game/domain/movement/movement_command_guard.dart';
import 'package:aonw_core/game/domain/movement/movement_command_path_constraints.dart';
import 'package:aonw_core/game/domain/movement/movement_command_planner.dart';
import 'package:aonw_core/game/domain/movement/movement_command_result.dart';
import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_visibility_mode.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_feasibility.dart';
import 'package:aonw_core/game/domain/movement/unit_manual_movement_rules.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

/// Applies authoritative manual-movement rules without a state container.
final class MovementCommandResolver {
  const MovementCommandResolver({
    this.fogOfWarService = const FogOfWarService(),
  });

  final FogOfWarService fogOfWarService;

  MovementCommandResult resolve({
    required MovementCommandState state,
    required MoveUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
    bool canAct = true,
    MovementCommandVisibilityMode visibilityMode =
        MovementCommandVisibilityMode.authoritative,
    MovementCommandPathConstraints pathConstraints =
        const MovementCommandPathConstraints.none(),
  }) {
    final guarded = MovementCommandGuard.validate(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      canAct: canAct,
    );
    if (guarded.reason case final reason?) return _reject(state, reason);

    final unit = UnitManualMovementRules.prepareForCommand(guarded.unit!);
    final targetTile = guarded.targetTile!;
    final planned = MovementCommandPlanner.resolve(
      state: state,
      unit: unit,
      targetTile: targetTile,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      visibilityMode: visibilityMode,
      pathConstraints: pathConstraints,
    );
    return switch (planned) {
      MovementPlanRejected(:final reason) => _reject(state, reason),
      MovementPlanAcceptedNoOp(:final knownStatePlan) =>
        _canEventuallyTraverse(
              state: state,
              unit: unit,
              targetTile: targetTile,
              plan: knownStatePlan,
            )
            ? _accept(state)
            : _reject(state, 'unit_movement_capacity_insufficient'),
      MovementPlanReady(:final plan, :final knownStatePlan) =>
        _canEventuallyTraverse(
              state: state,
              unit: unit,
              targetTile: targetTile,
              plan: knownStatePlan,
            )
            ? MovementCommandExecutor(fogOfWarService: fogOfWarService).execute(
                state: state,
                unit: unit,
                unitIndex: guarded.unitIndex!,
                plan: plan,
                mapData: mapData,
              )
            : _reject(state, 'unit_movement_capacity_insufficient'),
    };
  }

  static bool _canEventuallyTraverse({
    required MovementCommandState state,
    required GameUnit unit,
    required MapTileView targetTile,
    required UnitMovementPlan plan,
  }) {
    return UnitMovementFeasibility.canEventuallyTraverse(
      unit: unit,
      plan: plan,
      canEnterStepBeyondCapacity: (step) =>
          MovementCommandGuard.canCarryArtifactIntoTargetCity(
            state: state,
            unit: unit,
            targetTile: targetTile,
            step: step,
          ),
    );
  }

  static MovementCommandResult _accept(MovementCommandState state) {
    return MovementCommandResult.accepted(
      units: state.units,
      fogOfWar: state.fogOfWar,
      diplomacy: state.diplomacy,
    );
  }

  static MovementCommandResult _reject(
    MovementCommandState state,
    String reason,
  ) {
    return MovementCommandResult.rejected(
      units: state.units,
      fogOfWar: state.fogOfWar,
      diplomacy: state.diplomacy,
      reason: reason,
    );
  }
}
