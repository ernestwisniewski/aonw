part of '../run_save_ai_benchmark.dart';

class _MultiTurnReplayRunner {
  const _MultiTurnReplayRunner({
    required this.snapshot,
    required this.savePath,
    required this.mapView,
    required this.cycles,
    required this.profiles,
    required this.includeDeadline,
    required this.strategyOverride,
  });

  final CanonicalGameSnapshot snapshot;
  final String savePath;
  final MapReadView mapView;
  final int cycles;
  final List<_ProfileSelection> profiles;
  final bool includeDeadline;
  final AiStrategyId? strategyOverride;

  _MultiTurnReplayReport run() {
    final humanPlayerIds = {
      for (final player in snapshot.persistedPlayers)
        if (player.kind == PlayerKind.human) player.id,
    };
    final aiPlayers = [
      for (final player in snapshot.persistedPlayers)
        if (player.kind == PlayerKind.ai && player.ai != null) player,
    ];
    final profile = profiles.firstWhere(
      (profile) => profile.name == 'auto',
      orElse: () => profiles.first,
    );
    // Build state before changing replay turn metadata.
    // Sparse snapshots can derive fallback state participants.
    // That state remains part of the replay aggregate.
    // The reset below applies only to persisted roster turn states.
    var state = _prepareReplayCycleState(
      snapshot.toClientState(activePlayerId: '', activePlayerCanAct: true),
      snapshot: snapshot,
      humanPlayerIds: humanPlayerIds,
    );
    var replaySnapshot = snapshot.withReplayPlayerTurnsReset();
    final startHumanCities = _cityCountOwnedBy(state.cities, humanPlayerIds);
    final cycleReports = <_MultiTurnCycleReport>[];

    for (var cycle = 1; cycle <= cycles; cycle++) {
      state = _prepareReplayCycleState(
        state,
        snapshot: replaySnapshot,
        humanPlayerIds: humanPlayerIds,
      );
      final cycleStartTurn = replaySnapshot.domain.turn;
      final cycleStartHumanCities = _cityCountOwnedBy(
        state.cities,
        humanPlayerIds,
      );
      final playerTurns = <_MultiTurnPlayerReport>[];

      for (final player in aiPlayers) {
        final turnSnapshot = replaySnapshot.withClientState(state);
        final prepared = _PreparedPlayer.fromSnapshot(
          snapshot: turnSnapshot,
          player: player,
          humanPlayerIds: humanPlayerIds,
          mapView: mapView,
          includeDeadline: includeDeadline,
        );
        final strategyId = strategyOverride ?? player.ai!.strategyId;
        final strategy = prepared._strategyFor(strategyId, profile);
        final planningStopwatch = Stopwatch()..start();
        final plan = strategy.plan(prepared.view, prepared.context);
        planningStopwatch.stop();

        final replay = _executeReplayTurn(
          snapshot: replaySnapshot,
          state: state,
          player: player,
          view: prepared.view,
          context: prepared.context,
          plan: plan,
          humanPlayerIds: humanPlayerIds,
        );
        replaySnapshot = replay.snapshot;
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
          endTurn: replaySnapshot.domain.turn,
          humanCitiesStart: cycleStartHumanCities,
          humanCitiesEnd: _cityCountOwnedBy(state.cities, humanPlayerIds),
          playerTurns: playerTurns,
        ),
      );
    }

    return _MultiTurnReplayReport(
      savePath: savePath,
      startTurn: snapshot.domain.turn,
      endTurn: replaySnapshot.domain.turn,
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
    required CanonicalGameSnapshot snapshot,
    required GameClientState state,
    required Player player,
    required GameView view,
    required AiContext context,
    required AiTurnPlan plan,
    required Set<String> humanPlayerIds,
  }) {
    final dispatcher = BenchmarkCommandDispatcher(
      snapshot: snapshot,
      mapView: context.mapData,
      ruleset: context.ruleset,
    );
    var currentSnapshot = snapshot;
    var currentState = state;
    final eventCounts = _ExecutionEventCounts();
    var applied = 0;
    var rejected = 0;
    var stale = 0;
    var skippedTerminal = 0;
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
          players: currentSnapshot.persistedPlayers,
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
      final transition = dispatcher.apply(
        state: currentState,
        command: command,
        context: commandContext,
      );
      eventCounts.addEvents(transition.events);
      if (!transition.accepted) {
        if (command is MoveUnitCommand && transition.rejectionReasons.isEmpty) {
          final staleDiagnostic = _staleMoveDiagnostic(
            command,
            currentState,
            planningView: view,
            player: player,
            players: currentSnapshot.persistedPlayers,
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
              context.mapData,
              commandContext,
            ),
          );
        }
        continue;
      }
      currentState = transition.state;
      applied += 1;
    }
    final terminalCommand = _replayTerminalCommand(currentSnapshot, player);
    final terminalTransition = dispatcher.apply(
      state: currentState,
      command: terminalCommand,
      context: _commandContext(playerId: player.id, aiContext: context),
    );
    eventCounts.addEvents(terminalTransition.events);
    final terminalChangedState = terminalTransition.state != currentState;
    currentState = terminalTransition.state;
    final savedAt = _replaySavedAt(currentSnapshot);

    currentSnapshot = dispatcher.snapshot.copyWith(
      metadata: dispatcher.snapshot.metadata.copyWith(savedAtUtc: savedAt),
    );

    executionStopwatch.stop();
    return _ReplayTurnResult(
      snapshot: currentSnapshot,
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
}

GameClientState _prepareReplayCycleState(
  GameClientState state, {
  required CanonicalGameSnapshot snapshot,
  required Set<String> humanPlayerIds,
}) {
  if (snapshot.domain.gameMode != GameMode.multiplayer) return state;
  return state
      .copyWith(
        activePlayerId: '',
        activePlayerCanAct: true,
        submittedPlayerIds: {
          for (final playerId in humanPlayerIds)
            if (playerId.isNotEmpty) playerId,
        },
      )
      .copyWithInteraction(
        moveCommandActive: false,
        movePreview: null,
        cityFoundingDraft: null,
        pendingAction: null,
      );
}

DateTime _syntheticReplaySavedAt(DateTime savedAt, {required int cycles}) =>
    savedAt.toUtc().add(Duration(seconds: cycles));

DateTime _replaySavedAt(CanonicalGameSnapshot snapshot) =>
    _syntheticReplaySavedAt(snapshot.metadata.savedAtUtc, cycles: 1);

DomainCommand _replayTerminalCommand(
  CanonicalGameSnapshot snapshot,
  Player player,
) => _terminalFor(snapshot.domain.gameMode, player.id);
