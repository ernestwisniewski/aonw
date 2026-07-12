import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_conversions.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/turn.dart';
import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';

class LocalCommandResolution {
  final GameSave save;
  final GameState state;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;
  final GameCommandContext context;

  const LocalCommandResolution({
    required this.save,
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
      combatSeedTurn: baseSnapshot.save.turn,
      paceBalance: baseSnapshot.save.matchRules.paceBalance,
      victoryRules: baseSnapshot.save.matchRules.victory,
    );
    if (command is SubmitTurnCommand &&
        _rejectSubmitTurn(
          baseSnapshot: baseSnapshot,
          command: command,
          actorPlayerId: effectiveContext.actorPlayerId,
        )) {
      return LocalCommandResolution(
        save: baseSnapshot.save.copyWith(savedAt: savedAt.toUtc()),
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
      save: resolved.save,
      state: resolved.state,
      events: [...transition.events, ...resolved.events],
      uiEffects: [...transition.uiEffects, ...resolved.uiEffects],
      context: effectiveContext,
    );
  }

  GameSave _saveForCommand(
    GameSave save,
    GameCommand command,
    DateTime savedAt,
  ) {
    if (command is EndTurnCommand) {
      return const AdvanceTurnPhase().advanceSave(
        save,
        playerId: command.playerId,
        savedAt: savedAt,
      );
    }
    return save.copyWith(savedAt: savedAt);
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

    return _ResolvedLocalCommand(
      save: _saveForCommand(baseSnapshot.save, command, savedAt),
      state: reducedState,
    );
  }

  _ResolvedLocalCommand _resolveSubmitTurn({
    required SaveSnapshot baseSnapshot,
    required SubmitTurnCommand command,
    required GameState reducedState,
    required DateTime savedAt,
  }) {
    final save = baseSnapshot.save;
    final playerIds = _activePlayerIds(save);
    if (!playerIds.every(reducedState.submittedPlayerIds.contains)) {
      return _ResolvedLocalCommand(
        save: save
            .withPlayerFinished(command.playerId)
            .copyWith(savedAt: savedAt.toUtc()),
        state: reducedState,
      );
    }

    return _finalizeSimultaneousTurn(
      save: save,
      state: reducedState,
      playerIds: playerIds,
      savedAt: savedAt.toUtc(),
    );
  }

  _ResolvedLocalCommand _finalizeSimultaneousTurn({
    required GameSave save,
    required GameState state,
    required List<String> playerIds,
    required DateTime savedAt,
  }) {
    final result = PersistentTurnPipeline.simultaneousFinalize(
      PersistentTurnPipelineRequest.simultaneousFinalize(
        save: save,
        state: state.toPersistentState(),
        playerIds: playerIds,
        savedAt: savedAt,
        mapData: reducer.mapData,
        mapDefinition: _mapDefinition(),
        ruleset: reducer.ruleset,
      ),
    );
    final movementDelta = result.movementDelta;
    final uiEffects = movementDelta == null
        ? const <UiEffect>[]
        : QueuedMovementEffectBuilder.fromUnitDelta(
            beforeUnits: movementDelta.beforeUnits,
            afterUnits: movementDelta.afterUnits,
          );
    final nextState =
        SaveSnapshot.fromPersistentState(
          save: result.save,
          state: result.state,
        ).toGameState(
          activePlayerId: state.activePlayerId,
          activePlayerCanAct: state.activePlayerCanAct,
        );

    return _ResolvedLocalCommand(
      save: result.save,
      state: nextState,
      events: result.events,
      uiEffects: uiEffects,
    );
  }

  List<String> _activePlayerIds(GameSave save) {
    final ids = save.players
        .map((player) => player.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isNotEmpty) return ids..sort();

    return save.playerStates.keys.where((id) => id.isNotEmpty).toList()..sort();
  }

  bool _rejectSubmitTurn({
    required SaveSnapshot baseSnapshot,
    required SubmitTurnCommand command,
    required String? actorPlayerId,
  }) {
    return (actorPlayerId != null &&
            actorPlayerId.isNotEmpty &&
            actorPlayerId != command.playerId) ||
        !_activePlayerIds(baseSnapshot.save).contains(command.playerId) ||
        baseSnapshot.runtimeState.hasSubmitted(command.playerId);
  }

  MapDefinition _mapDefinition() {
    final mapData = reducer.mapData;
    return MapDefinition(
      cols: mapData.cols,
      rows: mapData.rows,
      mapName: mapData.mapName,
      defaultZoom: mapData.defaultZoom,
      tiles: [
        for (final tile in mapData.tiles)
          MapTileDefinition(
            col: tile.col,
            row: tile.row,
            terrains: tile.terrains,
            resources: tile.resources,
            height: tile.height,
          ),
      ],
    );
  }
}

class _ResolvedLocalCommand {
  final GameSave save;
  final GameState state;
  final List<GameEvent> events;
  final List<UiEffect> uiEffects;

  const _ResolvedLocalCommand({
    required this.save,
    required this.state,
    this.events = const [],
    this.uiEffects = const [],
  });
}
