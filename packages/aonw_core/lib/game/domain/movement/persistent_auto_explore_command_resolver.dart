import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_phase.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_resolver.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_result.dart';
import 'package:aonw_core/game/domain/movement/auto_explore_command_state.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/movement/movement_command_state.dart';
import 'package:aonw_core/game/domain/runtime/game_runtime_state.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/state/persistent_game_state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class PersistentAutoExploreCommandResult {
  const PersistentAutoExploreCommandResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.execution,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final MovementCommandExecution? execution;
  final String? reason;
}

/// Persistence adapter for the neutral auto-explore command resolver.
final class PersistentAutoExploreCommandResolver {
  const PersistentAutoExploreCommandResolver({
    this.fogOfWarService = const FogOfWarService(),
  });

  final FogOfWarService fogOfWarService;

  PersistentAutoExploreCommandResult resolve({
    required PersistentGameState state,
    required AutoExploreUnitCommand command,
    required String actorPlayerId,
    required MapTraversalView mapData,
    required AutoExploreCommandPhase phase,
    bool canAct = true,
  }) {
    final result = AutoExploreCommandResolver(fogOfWarService: fogOfWarService)
        .resolve(
          state: AutoExploreCommandState(
            movement: MovementCommandState(
              units: state.units,
              cities: state.cities,
              fogOfWar: state.fogOfWar,
              diplomacy: state.runtimeState.diplomacy,
              playerIds: state.knownPlayerIds,
            ),
            interaction: PersistedInteractionState(
              cityFoundingDraft: state.runtimeState.cityFoundingDraft,
              pendingAction: state.runtimeState.pendingAction,
            ),
          ),
          command: command,
          actorPlayerId: actorPlayerId,
          mapData: mapData,
          phase: phase,
          canAct: canAct,
        );
    return _apply(state, result);
  }

  static PersistentAutoExploreCommandResult _apply(
    PersistentGameState state,
    AutoExploreCommandResult result,
  ) {
    if (!result.accepted) {
      return PersistentAutoExploreCommandResult(
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    final unitsChanged = !identical(result.units, state.units);
    final fogChanged = !identical(result.fogOfWar, state.fogOfWar);
    final runtimeState = _runtimeStateAfterResult(state.runtimeState, result);
    final runtimeChanged = !identical(runtimeState, state.runtimeState);
    final nextState = unitsChanged || fogChanged || runtimeChanged
        ? state.copyWith(
            units: unitsChanged ? result.units : null,
            fogOfWar: fogChanged ? result.fogOfWar : null,
            runtimeState: runtimeChanged ? runtimeState : null,
          )
        : state;
    return PersistentAutoExploreCommandResult(
      accepted: true,
      state: nextState,
      events: result.events,
      execution: result.execution,
    );
  }

  static GameRuntimeState _runtimeStateAfterResult(
    GameRuntimeState runtimeState,
    AutoExploreCommandResult result,
  ) {
    final diplomacyChanged = !identical(
      result.diplomacy,
      runtimeState.diplomacy,
    );
    final draftChanged =
        result.interaction.cityFoundingDraft != runtimeState.cityFoundingDraft;
    final pendingChanged =
        result.interaction.pendingAction != runtimeState.pendingAction;
    if (!diplomacyChanged && !draftChanged && !pendingChanged) {
      return runtimeState;
    }
    return runtimeState.copyWith(
      diplomacy: diplomacyChanged ? result.diplomacy : null,
      cityFoundingDraft: draftChanged
          ? result.interaction.cityFoundingDraft
          : runtimeState.cityFoundingDraft,
      pendingAction: pendingChanged
          ? result.interaction.pendingAction
          : runtimeState.pendingAction,
    );
  }
}
