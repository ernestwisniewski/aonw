import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class SimulationGameEngineResult {
  const SimulationGameEngineResult({
    required this.accepted,
    required this.state,
    required this.snapshot,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final CanonicalGameSnapshot snapshot;
  final List<GameEvent> events;
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
    MovementCommandVisibilityMode movementVisibilityMode =
        MovementCommandVisibilityMode.authoritative,
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
        movementVisibilityMode: movementVisibilityMode,
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
        events: result.events,
      );
    }
    return _projectAcceptedResult(
      state: state,
      engineInput: engineInput,
      resultSnapshot: result.snapshot,
      events: result.events,
    );
  }

  SimulationGameEngineResult _projectAcceptedResult({
    required PersistentGameState state,
    required CanonicalGameSnapshot engineInput,
    required CanonicalGameSnapshot resultSnapshot,
    required List<GameEvent> events,
  }) {
    final domain = resultSnapshot.domain;
    final unitsChanged = !identical(domain.units, engineInput.domain.units);
    final artifactsChanged = !identical(
      domain.artifacts,
      engineInput.domain.artifacts,
    );
    final fogChanged = !identical(domain.fogOfWar, engineInput.domain.fogOfWar);
    final diplomacyChanged = !identical(
      domain.diplomacy,
      engineInput.domain.diplomacy,
    );
    final interactionChanged = !identical(
      resultSnapshot.interaction,
      engineInput.interaction,
    );
    var runtime = state.runtimeState;
    if (diplomacyChanged) {
      runtime = runtime.copyWith(diplomacy: domain.diplomacy);
    }
    if (interactionChanged) {
      runtime = runtime.copyWith(
        cityFoundingDraft: resultSnapshot.interaction.cityFoundingDraft,
        pendingAction: resultSnapshot.interaction.pendingAction,
      );
    }
    return SimulationGameEngineResult(
      accepted: true,
      snapshot: resultSnapshot,
      events: events,
      state: state.copyWith(
        units: unitsChanged ? domain.units : null,
        artifacts: artifactsChanged ? domain.artifacts : null,
        fogOfWar: fogChanged ? domain.fogOfWar : null,
        runtimeState: diplomacyChanged || interactionChanged ? runtime : null,
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
    final session = snapshot.session.copyWith(
      submittedPlayerIds: runtime.submittedPlayerIds,
      timeoutStreaksByPlayerId: runtime.timeoutStreaksByPlayerId,
      afkPlayerIds: runtime.afkPlayerIds,
      kickedPlayerIds: runtime.kickedPlayerIds,
      turnStartedAt: runtime.turnStartedAt ?? snapshot.session.turnStartedAt,
    );
    return snapshot.copyWith(
      domain: snapshot.domain.copyWith(
        playerGold: state.playerGold,
        playerWarWeariness: state.playerWarWeariness,
        playerStabilityNet: state.playerStabilityNet,
        units: state.units,
        cities: state.cities,
        artifacts: state.artifacts,
        fieldImprovements: state.fieldImprovements,
        fogOfWar: state.fogOfWar,
        research: state.research,
        wonderRegistry: state.wonderRegistry,
        intendedAttacks: runtime.intendedAttacks,
        diplomacy: runtime.diplomacy,
        resourceTradeAgreements: runtime.resourceTradeAgreements,
        dominationHoldTurnsByPlayerId: runtime.dominationHoldTurnsByPlayerId,
        culturalVictoryHoldTurnsByPlayerId:
            runtime.culturalVictoryHoldTurnsByPlayerId,
        mapObjectiveHoldStatesByObjectiveId:
            runtime.mapObjectiveHoldStatesByObjectiveId,
      ),
      session: session == snapshot.session ? snapshot.session : session,
      interaction: interaction == snapshot.interaction
          ? snapshot.interaction
          : interaction,
    );
  }
}
