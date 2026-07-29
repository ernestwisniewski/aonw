import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/advance_turn_snapshot.dart';
import 'package:aonw/game/application/services/local_combat_command_resolver.dart';
import 'package:aonw/game/application/services/local_movement_command_resolver.dart';
import 'package:aonw/game/application/services/local_movement_presentation_origin.dart';
import 'package:aonw/game/application/services/local_unit_action_command_resolver.dart';
import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/turn.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';

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
    if (engineFamily == GameEngineCommandFamily.unitAction) {
      return _resolveUnitAction(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command as DomainCommand,
        savedAt: savedAt,
        context: effectiveContext,
      );
    }
    if (engineFamily == GameEngineCommandFamily.movement) {
      return _resolveMovement(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command as DomainCommand,
        savedAt: savedAt,
        context: effectiveContext,
        presentationOrigin: movementPresentationOrigin,
      );
    }
    if (engineFamily == GameEngineCommandFamily.combat) {
      final combat =
          LocalCombatCommandResolver(
            mapView: reducer.mapData,
            ruleset: reducer.ruleset,
          ).resolve(
            baseSnapshot: baseSnapshot,
            currentState: currentState,
            command: command as AttackHexCommand,
            savedAt: savedAt,
            context: effectiveContext,
          );
      return LocalCommandResolution(
        snapshot: combat.snapshot,
        state: combat.state,
        events: combat.events,
        uiEffects: combat.uiEffects,
        context: effectiveContext,
        combatAnimations: combat.combatAnimations,
      );
    }
    return _resolveReducerCommand(
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      savedAt: savedAt,
      context: effectiveContext,
    );
  }

  LocalCommandResolution _resolveReducerCommand({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
    required GameCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    if (command is SubmitTurnCommand &&
        _rejectSubmitTurn(
          baseSnapshot: baseSnapshot,
          command: command,
          actorPlayerId: context.actorPlayerId,
        )) {
      return LocalCommandResolution(
        snapshot: baseSnapshot.withSavedAt(savedAt).withGameState(currentState),
        state: currentState,
        events: const [],
        uiEffects: const [],
        context: context,
      );
    }
    final transition = reducer.reduce(currentState, command, context: context);
    final resolved = _resolveCommand(
      baseSnapshot: baseSnapshot,
      command: command,
      reducedState: transition.state,
      savedAt: savedAt,
    );

    return LocalCommandResolution(
      snapshot: resolved.snapshot,
      state: resolved.state,
      events: [...transition.events, ...resolved.events],
      uiEffects: [...transition.uiEffects, ...resolved.uiEffects],
      context: context,
    );
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

  _ResolvedLocalCommand _resolveCommand({
    required SaveSnapshot baseSnapshot,
    required GameCommand command,
    required GameState reducedState,
    required DateTime savedAt,
  }) {
    if (command is SubmitTurnCommand) {
      return _resolveSubmitTurn(
        baseSnapshot: baseSnapshot,
        command: command,
        reducedState: reducedState,
        savedAt: savedAt,
      );
    }

    if (command is EndTurnCommand) {
      final snapshot = const AdvanceTurnPhase().advanceSnapshot(
        baseSnapshot,
        playerId: command.playerId,
        savedAt: savedAt,
      );
      return _ResolvedLocalCommand(
        snapshot: snapshot.withGameState(reducedState),
        state: reducedState,
      );
    }
    return _ResolvedLocalCommand(
      snapshot: baseSnapshot.withSavedAt(savedAt).withGameState(reducedState),
      state: reducedState,
    );
  }

  _ResolvedLocalCommand _resolveSubmitTurn({
    required SaveSnapshot baseSnapshot,
    required SubmitTurnCommand command,
    required GameState reducedState,
    required DateTime savedAt,
  }) {
    final playerIds = _activePlayerIds(baseSnapshot);
    if (!playerIds.every(reducedState.submittedPlayerIds.contains)) {
      return _ResolvedLocalCommand(
        snapshot: baseSnapshot
            .withPlayerFinished(command.playerId)
            .withSavedAt(savedAt)
            .withGameState(reducedState),
        state: reducedState,
      );
    }

    return _finalizeSimultaneousTurn(
      snapshot: baseSnapshot,
      state: reducedState,
      playerIds: playerIds,
      savedAt: savedAt.toUtc(),
    );
  }

  _ResolvedLocalCommand _finalizeSimultaneousTurn({
    required SaveSnapshot snapshot,
    required GameState state,
    required List<String> playerIds,
    required DateTime savedAt,
  }) {
    final result = CanonicalTurnPipeline.simultaneousFinalize(
      CanonicalTurnPipelineRequest.simultaneousFinalize(
        snapshot: snapshot.withGameState(state).canonical,
        playerIds: playerIds,
        savedAt: savedAt,
        mapView: reducer.mapData,
        ruleset: reducer.ruleset,
      ),
    );
    final movementDelta = result.movementDelta;
    final uiEffects = QueuedMovementEffectBuilder.fromExecutions(
      movementDelta.executions,
    );
    final resolvedSnapshot = SaveSnapshot.fromCanonical(result.snapshot);
    final nextState = resolvedSnapshot.toGameState(
      activePlayerId: state.activePlayerId,
      activePlayerCanAct: state.activePlayerCanAct,
    );

    return _ResolvedLocalCommand(
      snapshot: resolvedSnapshot,
      state: nextState,
      events: result.events,
      uiEffects: uiEffects,
    );
  }

  List<String> _activePlayerIds(SaveSnapshot snapshot) {
    final ids = snapshot.domain.participants
        .map((player) => player.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isNotEmpty) return ids..sort();

    return snapshot.session.turnStatesByPlayerId.keys
        .where((id) => id.isNotEmpty)
        .toList()
      ..sort();
  }

  bool _rejectSubmitTurn({
    required SaveSnapshot baseSnapshot,
    required SubmitTurnCommand command,
    required String? actorPlayerId,
  }) {
    return (actorPlayerId != null &&
            actorPlayerId.isNotEmpty &&
            actorPlayerId != command.playerId) ||
        !_activePlayerIds(baseSnapshot).contains(command.playerId) ||
        baseSnapshot.session.hasSubmitted(command.playerId);
  }
}

GameEngineCommandFamily? _engineFamily(GameCommand command) =>
    command is DomainCommand ? GameEngine.commandFamily(command) : null;

class _ResolvedLocalCommand {
  final SaveSnapshot snapshot;
  final GameState state;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;

  const _ResolvedLocalCommand({
    required this.snapshot,
    required this.state,
    this.events = const [],
    this.uiEffects = const [],
  });
}
