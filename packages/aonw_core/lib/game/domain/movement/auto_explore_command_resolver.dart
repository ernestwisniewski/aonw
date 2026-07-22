import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_guard.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_phase.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_result.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_resolver.dart';
import 'package:aonw_core/game/domain/movement/movement_command_result.dart';
import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_visibility_mode.dart';
import 'package:aonw_core/game/domain/movement/movement_hidden_obstacle_rules.dart';
import 'package:aonw_core/game/domain/movement/scout_auto_explore_planner.dart';
import 'package:aonw_core/game/domain/movement/scout_auto_explore_target.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_visibility_rules.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/state/persisted_interaction_unit_rules.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

/// Resolves auto-exploration without depending on a persisted state container.
final class AutoExploreCommandResolver {
  const AutoExploreCommandResolver({
    this.fogOfWarService = const FogOfWarService(),
  });

  final FogOfWarService fogOfWarService;

  AutoExploreCommandResult resolve({
    required AutoExploreCommandState state,
    required AutoExploreUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required AutoExploreCommandPhase phase,
    bool canAct = true,
  }) {
    final guarded = AutoExploreCommandGuard.validate(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      canAct: canAct,
    );
    if (guarded.reason case final reason?) return _reject(state, reason);

    final unit = guarded.unit!;
    final target = _targetFor(
      state: state,
      unit: unit,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
    );
    if (target == null) {
      return phase == AutoExploreCommandPhase.direct
          ? _reject(state, 'auto_explore_no_target')
          : _finishContinuation(state, guarded.unitIndex!, unit);
    }
    return _moveTowardTarget(
      state: state,
      unit: unit,
      unitIndex: guarded.unitIndex!,
      target: target,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      phase: phase,
    );
  }

  static ScoutAutoExploreTarget? _targetFor({
    required AutoExploreCommandState state,
    required GameUnit unit,
    required String actorPlayerId,
    required MapTraversalView mapData,
  }) {
    final movement = state.movement;
    final visibility = UnitMovementVisibilityRules.visibilityForActor(
      fogOfWar: movement.fogOfWar,
      actorPlayerId: actorPlayerId,
    );
    final knownUnits = UnitMovementVisibilityRules.planningUnitsForActor(
      units: movement.units,
      movingUnit: unit,
      actorPlayerId: actorPlayerId,
      visibility: visibility,
    );
    bool canEnterTile(MapTileView tile) {
      return MovementHiddenObstacleRules.canPlanThroughCity(
        cities: movement.cities,
        diplomacy: movement.diplomacy,
        unit: unit,
        tile: tile,
        visibility: visibility,
      );
    }

    return const ScoutAutoExplorePlanner().targetFor(
      unit: unit,
      mapData: mapData,
      units: knownUnits,
      fogOfWar: movement.fogOfWar,
      canEnterTile: canEnterTile,
    );
  }

  AutoExploreCommandResult _moveTowardTarget({
    required AutoExploreCommandState state,
    required GameUnit unit,
    required int unitIndex,
    required ScoutAutoExploreTarget target,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required AutoExploreCommandPhase phase,
  }) {
    final interaction = PersistedInteractionUnitRules.clearOwnedByUnit(
      state.interaction,
      unit.id,
    );
    final primedUnits = _replaceUnit(
      state.movement.units,
      unitIndex,
      unit
          .copyWith(posture: UnitPosture.autoExploring)
          .copyWithQueuedPath(null),
    );
    final moved = MovementCommandResolver(fogOfWarService: fogOfWarService)
        .resolve(
          state: _movementStateWithUnits(state.movement, primedUnits),
          command: target.command,
          actorPlayerId: actorPlayerId,
          mapData: mapData,
          visibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
          pathConstraints: target.pathConstraints,
        );
    if (!moved.accepted) {
      return _reject(state, moved.reason ?? 'move_failed');
    }
    return _acceptMoved(
      state: state,
      moved: moved,
      interaction: interaction,
      unitId: unit.id,
      phase: phase,
    );
  }

  static AutoExploreCommandResult _finishContinuation(
    AutoExploreCommandState state,
    int unitIndex,
    GameUnit unit,
  ) {
    return AutoExploreCommandResult.accepted(
      units: _replaceUnit(
        state.movement.units,
        unitIndex,
        unit.copyWith(posture: UnitPosture.active).copyWithQueuedPath(null),
      ),
      fogOfWar: state.movement.fogOfWar,
      diplomacy: state.movement.diplomacy,
      interaction: PersistedInteractionUnitRules.clearOwnedByUnit(
        state.interaction,
        unit.id,
      ),
    );
  }

  static AutoExploreCommandResult _acceptMoved({
    required AutoExploreCommandState state,
    required MovementCommandResult moved,
    required PersistedInteractionState interaction,
    required String unitId,
    required AutoExploreCommandPhase phase,
  }) {
    final unitIndex = _unitIndexById(moved.units, unitId);
    if (unitIndex == null) return _reject(state, 'unit_not_found');
    final movedUnit = moved.units[unitIndex];
    final finished =
        phase == AutoExploreCommandPhase.continuation &&
        moved.execution == null &&
        movedUnit.queuedPath == null;
    return AutoExploreCommandResult.accepted(
      units: _replaceUnit(
        moved.units,
        unitIndex,
        movedUnit.copyWith(
          posture: finished ? UnitPosture.active : UnitPosture.autoExploring,
        ),
      ),
      fogOfWar: moved.fogOfWar,
      diplomacy: moved.diplomacy,
      interaction: interaction,
      events: moved.events,
      execution: moved.execution,
    );
  }

  static MovementCommandState _movementStateWithUnits(
    MovementCommandState state,
    List<GameUnit> units,
  ) {
    return MovementCommandState(
      units: units,
      cities: state.cities,
      fogOfWar: state.fogOfWar,
      diplomacy: state.diplomacy,
      playerIds: state.playerIds,
    );
  }

  static AutoExploreCommandResult _reject(
    AutoExploreCommandState state,
    String reason,
  ) {
    return AutoExploreCommandResult.rejected(
      units: state.movement.units,
      fogOfWar: state.movement.fogOfWar,
      diplomacy: state.movement.diplomacy,
      interaction: state.interaction,
      reason: reason,
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

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var index = 0; index < units.length; index++) {
      if (units[index].id == unitId) return index;
    }
    return null;
  }
}
