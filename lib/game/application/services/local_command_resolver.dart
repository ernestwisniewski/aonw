import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/local_city_economy_command_resolver.dart';
import 'package:aonw/game/application/services/local_combat_command_resolver.dart';
import 'package:aonw/game/application/services/local_movement_command_resolver.dart';
import 'package:aonw/game/application/services/local_movement_presentation_origin.dart';
import 'package:aonw/game/application/services/local_research_diplomacy_command_resolver.dart';
import 'package:aonw/game/application/services/local_unit_action_command_resolver.dart';
import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';

part 'local_command_resolver_research_diplomacy.dart';

class LocalCommandResolution {
  final SaveSnapshot snapshot;
  final GameState state;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;
  final List<CombatAnimationFact> combatAnimations;
  final GameCommandContext context;

  const LocalCommandResolution({
    required this.snapshot,
    required this.state,
    required this.events,
    required this.uiEffects,
    required this.context,
    this.combatAnimations = const [],
  });
}

class LocalCommandResolver {
  final GameStateReducer reducer;

  const LocalCommandResolver({required this.reducer});

  LocalCommandResolution resolve({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
    required GameCommand command,
    required DateTime savedAt,
    GameCommandContext context = const GameCommandContext(),
    LocalMovementPresentationOrigin movementPresentationOrigin =
        LocalMovementPresentationOrigin.direct,
  }) {
    final effectiveContext = _effectiveContext(baseSnapshot, context);
    final engineFamily = _engineFamily(command);
    return switch (engineFamily) {
      GameEngineCommandFamily.turn => _resolveTurn(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command as DomainCommand,
        savedAt: savedAt,
        context: effectiveContext,
      ),
      GameEngineCommandFamily.unitAction => _resolveUnitAction(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command as DomainCommand,
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
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
    required GameCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
    required GameEngineCommandFamily? engineFamily,
    required LocalMovementPresentationOrigin movementPresentationOrigin,
  }) {
    return switch (engineFamily) {
      GameEngineCommandFamily.movement => _resolveMovement(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command as DomainCommand,
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
        command: command as DomainCommand,
        savedAt: savedAt,
        context: context,
      ),
      _ => _resolveResearchDiplomacyOrReducer(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command,
        savedAt: savedAt,
        context: context,
        engineFamily: engineFamily,
      ),
    };
  }

  LocalCommandResolution _resolveReducerCommand({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
    required GameCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    final transition = reducer.reduce(currentState, command, context: context);
    return LocalCommandResolution(
      snapshot: baseSnapshot
          .withSavedAt(savedAt)
          .withGameState(transition.state),
      state: transition.state,
      events: transition.events,
      uiEffects: transition.uiEffects,
      context: context,
    );
  }
}

extension _LocalCommandResolverImplementation on LocalCommandResolver {
  LocalCommandResolution _resolveTurn({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
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
        snapshot: baseSnapshot.withSavedAt(savedAt).withGameState(currentState),
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
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    final playerIds = _activePlayerIds(baseSnapshot);
    return const GameEngine().apply(
      snapshot: baseSnapshot.withGameState(currentState).canonical,
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
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
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
    var nextState = projection.state;
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
      snapshot: projection.snapshot.withGameState(nextState),
      state: nextState,
      events: accepted.events,
      uiEffects: QueuedMovementEffectBuilder.fromExecutions(
        movement.executions,
        beforeUnits: movement.beforeUnits,
        afterUnits: movement.afterUnits,
      ),
      context: context,
    );
  }

  ({SaveSnapshot snapshot, GameState state}) _acceptedTurnProjection({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
    required DomainCommand command,
    required GameEngineAccepted accepted,
    required DateTime savedAt,
    required bool preservesRawTurnStart,
  }) {
    final canonicalSameTurn =
        preservesRawTurnStart && command is EndTurnCommand;
    final snapshot = SaveSnapshot.fromCanonical(accepted.snapshot);
    final persistent = preservesRawTurnStart
        ? snapshot.rawPersistentState.copyWith(
            runtimeState: snapshot.runtimeState.copyWith(
              turnStartedAt: baseSnapshot.persistedTurnStartedAt,
            ),
          )
        : snapshot.rawPersistentState;
    if (canonicalSameTurn || !preservesRawTurnStart) {
      return (
        snapshot: SaveSnapshot.fromPersistentState(
          save: snapshot.save,
          state: persistent,
          eventLogOffset: snapshot.eventLogOffset,
        ),
        state: currentState
            .copyWithPersistentState(persistent)
            .copyWithInteraction(
              cityFoundingDraft:
                  accepted.snapshot.interaction.cityFoundingDraft,
              pendingAction: accepted.snapshot.interaction.pendingAction,
            ),
      );
    }
    final state = currentState
        .copyWith(
          submittedPlayerIds: accepted.snapshot.session.submittedPlayerIds,
          turnStartedAt: baseSnapshot.persistedTurnStartedAt,
        )
        .copyWithInteraction(
          cityFoundingDraft: accepted.snapshot.interaction.cityFoundingDraft,
          pendingAction: accepted.snapshot.interaction.pendingAction,
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

  SaveSnapshot _projectUnfinalizedTurn({
    required SaveSnapshot baseSnapshot,
    required GameState state,
    required DomainCommand command,
    required DateTime savedAt,
  }) {
    var projected = baseSnapshot.withSavedAt(savedAt).withGameState(state);
    final playerId = switch (command) {
      SubmitTurnCommand(:final playerId) ||
      EndTurnCommand(:final playerId) => playerId,
      _ => null,
    };
    if (playerId != null &&
        projected.session.turnStatesByPlayerId.containsKey(playerId)) {
      projected = projected.withPlayerFinished(playerId);
    }
    return projected;
  }

  GameCommandContext _effectiveContext(
    SaveSnapshot snapshot,
    GameCommandContext context,
  ) {
    return context.copyWith(
      combatSeedTurn: snapshot.domain.turn,
      paceBalance: snapshot.domain.matchRules.paceBalance,
      victoryRules: snapshot.domain.matchRules.victory,
    );
  }

  LocalCommandResolution _resolveMovement({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
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
      context: context,
    );
  }

  LocalCommandResolution _resolveCityEconomy({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
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
    );
  }

  LocalCommandResolution _resolveCombat({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
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
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
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

GameEngineCommandFamily? _engineFamily(GameCommand command) =>
    command is DomainCommand ? GameEngine.commandFamily(command) : null;

String _turnPlayerId(DomainCommand command) => switch (command) {
  SubmitTurnCommand(:final playerId) ||
  EndTurnCommand(:final playerId) => playerId,
  _ => '',
};
