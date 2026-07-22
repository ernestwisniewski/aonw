import 'package:aonw_core/game/domain/diplomacy/diplomatic_contact.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/movement/movement_command_result.dart';
import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/movement/queued_move_path.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_plan.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Applies one validated movement plan to borrowed state slices.
final class MovementCommandExecutor {
  const MovementCommandExecutor({required this.fogOfWarService});

  final FogOfWarService fogOfWarService;

  MovementCommandResult execute({
    required MovementCommandState state,
    required GameUnit unit,
    required int unitIndex,
    required UnitMovementPlan plan,
    required MapTraversalView mapData,
  }) {
    final destinationStep = plan.canMoveNow
        ? plan.steps.last
        : plan.furthestReachableStep;
    if (destinationStep == null ||
        unit.occupies(destinationStep.col, destinationStep.row)) {
      return _queueAtOrigin(state, unit, unitIndex, plan);
    }
    final moved = unit.copyWith(
      col: destinationStep.col,
      row: destinationStep.row,
      movementPoints: plan.remainingMovementPointsAfterStep(destinationStep),
      posture: UnitPosture.active,
    );
    return _applyMovedUnit(
      state: state,
      previousUnit: unit,
      movedUnit: plan.canMoveNow
          ? moved.copyWithQueuedPath(null)
          : moved.copyWithQueuedPath(_queuedPathFor(plan)),
      unitIndex: unitIndex,
      plan: plan,
      mapData: mapData,
    );
  }

  MovementCommandResult _queueAtOrigin(
    MovementCommandState state,
    GameUnit unit,
    int unitIndex,
    UnitMovementPlan plan,
  ) {
    final queued = unit
        .copyWith(posture: UnitPosture.active)
        .copyWithQueuedPath(_queuedPathFor(plan));
    return MovementCommandResult.accepted(
      units: _replaceUnit(state.units, unitIndex, queued),
      fogOfWar: state.fogOfWar,
      diplomacy: state.diplomacy,
    );
  }

  MovementCommandResult _applyMovedUnit({
    required MovementCommandState state,
    required GameUnit previousUnit,
    required GameUnit movedUnit,
    required int unitIndex,
    required UnitMovementPlan plan,
    required MapTraversalView mapData,
  }) {
    final units = _replaceUnit(state.units, unitIndex, movedUnit);
    final recomputedFog = fogOfWarService.recomputeAfterUnitMove(
      current: state.fogOfWar,
      mapData: mapData,
      previousUnit: previousUnit,
      movedUnit: movedUnit,
      units: units,
      cities: state.cities,
    );
    final fogOfWar = recomputedFog == state.fogOfWar
        ? state.fogOfWar
        : recomputedFog;
    final diplomacy = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: state.diplomacy,
      fogOfWar: fogOfWar,
      units: units,
      cities: state.cities,
      playerIds: state.playerIds,
    );
    final execution = MovementCommandExecution(
      unitId: previousUnit.id,
      fromCol: previousUnit.col,
      fromRow: previousUnit.row,
      steps: plan.canMoveNow ? plan.steps.skip(1) : plan.reachableSteps.skip(1),
    );
    return MovementCommandResult.accepted(
      units: units,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      events: List<GameEvent>.unmodifiable([
        UnitMovedEvent(
          unitId: previousUnit.id,
          fromCol: previousUnit.col,
          fromRow: previousUnit.row,
          toCol: movedUnit.col,
          toRow: movedUnit.row,
        ),
      ]),
      execution: execution,
    );
  }

  static QueuedMovePath _queuedPathFor(UnitMovementPlan plan) {
    return QueuedMovePath(
      targetCol: plan.targetCol,
      targetRow: plan.targetRow,
      steps: plan.steps,
    );
  }

  static List<GameUnit> _replaceUnit(
    List<GameUnit> units,
    int unitIndex,
    GameUnit updated,
  ) {
    if (units[unitIndex] == updated) return units;
    return List<GameUnit>.unmodifiable([
      for (var index = 0; index < units.length; index++)
        if (index == unitIndex) updated else units[index],
    ]);
  }
}
