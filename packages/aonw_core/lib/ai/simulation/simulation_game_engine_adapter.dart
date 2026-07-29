import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class SimulationGameEngineResult {
  const SimulationGameEngineResult({
    required this.accepted,
    required this.state,
    required this.snapshot,
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final CanonicalGameSnapshot snapshot;
  final String? reason;
}

/// Projects state-only AI simulations through the authoritative game engine.
final class SimulationGameEngineAdapter {
  const SimulationGameEngineAdapter();

  SimulationGameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required PersistentGameState state,
    required DomainCommand command,
    required String actorPlayerId,
    required int commandTick,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    final engineInput = _engineInput(snapshot: snapshot, state: state);
    final result = const GameEngine().apply(
      snapshot: engineInput,
      command: command,
      context: GameEngineContext(
        actorPlayerId: actorPlayerId,
        mapView: mapView,
        ruleset: ruleset,
        commandTick: commandTick,
      ),
    );
    if (result is GameEngineRejected) {
      return SimulationGameEngineResult(
        accepted: false,
        state: state,
        snapshot: result.snapshot,
        reason: result.reason,
      );
    }
    if (identical(result.snapshot, engineInput)) {
      return SimulationGameEngineResult(
        accepted: true,
        state: state,
        snapshot: result.snapshot,
      );
    }
    return _projectAcceptedResult(
      state: state,
      engineInput: engineInput,
      resultSnapshot: result.snapshot,
    );
  }

  SimulationGameEngineResult _projectAcceptedResult({
    required PersistentGameState state,
    required CanonicalGameSnapshot engineInput,
    required CanonicalGameSnapshot resultSnapshot,
  }) {
    final domain = resultSnapshot.domain;
    final unitsChanged = !identical(domain.units, engineInput.domain.units);
    final artifactsChanged = !identical(
      domain.artifacts,
      engineInput.domain.artifacts,
    );
    final interactionChanged = !identical(
      resultSnapshot.interaction,
      engineInput.interaction,
    );
    return SimulationGameEngineResult(
      accepted: true,
      snapshot: resultSnapshot,
      state: state.copyWith(
        units: unitsChanged ? domain.units : null,
        artifacts: artifactsChanged ? domain.artifacts : null,
        runtimeState: interactionChanged
            ? state.runtimeState.copyWith(
                cityFoundingDraft: resultSnapshot.interaction.cityFoundingDraft,
                pendingAction: resultSnapshot.interaction.pendingAction,
              )
            : null,
      ),
    );
  }

  CanonicalGameSnapshot _engineInput({
    required CanonicalGameSnapshot snapshot,
    required PersistentGameState state,
  }) {
    final runtime = state.runtimeState;
    final interaction = PersistedInteractionState(
      cityFoundingDraft: runtime.cityFoundingDraft,
      pendingAction: runtime.pendingAction,
    );
    return snapshot.copyWith(
      domain: snapshot.domain.copyWith(
        units: state.units,
        artifacts: state.artifacts,
      ),
      interaction: interaction == snapshot.interaction
          ? snapshot.interaction
          : interaction,
    );
  }
}
