import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_city_economy_command_resolver.dart';
import 'package:aonw/game/application/services/local_combat_command_resolver.dart';
import 'package:aonw/game/application/services/local_movement_command_resolver.dart';
import 'package:aonw/game/application/services/local_movement_presentation_origin.dart';
import 'package:aonw/game/application/services/local_research_diplomacy_command_resolver.dart';
import 'package:aonw/game/application/services/local_unit_action_command_resolver.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/turn/phases/selection_refresh_phase.dart';
import 'package:aonw/game/domain/turn/turn_context.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/state.dart';

part 'local_command_resolver_research_diplomacy.dart';

class LocalCommandResolution {
  final CanonicalGameSnapshot snapshot;
  final GameClientState state;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;
  final List<CombatAnimationFact> combatAnimations;
  final List<MovementCommandExecution> movementExecutions;
  final GameCommandContext context;
  final bool accepted;
  final String? rejectionReason;

  const LocalCommandResolution({
    required this.snapshot,
    required this.state,
    required this.events,
    required this.uiEffects,
    required this.context,
    this.combatAnimations = const [],
    this.movementExecutions = const [],
    this.accepted = true,
    this.rejectionReason,
  });
}

class LocalCommandResolver {
  final GameStateReducer reducer;

  const LocalCommandResolver({required this.reducer});

  LocalCommandResolution resolve({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    GameCommandContext context = const GameCommandContext(),
    LocalMovementPresentationOrigin movementPresentationOrigin =
        LocalMovementPresentationOrigin.direct,
  }) {
    final effectiveContext = _effectiveContext(baseSnapshot, context);
    final engineFamily = GameEngine.commandFamily(command);
    if (engineFamily == null) {
      throw StateError(
        '${command.runtimeType} has no canonical GameEngine family.',
      );
    }
    return switch (engineFamily) {
      GameEngineCommandFamily.turn => _resolveTurn(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command,
        savedAt: savedAt,
        context: effectiveContext,
      ),
      GameEngineCommandFamily.unitAction => _resolveUnitAction(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command,
        savedAt: savedAt,
        context: effectiveContext,
      ),
      _ => _resolveRemainingFamily(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command,
        savedAt: savedAt,
        context: effectiveContext,
        engineFamily: engineFamily,
        movementPresentationOrigin: movementPresentationOrigin,
      ),
    };
  }

  LocalCommandResolution _resolveRemainingFamily({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
    required GameEngineCommandFamily engineFamily,
    required LocalMovementPresentationOrigin movementPresentationOrigin,
  }) {
    return switch (engineFamily) {
      GameEngineCommandFamily.movement => _resolveMovement(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command,
        savedAt: savedAt,
        context: context,
        presentationOrigin: movementPresentationOrigin,
      ),
      GameEngineCommandFamily.combat => _resolveCombat(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command as AttackHexCommand,
        savedAt: savedAt,
        context: context,
      ),
      GameEngineCommandFamily.city ||
      GameEngineCommandFamily.production ||
      GameEngineCommandFamily.worker ||
      GameEngineCommandFamily.artifactTrade => _resolveCityEconomy(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command,
        savedAt: savedAt,
        context: context,
      ),
      _ => _resolveResearchDiplomacy(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command,
        savedAt: savedAt,
        context: context,
      ),
    };
  }
}

