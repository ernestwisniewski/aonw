import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/runtime/game_runtime_state.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/state/persistent_game_state.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_context.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_orchestrator.dart';
import 'package:aonw_core/game/domain/turn/movement/turn_movement_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class PersistentTurnMovementResult {
  factory PersistentTurnMovementResult({
    required PersistentGameState state,
    bool changed = false,
    Iterable<GameEvent> events = const [],
    Iterable<MovementCommandExecution> executions = const [],
  }) {
    return PersistentTurnMovementResult._(
      state: state,
      changed: changed,
      events: events.isEmpty ? const [] : List.unmodifiable(events),
      executions: executions.isEmpty ? const [] : List.unmodifiable(executions),
    );
  }

  const PersistentTurnMovementResult._({
    required this.state,
    required this.changed,
    required this.events,
    required this.executions,
  });

  final PersistentGameState state;
  final bool changed;
  final List<GameEvent> events;
  final List<MovementCommandExecution> executions;
}

/// Persistence adapter for the neutral turn-movement kernel.
abstract final class PersistentTurnMovementProcessor {
  static PersistentTurnMovementResult resetForPlayers({
    required PersistentGameState state,
    required Iterable<String> playerIds,
    required MapTraversalView mapData,
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    final movement = TurnMovementOrchestrator.resetForPlayers(
      state: TurnMovementState(
        units: state.units,
        cities: state.cities,
        diplomacy: state.runtimeState.diplomacy,
        fogOfWar: state.fogOfWar,
        interaction: _interactionFrom(state.runtimeState),
      ),
      context: TurnMovementContext(
        playerIds: playerIds,
        phaseKnownPlayerIds: _knownPlayerIds(state),
        mapData: mapData,
        fogOfWarService: fogOfWarService,
      ),
    );
    if (!movement.changed) return PersistentTurnMovementResult(state: state);
    final unitsChanged = !identical(movement.state.units, state.units);
    final fogChanged = !identical(movement.state.fogOfWar, state.fogOfWar);
    final runtimeState = _runtimeStateAfterMovement(
      state.runtimeState,
      movement.state,
    );
    final runtimeChanged = !identical(runtimeState, state.runtimeState);
    return PersistentTurnMovementResult(
      state: unitsChanged || fogChanged || runtimeChanged
          ? state.copyWith(
              units: unitsChanged ? movement.state.units : null,
              fogOfWar: fogChanged ? movement.state.fogOfWar : null,
              runtimeState: runtimeChanged ? runtimeState : null,
            )
          : state,
      changed: true,
      events: movement.events,
      executions: movement.executions,
    );
  }

  static GameRuntimeState _runtimeStateAfterMovement(
    GameRuntimeState runtimeState,
    TurnMovementState movement,
  ) {
    final diplomacyChanged = !identical(
      movement.diplomacy,
      runtimeState.diplomacy,
    );
    final draftChanged =
        movement.interaction.cityFoundingDraft !=
        runtimeState.cityFoundingDraft;
    final pendingChanged =
        movement.interaction.pendingAction != runtimeState.pendingAction;
    if (!diplomacyChanged && !draftChanged && !pendingChanged) {
      return runtimeState;
    }
    return runtimeState.copyWith(
      diplomacy: diplomacyChanged ? movement.diplomacy : null,
      cityFoundingDraft: draftChanged
          ? movement.interaction.cityFoundingDraft
          : runtimeState.cityFoundingDraft,
      pendingAction: pendingChanged
          ? movement.interaction.pendingAction
          : runtimeState.pendingAction,
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

  static Set<String> _knownPlayerIds(PersistentGameState state) {
    return {
      ...state.playerColors.keys,
      ...state.playerGold.keys,
      ...state.fogOfWar.playerIds,
      for (final unit in state.units) unit.ownerPlayerId,
      for (final city in state.cities) city.ownerPlayerId,
    };
  }
}
