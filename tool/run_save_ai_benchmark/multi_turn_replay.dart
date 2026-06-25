part of '../run_save_ai_benchmark.dart';

class _MultiTurnReplayRunner {
  const _MultiTurnReplayRunner({
    required this.snapshot,
    required this.savePath,
    required this.mapData,
    required this.cycles,
    required this.profiles,
    required this.includeDeadline,
    required this.strategyOverride,
  });

  final SaveSnapshot snapshot;
  final String savePath;
  final MapData mapData;
  final int cycles;
  final List<_ProfileSelection> profiles;
  final bool includeDeadline;
  final AiStrategyId? strategyOverride;

  _MultiTurnReplayReport run() {
    final humanPlayerIds = {
      for (final player in snapshot.save.players)
        if (player.kind == PlayerKind.human) player.id,
    };
    final aiPlayers = [
      for (final player in snapshot.save.players)
        if (player.kind == PlayerKind.ai && player.ai != null) player,
    ];
    final profile = profiles.firstWhere(
      (profile) => profile.name == 'auto',
      orElse: () => profiles.first,
    );
    var save = _resetPlayerTurns(snapshot.save);
    var state = _prepareCycleState(
      snapshot.toGameState(activePlayerId: '', activePlayerCanAct: true),
      save: save,
      humanPlayerIds: humanPlayerIds,
    );
    final startHumanCities = _cityCountOwnedBy(state.cities, humanPlayerIds);
    final cycleReports = <_MultiTurnCycleReport>[];

    for (var cycle = 1; cycle <= cycles; cycle++) {
      state = _prepareCycleState(
        state,
        save: save,
        humanPlayerIds: humanPlayerIds,
      );
      final cycleStartTurn = save.turn;
      final cycleStartHumanCities = _cityCountOwnedBy(
        state.cities,
        humanPlayerIds,
      );
      final playerTurns = <_MultiTurnPlayerReport>[];

      for (final player in aiPlayers) {
        final turnSnapshot = SaveSnapshot.fromGameState(
          save: save,
          state: state,
          eventLogOffset: snapshot.eventLogOffset,
        );
        final prepared = _PreparedPlayer.fromSnapshot(
          snapshot: turnSnapshot,
          player: player,
          humanPlayerIds: humanPlayerIds,
          mapData: mapData,
          includeDeadline: includeDeadline,
        );
        final strategyId = strategyOverride ?? player.ai!.strategyId;
        final strategy = prepared._strategyFor(strategyId, profile);
        final planningStopwatch = Stopwatch()..start();
        final plan = strategy.plan(prepared.view, prepared.context);
        planningStopwatch.stop();

        final replay = _executeReplayTurn(
          save: save,
          state: state,
          player: player,
          view: prepared.view,
          context: prepared.context,
          plan: plan,
          humanPlayerIds: humanPlayerIds,
        );
        save = replay.save;
        state = replay.state;
        playerTurns.add(
          _MultiTurnPlayerReport(
            playerId: player.id,
            playerName: player.name,
            strategicMode: prepared.strategicPlan.mode.name,
            warGoals: [
              for (final goal in prepared.strategicPlan.warGoals)
                _warGoalSummary(goal),
            ],
            strategicPlan: prepared.strategicPlan,
            defenseAssignedUnitCount: _defenseAssignedUnitIds(
              prepared.strategicPlan,
            ).length,
            defenseAssignmentCount: prepared.strategicPlan.defenses.length,
            frontierClearingAssignedUnitCount:
                prepared.strategicPlan.frontierClearingAssignments.length,
            planningDuration: planningStopwatch.elapsed,
            plan: plan,
            view: prepared.view,
            humanPlayerIds: humanPlayerIds,
            immediateHumanAttackTargets: _immediateHumanAttackTargets(
              prepared.view,
              prepared.context,
              humanPlayerIds,
            ),
            applied: replay.applied,
            rejected: replay.rejected,
            stale: replay.stale,
            skippedTerminal: replay.skippedTerminal,
            terminalChangedState: replay.terminalChangedState,
            executionDuration: replay.executionDuration,
            eventCounts: replay.eventCounts,
            staleMoveDiagnostics: replay.staleMoveDiagnostics,
            rejectedCommandSample: replay.rejectedCommandDescriptions,
            plannedCommandSample: [
              for (final command in plan.commands.take(6))
                _describeCommand(command),
            ],
          ),
        );
      }

      cycleReports.add(
        _MultiTurnCycleReport(
          index: cycle,
          startTurn: cycleStartTurn,
          endTurn: save.turn,
          humanCitiesStart: cycleStartHumanCities,
          humanCitiesEnd: _cityCountOwnedBy(state.cities, humanPlayerIds),
          playerTurns: playerTurns,
        ),
      );
    }

    return _MultiTurnReplayReport(
      savePath: savePath,
      startTurn: snapshot.save.turn,
      endTurn: save.turn,
      startHumanCities: startHumanCities,
      endHumanCities: _cityCountOwnedBy(state.cities, humanPlayerIds),
      endHumanCityStates: _humanCityEndStates(
        state,
        humanPlayerIds: humanPlayerIds,
      ),
      cycles: cycleReports,
    );
  }

