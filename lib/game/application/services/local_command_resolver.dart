import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/turn.dart';
import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/state.dart';

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
    );
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
    if (playerIds.isEmpty ||
        !playerIds.contains(command.playerId) ||
        baseSnapshot.runtimeState.hasSubmitted(command.playerId)) {
      return _ResolvedLocalCommand(
        save: save.copyWith(savedAt: savedAt.toUtc()),
        state: reducedState,
      );
    }

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
    final ruleset = reducer.ruleset.copyWith(
      paceBalance: save.matchRules.paceBalance,
    );
    final persistent = PersistentGameState(
      playerColors: state.playerColors,
      playerCountries: state.playerCountries,
      playerGold: state.playerGold,
      playerWarWeariness: state.playerWarWeariness,
      playerStabilityNet: state.playerStabilityNet,
      units: state.units,
      cities: state.cities,
      artifacts: state.artifacts,
      fieldImprovements: state.fieldImprovements,
      fogOfWar: state.fogOfWar,
      research: state.research,
      runtimeState: state.runtimeState,
    );
    final combat = PersistentTurnCombatResolver.resolve(
      turn: save.turn,
      state: persistent,
      mapDefinition: _mapDefinition(),
      ruleset: ruleset,
    );
    final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: combat.state,
      playerIds: playerIds,
      mapData: reducer.mapData,
      ruleset: ruleset,
      priorEvents: combat.events,
      mapObjectives: reducer.mapData.objectives,
    );
    final artifactProgress = PersistentArtifactTurnProcessor.advanceForPlayers(
      state: economy.state,
      playerIds: playerIds,
    );
    final movement = PersistentTurnMovementProcessor.resetForPlayers(
      state: artifactProgress.state,
      playerIds: playerIds,
      mapData: reducer.mapData,
    );
    final discoveredDiplomacy = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: movement.state.runtimeState.diplomacy,
      fogOfWar: movement.state.fogOfWar,
      units: movement.state.units,
      cities: movement.state.cities,
      playerIds: playerIds,
    );
    final diplomacy = DiplomacyTurnResolver.resolve(
      diplomacy: discoveredDiplomacy,
      turn: save.turn + 1,
      units: movement.state.units,
      cities: movement.state.cities,
    );
    final uiEffects = QueuedMovementEffectBuilder.fromUnitDelta(
      beforeUnits: economy.state.units,
      afterUnits: movement.state.units,
    );
    const dominationProgressCalculator = DominationProgressCalculator();
    final previousDominationHoldTurns =
        movement.state.runtimeState.dominationHoldTurnsByPlayerId;
    final dominationHoldTurns = dominationProgressCalculator.advanceHoldTurns(
      playerIds: playerIds,
      state: movement.state,
      mapData: reducer.mapData,
      victoryRules: save.matchRules.victory,
      previousHoldTurnsByPlayerId: previousDominationHoldTurns,
    );
    final dominationEvents = dominationProgressCalculator
        .thresholdReachedEvents(
          playerIds: playerIds,
          state: movement.state,
          mapData: reducer.mapData,
          victoryRules: save.matchRules.victory,
          previousHoldTurnsByPlayerId: previousDominationHoldTurns,
          nextHoldTurnsByPlayerId: dominationHoldTurns,
        );
    final previousCulturalHoldTurns =
        movement.state.runtimeState.culturalVictoryHoldTurnsByPlayerId;
    final culturalHoldTurns = save.matchRules.victory.culturalEnabled
        ? CulturalVictoryProgressCalculator.advanceHoldTurns(
            playerIds: playerIds,
            state: movement.state,
            previousHoldTurnsByPlayerId: previousCulturalHoldTurns,
            requiredArtifactCount:
                save.matchRules.victory.culturalRequiredArtifacts,
          )
        : previousCulturalHoldTurns;
    final runtimeState = movement.state.runtimeState.copyWith(
      submittedPlayerIds: const {},
      intendedAttacks: const [],
      diplomacy: diplomacy.diplomacy,
      dominationHoldTurnsByPlayerId: dominationHoldTurns,
      culturalVictoryHoldTurnsByPlayerId: culturalHoldTurns,
      turnStartedAt: savedAt,
    );
    final nextSave = save.withNewTurn().copyWith(savedAt: savedAt);
    final nextPersistent = movement.state.copyWith(runtimeState: runtimeState);
    final nextState =
        SaveSnapshot.fromPersistentState(
          save: nextSave,
          state: nextPersistent,
        ).toGameState(
          activePlayerId: state.activePlayerId,
          activePlayerCanAct: state.activePlayerCanAct,
        );

    return _ResolvedLocalCommand(
      save: nextSave,
      state: nextState,
      events: [
        AllPlayersSubmittedEvent(turn: save.turn, playerIds: playerIds),
        ...combat.events,
        ...economy.events,
        ...diplomacy.events,
        ...dominationEvents,
        for (final playerId in playerIds) TurnEndedEvent(playerId: playerId),
      ],
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
