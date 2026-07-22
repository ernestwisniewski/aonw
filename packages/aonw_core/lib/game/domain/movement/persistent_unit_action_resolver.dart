import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement/movement_command_visibility_mode.dart';
import 'package:aonw_core/game/domain/movement/persistent_move_unit_resolver.dart';
import 'package:aonw_core/game/domain/movement/scout_auto_explore_planner.dart';
import 'package:aonw_core/game/domain/movement/unit_action_command_resolver.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class PersistentUnitActionResult {
  const PersistentUnitActionResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;
}

final class PersistentUnitActionResolver {
  const PersistentUnitActionResolver();

  PersistentUnitActionResult cancelUnitAction({
    required PersistentGameState state,
    required CancelUnitActionCommand command,
    required String actorPlayerId,
  }) {
    return _applyUnitAction(
      state,
      UnitActionCommandResolver.cancelUnitAction(
        units: state.units,
        artifacts: state.artifacts,
        interaction: _interactionFrom(state.runtimeState),
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  PersistentUnitActionResult skipUnitTurn({
    required PersistentGameState state,
    required SkipUnitTurnCommand command,
    required String actorPlayerId,
  }) {
    return _applyUnitAction(
      state,
      UnitActionCommandResolver.skipUnitTurn(
        units: state.units,
        artifacts: state.artifacts,
        interaction: _interactionFrom(state.runtimeState),
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  PersistentUnitActionResult fortifyUnit({
    required PersistentGameState state,
    required FortifyUnitCommand command,
    required String actorPlayerId,
  }) {
    return _applyUnitAction(
      state,
      UnitActionCommandResolver.fortifyUnit(
        units: state.units,
        artifacts: state.artifacts,
        interaction: _interactionFrom(state.runtimeState),
        command: command,
        actorPlayerId: actorPlayerId,
      ),
    );
  }

  PersistentUnitActionResult autoExploreUnit({
    required PersistentGameState state,
    required AutoExploreUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
  }) {
    final unit = state.units.byId(command.unitId);
    if (unit == null) return _reject(state, 'unit_not_found');
    if (unit.ownerPlayerId != actorPlayerId) {
      return _reject(state, 'unit_not_controlled');
    }
    if (unit.type != GameUnitType.scout) {
      return _reject(state, 'unit_not_scout');
    }
    if (unit.isWorking || unit.isFortified) return _reject(state, 'unit_busy');
    if (unit.movementPoints <= 0) return _reject(state, 'unit_exhausted');
    if (unit.queuedPath != null) return _reject(state, 'unit_has_path');

    final move = const ScoutAutoExplorePlanner().commandFor(
      unit: unit,
      mapData: mapData,
      units: state.units,
      fogOfWar: state.fogOfWar,
    );
    if (move == null) return _reject(state, 'auto_explore_no_target');

    final exploring = unit
        .copyWith(posture: UnitPosture.autoExploring)
        .copyWithQueuedPath(null);
    final primed = _replaceUnitAndClearRuntimeAction(state, unit, exploring);
    final moved = const PersistentMoveUnitResolver().resolve(
      state: primed,
      command: move,
      actorPlayerId: actorPlayerId,
      mapData: mapData,
      visibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
    );
    if (!moved.accepted) return _reject(state, moved.reason ?? 'move_failed');

    final movedUnit = moved.state.units.byId(unit.id);
    if (movedUnit == null) return _reject(state, 'unit_not_found');
    return PersistentUnitActionResult(
      accepted: true,
      state: moved.state.copyWith(
        units: _replaceUnit(
          moved.state.units,
          movedUnit.copyWith(posture: UnitPosture.autoExploring),
        ),
      ),
      events: moved.events,
    );
  }

  PersistentUnitActionResult _reject(PersistentGameState state, String reason) {
    return PersistentUnitActionResult(
      accepted: false,
      state: state,
      reason: reason,
    );
  }

  static PersistentUnitActionResult _applyUnitAction(
    PersistentGameState state,
    UnitActionCommandResult result,
  ) {
    if (!result.accepted) {
      return PersistentUnitActionResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    final unitsChanged = !identical(result.units, state.units);
    final artifactsChanged = !identical(result.artifacts, state.artifacts);
    final runtimeState = _runtimeStateAfterUnitAction(
      state.runtimeState,
      result.interaction,
    );
    return PersistentUnitActionResult(
      accepted: true,
      state:
          unitsChanged ||
              artifactsChanged ||
              !identical(runtimeState, state.runtimeState)
          ? state.copyWith(
              units: unitsChanged ? result.units : null,
              artifacts: artifactsChanged ? result.artifacts : null,
              runtimeState: identical(runtimeState, state.runtimeState)
                  ? null
                  : runtimeState,
            )
          : state,
    );
  }

  static GameRuntimeState _runtimeStateAfterUnitAction(
    GameRuntimeState runtimeState,
    PersistedInteractionState interaction,
  ) {
    if (runtimeState.cityFoundingDraft == interaction.cityFoundingDraft &&
        runtimeState.pendingAction == interaction.pendingAction) {
      return runtimeState;
    }
    return runtimeState.copyWith(
      cityFoundingDraft: interaction.cityFoundingDraft,
      pendingAction: interaction.pendingAction,
    );
  }

  static PersistedInteractionState _interactionFrom(
    GameRuntimeState runtimeState,
  ) {
    return PersistedInteractionState(
      cityFoundingDraft: runtimeState.cityFoundingDraft,
      pendingAction: runtimeState.pendingAction,
    );
  }

  static PersistentGameState _replaceUnitAndClearRuntimeAction(
    PersistentGameState state,
    GameUnit original,
    GameUnit updated,
  ) {
    final runtimeState = _clearRuntimeActionForUnit(
      state.runtimeState,
      original.id,
    );
    return state.copyWith(
      units: _replaceUnit(state.units, updated),
      runtimeState: runtimeState,
    );
  }

  static GameRuntimeState _clearRuntimeActionForUnit(
    GameRuntimeState runtimeState,
    String unitId,
  ) {
    final clearPending = runtimeState.pendingAction?.ownsUnit(unitId) ?? false;
    final clearDraft = runtimeState.cityFoundingDraft?.unitId == unitId;
    if (!clearPending && !clearDraft) return runtimeState;

    return runtimeState.copyWith(
      cityFoundingDraft: clearDraft ? null : runtimeState.cityFoundingDraft,
      pendingAction: clearPending ? null : runtimeState.pendingAction,
    );
  }

  static List<GameUnit> _replaceUnit(List<GameUnit> units, GameUnit updated) {
    return [
      for (final unit in units)
        if (unit.id == updated.id) updated else unit,
    ];
  }
}