  _ReplayTurnResult _executeReplayTurn({
    required GameSave save,
    required GameState state,
    required Player player,
    required GameView view,
    required AiContext context,
    required AiTurnPlan plan,
    required Set<String> humanPlayerIds,
  }) {
    final reducer = GameStateReducer(
      mapData: mapData,
      ruleset: context.ruleset,
    );
    var currentSave = save;
    var currentState = state;
    final eventCounts = _ExecutionEventCounts();
    var applied = 0;
    var rejected = 0;
    var stale = 0;
    var skippedTerminal = 0;
    var terminalChangedState = false;
    final staleMoveDiagnostics = <_StaleMoveDiagnostic>[];
    final rejectedCommandDescriptions = <String>[];
    final executionStopwatch = Stopwatch()..start();

    for (
      var commandIndex = 0;
      commandIndex < plan.commands.length;
      commandIndex++
    ) {
      final command = plan.commands[commandIndex];
      if (_isTerminal(command)) {
        skippedTerminal += 1;
        continue;
      }
      if (command is MoveUnitCommand &&
          _isUnitAlreadyAtTarget(command, currentState)) {
        final staleDiagnostic = _staleMoveDiagnostic(
          command,
          currentState,
          planningView: view,
          player: player,
          players: currentSave.players,
          humanPlayerIds: humanPlayerIds,
          commandIndex: commandIndex,
        );
        stale += 1;
        if (staleDiagnostic != null) {
          staleMoveDiagnostics.add(staleDiagnostic);
        }
        continue;
      }
      final commandContext = _commandContext(
        playerId: player.id,
        aiContext: context,
      );
      final transition = reducer.reduce(
        currentState,
        command,
        context: commandContext,
      );
      eventCounts.add(transition);
      if (transition.state == currentState) {
        if (command is MoveUnitCommand &&
            _rejectionReasons(transition).isEmpty) {
          final staleDiagnostic = _staleMoveDiagnostic(
            command,
            currentState,
            planningView: view,
            player: player,
            players: currentSave.players,
            humanPlayerIds: humanPlayerIds,
            commandIndex: commandIndex,
          );
          if (staleDiagnostic != null) {
            stale += 1;
            staleMoveDiagnostics.add(staleDiagnostic);
            continue;
          }
        }
        rejected += 1;
        if (rejectedCommandDescriptions.length < 12) {
          rejectedCommandDescriptions.add(
            _describeRejectedCommand(
              command,
              currentState,
              mapData,
              commandContext,
            ),
          );
        }
        continue;
      }
      currentState = transition.state;
      applied += 1;
    }

    final terminalCommand = _terminalFor(currentSave.gameMode, player.id);
    final terminalTransition = reducer.reduce(
      currentState,
      terminalCommand,
      context: _commandContext(playerId: player.id, aiContext: context),
    );
    eventCounts.add(terminalTransition);
    terminalChangedState = terminalTransition.state != currentState;
    currentState = terminalTransition.state;

    if (terminalCommand is SubmitTurnCommand) {
      final playerIds = _activePlayerIds(currentSave);
      if (playerIds.isNotEmpty &&
          playerIds.every(currentState.submittedPlayerIds.contains)) {
        final finalized = _finalizeSimultaneousTurn(
          save: currentSave,
          state: currentState,
          playerIds: playerIds,
          savedAt: _syntheticSavedAt(currentSave, cycles: 1),
        );
        currentSave = finalized.save;
        currentState = finalized.state;
        eventCounts.addEvents(finalized.events);
      }
    } else if (terminalCommand is EndTurnCommand) {
      currentSave = currentSave
          .withPlayerFinished(player.id)
          .copyWith(savedAt: _syntheticSavedAt(currentSave, cycles: 1));
    }

    executionStopwatch.stop();
    return _ReplayTurnResult(
      save: currentSave,
      state: currentState,
      applied: applied,
      rejected: rejected,
      stale: stale,
      skippedTerminal: skippedTerminal,
      terminalChangedState: terminalChangedState,
      executionDuration: executionStopwatch.elapsed,
      eventCounts: eventCounts.snapshot(),
      staleMoveDiagnostics: staleMoveDiagnostics,
      rejectedCommandDescriptions: rejectedCommandDescriptions,
    );
  }

  _ResolvedReplayTurn _finalizeSimultaneousTurn({
    required GameSave save,
    required GameState state,
    required List<String> playerIds,
    required DateTime savedAt,
  }) {
    final ruleset = GameRuleset.defaults.copyWith(
      paceBalance: save.matchRules.paceBalance,
    );
    final persistent = PersistentGameState(
      playerColors: state.playerColors,
      playerCountries: state.playerCountries,
      playerGold: state.playerGold,
      units: state.units,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      fogOfWar: state.fogOfWar,
      research: state.research,
      runtimeState: state.runtimeState,
    );
    final combat = PersistentTurnCombatResolver.resolve(
      turn: save.turn,
      state: persistent,
      mapDefinition: _mapDefinition(mapData),
      ruleset: ruleset,
    );
    final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: combat.state,
      playerIds: playerIds,
      mapData: mapData,
      ruleset: ruleset,
      mapObjectives: mapData.objectives,
    );
    final movement = PersistentTurnMovementProcessor.resetForPlayers(
      state: economy.state,
      playerIds: playerIds,
      mapData: mapData,
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
    final runtimeState = movement.state.runtimeState.copyWith(
      submittedPlayerIds: const {},
      intendedAttacks: const [],
      dominationHoldTurnsByPlayerId: dominationHoldTurns,
      turnStartedAt: savedAt,
    );
    final nextSave = save.withNewTurn().copyWith(savedAt: savedAt);
    final nextPersistent = movement.state.copyWith(runtimeState: runtimeState);
    final nextState = SaveSnapshot.fromPersistentState(
      save: nextSave,
      state: nextPersistent,
    ).toGameState(activePlayerId: '', activePlayerCanAct: true);

    return _ResolvedReplayTurn(
      save: nextSave,
      state: nextState,
      events: [
        AllPlayersSubmittedEvent(turn: save.turn, playerIds: playerIds),
        ...combat.events,
        ...economy.events,
        ...dominationEvents,
        for (final playerId in playerIds) TurnEndedEvent(playerId: playerId),
      ],
    );
  }
}
