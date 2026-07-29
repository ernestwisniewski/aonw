import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/advance_turn_snapshot.dart';
import 'package:aonw/game/application/services/local_unit_action_projection.dart';
import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/turn.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/event.dart';

class LocalCommandResolution {
  final SaveSnapshot snapshot;
  final GameState state;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;
  final GameCommandContext context;

  const LocalCommandResolution({
    required this.snapshot,
    required this.state,
    required this.events,
    required this.uiEffects,
    required this.context,
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
  }) {
    final effectiveContext = context.copyWith(
      combatSeedTurn: baseSnapshot.domain.turn,
      paceBalance: baseSnapshot.domain.matchRules.paceBalance,
      victoryRules: baseSnapshot.domain.matchRules.victory,
    );
    if (command is SkipUnitTurnCommand || command is FortifyUnitCommand) {
      return _resolveEngineUnitAction(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        command: command as DomainCommand,
        savedAt: savedAt,
        context: effectiveContext,
      );
    }
    if (command is SubmitTurnCommand &&
        _rejectSubmitTurn(
          baseSnapshot: baseSnapshot,
          command: command,
          actorPlayerId: effectiveContext.actorPlayerId,
        )) {
      return LocalCommandResolution(
        snapshot: baseSnapshot.withSavedAt(savedAt).withGameState(currentState),
        state: currentState,
        events: const [],
        uiEffects: const [],
        context: effectiveContext,
      );
    }
    final transition = reducer.reduce(
      currentState,
      command,
      context: effectiveContext,
    );
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
      context: effectiveContext,
    );
  }

  LocalCommandResolution _resolveEngineUnitAction({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    if (!context.canAct ||
        (!context.hasActor && !currentState.activePlayerCanAct)) {
      return _unchangedEngineResolution(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        savedAt: savedAt,
        context: context,
      );
    }
    final actorPlayerId = _unitActionActorPlayerId(
      snapshot: baseSnapshot,
      state: currentState,
      command: command,
      context: context,
    );
    final result = _applyUnitActionEngine(
      snapshot: baseSnapshot,
      command: command,
      actorPlayerId: actorPlayerId,
      context: context,
    );
    return _engineUnitActionResolution(
      result: result,
      baseSnapshot: baseSnapshot,
      currentState: currentState,
      command: command,
      savedAt: savedAt,
      context: context,
    );
  }

  GameEngineResult _applyUnitActionEngine({
    required SaveSnapshot snapshot,
    required DomainCommand command,
    required String actorPlayerId,
    required GameCommandContext context,
  }) {
    return const GameEngine().apply(
      snapshot: snapshot.canonical,
      command: command,
      context: GameEngineContext(
        actorPlayerId: actorPlayerId,
        mapView: reducer.mapData,
        ruleset: reducer.ruleset,
        commandTick: context.commandTick,
      ),
    );
  }

  LocalCommandResolution _engineUnitActionResolution({
    required GameEngineResult result,
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
    required DomainCommand command,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    if (result is GameEngineRejected) {
      return _unchangedEngineResolution(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        savedAt: savedAt,
        context: context,
      );
    }
    if (identical(result.snapshot, baseSnapshot.canonical)) {
      return _unchangedEngineResolution(
        baseSnapshot: baseSnapshot,
        currentState: currentState,
        savedAt: savedAt,
        context: context,
      );
    }
    final snapshot = baseSnapshot.withUnitActionEngineProjection(
      units: result.snapshot.domain.units,
      artifacts: result.snapshot.domain.artifacts,
      interaction: result.snapshot.interaction,
      savedAt: savedAt,
    );
    final state = projectLocalUnitActionPresentation(
      reducer: reducer,
      currentState: currentState,
      baseSnapshot: baseSnapshot.canonical,
      resultSnapshot: result.snapshot,
      command: command,
    );
    return LocalCommandResolution(
      snapshot: snapshot,
      state: state,
      events: result.events,
      uiEffects: const [],
      context: context,
    );
  }

  LocalCommandResolution _unchangedEngineResolution({
    required SaveSnapshot baseSnapshot,
    required GameState currentState,
    required DateTime savedAt,
    required GameCommandContext context,
  }) {
    return LocalCommandResolution(
      snapshot: baseSnapshot.withUnitActionEngineProjection(
        units: baseSnapshot.units,
        artifacts: baseSnapshot.artifacts,
        interaction: baseSnapshot.interaction,
        savedAt: savedAt,
      ),
      state: currentState,
      events: const [],
      uiEffects: const [],
      context: context,
    );
  }

  String _unitActionActorPlayerId({
    required SaveSnapshot snapshot,
    required GameState state,
    required DomainCommand command,
    required GameCommandContext context,
  }) {
    final contextActor = context.actorPlayerId;
    if (contextActor != null && contextActor.isNotEmpty) return contextActor;
    if (state.activePlayerId.isNotEmpty) return state.activePlayerId;
    final unitId = switch (command) {
      SkipUnitTurnCommand(:final unitId) => unitId,
      FortifyUnitCommand(:final unitId) => unitId,
      _ => '',
    };
    return snapshot.domain.units.byId(unitId)?.ownerPlayerId ?? '';
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