extension _LocalCommandResolverImplementation on LocalCommandResolver {
  LocalCommandResolution _resolveTurn({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    final result = _applyTurnEngine(
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      savedAt: savedAt,
      context: context,
    );
    if (result is GameEngineRejected) {
      return LocalCommandResolution(
        snapshot: baseSnapshot
            .withSavedAt(savedAt)
            .withClientState(currentState),
        state: currentState,
        events: const [],
        uiEffects: const [],
        context: context,
      );
    }
    return _acceptedTurnResolution(
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      savedAt: savedAt,
      context: context,
      accepted: result as GameEngineAccepted,
    );
  }

  GameEngineResult _applyTurnEngine({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    final playerIds = _activePlayerIds(baseSnapshot);
    return const GameEngine().apply(
      snapshot: baseSnapshot.withClientState(currentState).canonical,
      command: command,
      context: GameEngineContext(
        actorPlayerId: context.actorPlayerId ?? _turnPlayerId(command),
        mapView: reducer.mapData,
        ruleset: reducer.ruleset,
        commandTick: context.commandTick,
        turnPlayerIds: playerIds,
        requiredTurnSubmissionPlayerIds: playerIds,
        savedAt: savedAt,
      ),
    );
  }

  LocalCommandResolution _acceptedTurnResolution({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
    required GameEngineAccepted accepted,
  }) {
    final preservesRawTurnStart =
        accepted.snapshot.domain.turn == baseSnapshot.domain.turn;
    final projection = _acceptedTurnProjection(
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      accepted: accepted,
      savedAt: savedAt,
      preservesRawTurnStart: preservesRawTurnStart,
    );
    var nextState = const SelectionRefreshPhase()
        .apply(
          TurnContext(
            state: projection.state,
            save: projection.snapshot.save,
            mapTiles: reducer.mapData.mapTiles,
            ruleset: reducer.ruleset.copyWith(
              paceBalance: accepted.snapshot.domain.matchRules.paceBalance,
            ),
            playerId: _turnPlayerId(command),
            savedAt: savedAt,
          ),
        )
        .state;
    if (command is SubmitTurnCommand &&
        currentState.activePlayerId == command.playerId) {
      nextState = nextState
          .copyWith(activePlayerCanAct: false)
          .copyWithInteraction(
            moveCommandActive: false,
            movePreview: null,
            cityFoundingDraft: null,
            pendingAction: null,
          );
    }
    final movement = accepted.movementDelta;
    return LocalCommandResolution(
      snapshot: projection.snapshot.withClientState(nextState),
      state: nextState,
      events: accepted.events,
      uiEffects: const [],
      movementExecutions: movement.executions,
      context: context,
    );
  }

  ({CanonicalGameSnapshot snapshot, GameClientState state})
  _acceptedTurnProjection({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required GameEngineAccepted accepted,
    required DateTime savedAt,
    required bool preservesRawTurnStart,
  }) {
    final canonicalSameTurn =
        preservesRawTurnStart && command is EndTurnCommand;
    final snapshot = preservesRawTurnStart
        ? accepted.snapshot.copyWith(
            domain: accepted.snapshot.domain.copyWith(
              turnStartedAt: baseSnapshot.persistedTurnStartedAt,
            ),
          )
        : accepted.snapshot;
    if (canonicalSameTurn || !preservesRawTurnStart) {
      var state = currentState.withDomain(snapshot.domain);
      if (command is EndTurnCommand) {
        state = state.copyWithInteraction(
          cityFoundingDraft: snapshot.domain.actions.cityFoundingDraft,
          pendingAction: snapshot.domain.actions.pendingAction,
        );
      }
      return (snapshot: snapshot, state: state);
    }
    final state = currentState.copyWith(
      submittedPlayerIds: accepted.snapshot.domain.submittedPlayerIds,
      turnStartedAt: baseSnapshot.persistedTurnStartedAt,
    );
    return (
      snapshot: _projectUnfinalizedTurn(
        baseSnapshot: baseSnapshot,
        state: state,
        command: command,
        savedAt: savedAt,
      ),
      state: state,
    );
  }

  CanonicalGameSnapshot _projectUnfinalizedTurn({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState state,
    required DomainCommand command,
    required DateTime savedAt,
  }) {
    var projected = baseSnapshot.withSavedAt(savedAt).withClientState(state);
    final playerId = switch (command) {
      SubmitTurnCommand(:final playerId) ||
      EndTurnCommand(:final playerId) => playerId,
      _ => null,
    };
    if (playerId != null &&
        projected.domain.turnStatesByPlayerId.containsKey(playerId)) {
      projected = projected.withPlayerFinished(playerId);
    }
    return projected;
  }

  GameCommandContext _effectiveContext(
    CanonicalGameSnapshot snapshot,
    GameCommandContext context,
  ) {
    return context.copyWith(
      combatSeedTurn: snapshot.domain.turn,
      paceBalance: snapshot.domain.matchRules.paceBalance,
      victoryRules: snapshot.domain.matchRules.victory,
    );
  }

  LocalCommandResolution _resolveMovement({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
    required LocalMovementPresentationOrigin presentationOrigin,
  }) {
    final movement =
        LocalMovementCommandResolver(
          mapView: reducer.mapData,
          ruleset: reducer.ruleset,
        ).resolve(
          baseSnapshot: baseSnapshot,
          currentState: currentState,
          command: command,
          savedAt: savedAt,
          context: context,
          presentationOrigin: presentationOrigin,
        );
    return LocalCommandResolution(
      snapshot: movement.snapshot,
      state: movement.state,
      events: movement.events,
      uiEffects: movement.uiEffects,
      movementExecutions: movement.movementExecutions,
      context: context,
    );
  }

  LocalCommandResolution _resolveCityEconomy({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    final resolution =
        LocalCityEconomyCommandResolver(
          mapView: reducer.mapData,
          ruleset: reducer.ruleset,
        ).resolve(
          baseSnapshot: baseSnapshot,
          currentState: currentState,
          command: command,
          savedAt: savedAt,
          context: context,
        );
    return LocalCommandResolution(
      snapshot: resolution.snapshot,
      state: resolution.state,
      events: resolution.events,
      uiEffects: const [],
      context: context,
      accepted: resolution.accepted,
      rejectionReason: resolution.rejectionReason,
    );
  }

  LocalCommandResolution _resolveCombat({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required AttackHexCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    final combat =
        LocalCombatCommandResolver(
          mapView: reducer.mapData,
          ruleset: reducer.ruleset,
        ).resolve(
          baseSnapshot: baseSnapshot,
          currentState: currentState,
          command: command,
          savedAt: savedAt,
          context: context,
        );
    return LocalCommandResolution(
      snapshot: combat.snapshot,
      state: combat.state,
      events: combat.events,
      uiEffects: combat.uiEffects,
      context: context,
      combatAnimations: combat.combatAnimations,
    );
  }

  LocalCommandResolution _resolveUnitAction({
    required CanonicalGameSnapshot baseSnapshot,
    required GameClientState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    final resolution =
        LocalUnitActionCommandResolver(
          mapView: reducer.mapData,
          ruleset: reducer.ruleset,
        ).resolve(
          baseSnapshot: baseSnapshot,
          currentState: currentState,
          command: command,
          savedAt: savedAt,
          context: context,
        );
    return LocalCommandResolution(
      snapshot: resolution.snapshot,
      state: resolution.state,
      events: resolution.events,
      uiEffects: const [],
      context: context,
    );
  }
}

String _turnPlayerId(DomainCommand command) => switch (command) {
  SubmitTurnCommand(:final playerId) ||
  EndTurnCommand(:final playerId) => playerId,
  _ => '',
};
