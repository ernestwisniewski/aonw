part of 'server_command_reducer.dart';

extension ServerCommandReducerTurns on ServerCommandReducer {
  _CommandApplication _submitTurn({
    required GameSave save,
    required PersistentGameState state,
    required WireMatch match,
    required SubmitTurnCommand command,
    required String actorPlayerId,
    required DateTime now,
    required MapData mapData,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    if (command.playerId != actorPlayerId) {
      return _CommandApplication.reject(
        save: save,
        state: state,
        reason: 'turn_player_not_controlled',
      );
    }
    final playerIds = _turnPlayerIds(save, state);
    if (playerIds.isEmpty || !playerIds.contains(command.playerId)) {
      return _CommandApplication.reject(
        save: save,
        state: state,
        reason: 'turn_player_not_active',
      );
    }
    final alreadySubmitted = state.runtimeState.hasSubmitted(command.playerId);
    final submitted = {
      ...state.runtimeState.submittedPlayerIds,
      command.playerId,
    };
    final submittedState = state.copyWith(
      runtimeState: state.runtimeState.copyWith(submittedPlayerIds: submitted),
    );
    final turnTimedOut = _turnTimedOut(save, state, now);
    final waitingPlayerIds = _waitingPlayerIds(
      match: match,
      playerIds: playerIds,
      submittedPlayerIds: submitted,
      turnTimedOut: turnTimedOut,
    );
    if (waitingPlayerIds.isNotEmpty) {
      return _CommandApplication.accept(
        save: alreadySubmitted
            ? save.copyWith(savedAt: now.toUtc())
            : save
                  .withPlayerFinished(command.playerId)
                  .copyWith(savedAt: now.toUtc()),
        state: submittedState,
      );
    }
    final skippedPlayerIds = playerIds
        .where((playerId) => !submitted.contains(playerId))
        .toList();

    return _finalizeSimultaneousTurn(
      save: save,
      state: submittedState,
      playerIds: playerIds,
      skippedPlayerIds: skippedPlayerIds,
      now: now,
      mapData: mapData,
      mapDefinition: mapDefinition,
      ruleset: ruleset,
    );
  }

  _CommandApplication _finalizeSimultaneousTurn({
    required GameSave save,
    required PersistentGameState state,
    required List<String> playerIds,
    required List<String> skippedPlayerIds,
    required DateTime now,
    required MapData mapData,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    final combat = PersistentTurnCombatResolver.resolve(
      turn: save.turn,
      state: state,
      mapDefinition: mapDefinition,
      ruleset: ruleset,
    );
    final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: combat.state,
      playerIds: playerIds,
      mapData: mapData,
      ruleset: ruleset,
      priorEvents: combat.events,
      mapObjectives: mapData.objectives,
      turn: save.turn,
    );
    final artifactProgress = PersistentArtifactTurnProcessor.advanceForPlayers(
      state: economy.state,
      playerIds: playerIds,
    );
    final movement = PersistentTurnMovementProcessor.resetForPlayers(
      state: artifactProgress.state,
      playerIds: playerIds,
      mapData: mapData,
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
    const dominationProgressCalculator = DominationProgressCalculator();
    final previousDominationHoldTurns =
        movement.state.runtimeState.dominationHoldTurnsByPlayerId;
    final dominationHoldTurns = dominationProgressCalculator.advanceHoldTurns(
      playerIds: playerIds,
      state: movement.state,
      mapData: mapData,
      victoryRules: save.matchRules.victory,
      previousHoldTurnsByPlayerId: previousDominationHoldTurns,
    );
    final dominationEvents = dominationProgressCalculator
        .thresholdReachedEvents(
          playerIds: playerIds,
          state: movement.state,
          mapData: mapData,
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
    final timeoutStreaks = _timeoutStreaksAfterTurn(
      previous: movement.state.runtimeState.timeoutStreaksByPlayerId,
      playerIds: playerIds,
      skippedPlayerIds: skippedPlayerIds,
    );
    final runtimeState = movement.state.runtimeState.copyWith(
      submittedPlayerIds: const {},
      timeoutStreaksByPlayerId: timeoutStreaks,
      intendedAttacks: const [],
      diplomacy: diplomacy.diplomacy,
      dominationHoldTurnsByPlayerId: dominationHoldTurns,
      culturalVictoryHoldTurnsByPlayerId: culturalHoldTurns,
      turnStartedAt: now.toUtc(),
    );
    final nextSave = _saveWithNewTurnForPlayers(
      save,
      playerIds: playerIds,
      now: now,
    );
    final nextState = movement.state.copyWith(runtimeState: runtimeState);
    return _CommandApplication.accept(
      save: nextSave,
      state: nextState,
      events: [
        for (final playerId in skippedPlayerIds)
          PlayerTimedOutEvent(turn: save.turn, playerId: playerId),
        AllPlayersSubmittedEvent(turn: save.turn, playerIds: playerIds),
        ...combat.events,
        ...economy.events,
        ...diplomacy.events,
        ...dominationEvents,
        for (final playerId in playerIds) TurnEndedEvent(playerId: playerId),
      ],
    );
  }

  List<String> _turnPlayerIds(GameSave save, PersistentGameState state) {
    final kickedPlayerIds = state.runtimeState.kickedPlayerIds;
    final ids = save.players
        .map((player) => player.id)
        .where((id) => id.isNotEmpty && !kickedPlayerIds.contains(id))
        .toList();
    if (ids.isNotEmpty) return ids..sort();
    return save.playerStates.keys
        .where((id) => id.isNotEmpty && !kickedPlayerIds.contains(id))
        .toList()
      ..sort();
  }

  bool _turnTimedOut(GameSave save, PersistentGameState state, DateTime now) {
    final turnStartedAt = state.runtimeState.turnStartedAt ?? save.savedAt;
    final deadline = turnStartedAt.toUtc().add(_turnTimeout);
    return !now.toUtc().isBefore(deadline);
  }

  List<String> _waitingPlayerIds({
    required WireMatch match,
    required List<String> playerIds,
    required Set<String> submittedPlayerIds,
    required bool turnTimedOut,
  }) {
    if (turnTimedOut) return const [];
    final wirePlayersById = {
      for (final player in match.players) player.id: player,
    };
    return [
      for (final playerId in playerIds)
        if (!submittedPlayerIds.contains(playerId) &&
            _requiresTurnSubmission(wirePlayersById[playerId]))
          playerId,
    ];
  }

  bool _requiresTurnSubmission(WirePlayer? player) {
    if (player == null) return true;
    if (player.kind == WirePlayerKind.ai) return false;
    return switch (player.connectionState) {
      WirePlayerConnectionState.connected ||
      WirePlayerConnectionState.connecting ||
      WirePlayerConnectionState.reconnecting => true,
      WirePlayerConnectionState.offline => false,
    };
  }

  Map<String, int> _timeoutStreaksAfterTurn({
    required Map<String, int> previous,
    required List<String> playerIds,
    required List<String> skippedPlayerIds,
  }) {
    final skipped = skippedPlayerIds.toSet();
    return {
      for (final playerId in playerIds)
        if (skipped.contains(playerId)) playerId: (previous[playerId] ?? 0) + 1,
    };
  }

  GameSave _saveWithNewTurnForPlayers(
    GameSave save, {
    required List<String> playerIds,
    required DateTime now,
  }) {
    final activePlayerIds = playerIds.toSet();
    final playerStates = {
      for (final entry in save.playerStates.entries)
        entry.key: activePlayerIds.contains(entry.key)
            ? PlayerTurnState.active
            : PlayerTurnState.finished,
    };
    return save.copyWith(
      turn: save.turn + 1,
      playerStates: playerStates,
      savedAt: now.toUtc(),
    );
  }
}
