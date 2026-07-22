import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement/unit_action_command_resolver.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';

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
}
