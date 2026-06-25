part of '../run_save_ai_benchmark.dart';

class _BenchmarkRuntimeReport {
  const _BenchmarkRuntimeReport({
    required this.shouldRunLocalAi,
    required this.localSinglePlayer,
    required this.throttle,
    required this.turn,
    required this.totalUnitCount,
    required this.totalCityCount,
    required this.findings,
  });

  final bool shouldRunLocalAi;
  final bool localSinglePlayer;
  final AiRuntimeThrottleSnapshot throttle;
  final int turn;
  final int totalUnitCount;
  final int totalCityCount;
  final List<_Finding> findings;

  factory _BenchmarkRuntimeReport.fromSnapshot(SaveSnapshot snapshot) {
    final save = snapshot.save;
    final shouldRunLocalAi = shouldRunLocalAiForMode(
      gameMode: save.gameMode,
      saveId: save.id,
      networkSession: null,
    );
    final localSinglePlayer = isLocalSinglePlayerAiRuntime(
      save: save,
      networkSession: null,
    );
    final throttle = AiRuntimeThrottler().snapshotFor(
      localSinglePlayer: localSinglePlayer,
      turn: save.turn,
      totalUnitCount: snapshot.units.length,
      totalCityCount: snapshot.cities.length,
    );
    final findings = <_Finding>[];
    final lateGameThresholdReached =
        save.turn >= AiRuntimeThrottler.adaptiveLateGameTurnThreshold ||
        snapshot.units.length >=
            AiRuntimeThrottler.adaptiveLateGameUnitThreshold ||
        snapshot.cities.length >=
            AiRuntimeThrottler.adaptiveLateGameCityThreshold;
    if (localSinglePlayer &&
        lateGameThresholdReached &&
        throttle.mctsRuntimeProfile != MctsRuntimeProfile.batterySaver) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message:
              'Local single-player late-game runtime should use batterySaver MCTS.',
        ),
      );
    }
    return _BenchmarkRuntimeReport(
      shouldRunLocalAi: shouldRunLocalAi,
      localSinglePlayer: localSinglePlayer,
      throttle: throttle,
      turn: save.turn,
      totalUnitCount: snapshot.units.length,
      totalCityCount: snapshot.cities.length,
      findings: findings,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'shouldRunLocalAi': shouldRunLocalAi,
      'localSinglePlayer': localSinglePlayer,
      'turn': turn,
      'totalUnitCount': totalUnitCount,
      'totalCityCount': totalCityCount,
      'pressureLevel': throttle.pressureLevel,
      'precomputeDebounceMs':
          throttle.precomputeDebounceDuration.inMilliseconds,
      'precomputeMinimumStartIntervalMs':
          throttle.precomputeMinimumStartInterval.inMilliseconds,
      'mctsRuntimeProfile': throttle.mctsRuntimeProfile.name,
      'adaptiveLateGame': throttle.adaptiveLateGame,
      'thresholds': {
        'turn': AiRuntimeThrottler.adaptiveLateGameTurnThreshold,
        'units': AiRuntimeThrottler.adaptiveLateGameUnitThreshold,
        'cities': AiRuntimeThrottler.adaptiveLateGameCityThreshold,
      },
      'findings': [for (final finding in findings) finding.toJson()],
    };
  }
}

class _BenchmarkReport {
  const _BenchmarkReport({
    required this.savePath,
    required this.snapshot,
    required this.mapData,
    required this.runtime,
    required this.playerResults,
    required this.repeats,
    required this.profiles,
    required this.includeDeadline,
    required this.strategyOverride,
    required this.multiTurnReplay,
    required this.syntheticScenarios,
    required this.runtimeSmoke,
  });

  final String savePath;
  final SaveSnapshot snapshot;
  final MapData mapData;
  final _BenchmarkRuntimeReport runtime;
  final List<_PlayerBenchmarkResult> playerResults;
  final int repeats;
  final List<_ProfileSelection> profiles;
  final bool includeDeadline;
  final AiStrategyId? strategyOverride;
  final _MultiTurnReplayReport? multiTurnReplay;
  final List<_SyntheticScenarioReport> syntheticScenarios;
  final _RuntimeUseCaseSmokeReport runtimeSmoke;

  bool get hasFailingFindings {
    return runtime.findings.any((finding) => finding.severity == 'fail') ||
        runtimeSmoke.findings.any((finding) => finding.severity == 'fail') ||
        playerResults.any(
          (player) =>
              player.findings.any((finding) => finding.severity == 'fail'),
        ) ||
        (multiTurnReplay?.findings.any(
              (finding) => finding.severity == 'fail',
            ) ??
            false) ||
        syntheticScenarios.any((scenario) => scenario.hasFailingFindings);
  }

  Map<String, Object?> toJson() {
    return {
      'save': {
        'path': savePath,
        'id': snapshot.save.id,
        'name': snapshot.save.name,
        'turn': snapshot.save.turn,
        'savedAt': snapshot.save.savedAt.toUtc().toIso8601String(),
        'mapName': snapshot.save.mapName,
        'gameMode': snapshot.save.gameMode.name,
      },
      'runtime': runtime.toJson(),
      'parameters': {
        'repeats': repeats,
        'profiles': [for (final profile in profiles) profile.name],
        'includeDeadline': includeDeadline,
        'strategyOverride': strategyOverride?.name,
        'assumedInterCommandDelayMs': _singlePlayerDelay.inMilliseconds,
      },
      'counts': {
        'players': snapshot.save.players.length,
        'units': snapshot.units.length,
        'cities': snapshot.cities.length,
        'fieldImprovements': snapshot.fieldImprovements.length,
        'mapTiles': mapData.tiles.length,
      },
      'players': [for (final result in playerResults) result.toJson()],
      if (multiTurnReplay != null) 'multiTurnReplay': multiTurnReplay!.toJson(),
      'syntheticScenarios': [
        for (final scenario in syntheticScenarios) scenario.toJson(),
      ],
      'runtimeUseCaseSmoke': runtimeSmoke.toJson(),
    };
  }

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# Save AI benchmark')
      ..writeln()
      ..writeln('- Save: `${snapshot.save.name}` (`${snapshot.save.id}`)')
      ..writeln('- Path: `$savePath`')
      ..writeln('- Turn: ${snapshot.save.turn}')
      ..writeln(
        '- Saved at: ${snapshot.save.savedAt.toUtc().toIso8601String()}',
      )
      ..writeln(
        '- Map: ${snapshot.save.mapName} (${mapData.cols}x${mapData.rows})',
      )
      ..writeln(
        '- Scope: ${snapshot.units.length} units, ${snapshot.cities.length} cities, '
        '${snapshot.fieldImprovements.length} improvements',
      )
      ..writeln('- Repeats: $repeats')
      ..writeln('- Deadline emulation: ${includeDeadline ? 'on' : 'off'}')
      ..writeln(
        '- Runtime mode: local AI ${runtime.shouldRunLocalAi ? 'yes' : 'no'}, '
        'local single-player ${runtime.localSinglePlayer ? 'yes' : 'no'}, '
        'MCTS `${runtime.throttle.mctsRuntimeProfile.name}`, '
        'adaptive late-game ${runtime.throttle.adaptiveLateGame ? 'yes' : 'no'}',
      )
      ..writeln();

    _writeFindings(buffer, runtime.findings);

    for (final result in playerResults) {
      buffer
        ..writeln('## ${result.player.name} (${result.player.id})')
        ..writeln()
        ..writeln(
          '- AI: ${result.ai.strategyId.name}, '
          '${result.ai.difficulty.name}, persona ${result.ai.persona.name}',
        )
        ..writeln('- Benchmark strategy: ${result.effectiveStrategyId.name}')
        ..writeln(
          '- Empire: ${result.view.ownCities.length} cities, '
          '${result.view.ownUnits.length} units, '
          '${result.militaryCount} military, gold ${result.view.ownGold}',
        )
        ..writeln(
          '- Strategic mode: ${result.strategicPlan.mode.name}; '
          'war goals: ${result.strategicPlan.warGoals.length}; '
          'rivals: ${result.strategicPlan.rivalRanking.length}',
        )
        ..writeln(
          '- Targetable human cities/units: '
          '${result.targetableHumanCityCount}/'
          '${result.targetableHumanUnitCount}; '
          'immediate attacks: ${result.immediateHumanAttackCount}; '
          'nearest human distance: ${result.nearestHumanDistance ?? 'n/a'}',
        )
        ..writeln('- Diplomacy vs humans: ${result.humanDiplomacySummary}')
        ..writeln();

      if (result.strategicPlan.warGoals.isNotEmpty) {
        buffer.writeln('War goals:');
        for (final goal in result.strategicPlan.warGoals) {
          buffer.writeln(
            '- ${goal.kind.name} -> ${goal.targetPlayerId} at '
            '${_hexLabel(goal.targetHex)}, units ${goal.assignedUnitIds.length}, '
            'priority ${goal.priority.toStringAsFixed(2)}',
          );
        }
        buffer.writeln();
      }

      for (final run in result.profileRuns) {
        final commandStats = run.commandStats;
        final execution = run.execution;
        final plannedDelay =
            commandStats.estimatedVisibleDelayCommands *
            _singlePlayerDelay.inMilliseconds;
        buffer
          ..writeln('Profile `${run.profile.name}`:')
          ..writeln(
            '- Planning avg ${run.average.inMilliseconds}ms, '
            'min ${run.min.inMilliseconds}ms, '
            'max ${run.max.inMilliseconds}ms',
          )
          ..writeln(
            '- Commands: ${commandStats.total} total, '
            '${commandStats.attacks} attacks, ${commandStats.attackHumans} human attacks, '
            '${commandStats.attackPressureTargets} pressure attacks, '
            '${commandStats.moves} moves, '
            '${commandStats.movesTowardHumans} moves toward humans, '
            '${commandStats.movesTowardWarGoals} toward war goals',
          )
          ..writeln(
            '- Estimated visible execution delay: ${plannedDelay}ms '
            'at ${_singlePlayerDelay.inMilliseconds}ms/visible command',
          )
          ..writeln(
            '- Reducer execution sim: ${execution.dispatchedCommands.length} applied, '
            '${execution.rejectedCommands.length} rejected, '
            '${execution.skippedStaleCommands.length} stale, '
            'terminal ${execution.terminalChangedState ? 'changed' : 'unchanged'} '
            'in ${execution.terminalDuration.inMilliseconds}ms, '
            'total ${execution.totalDuration.inMilliseconds}ms',
          )
          ..writeln(
            '- Applied combat/events: ${execution.appliedCommandStats.attacks} attacks, '
            '${execution.eventCounts.unitKills} unit kills, '
            '${execution.eventCounts.cityCaptures} city captures, '
            '${execution.eventCounts.total} events',
          );
        if (execution.rejectedCommands.isNotEmpty) {
          buffer.writeln(
            '- Rejected commands: '
            '${execution.rejectedCommands.take(3).map(_describeCommand).join('; ')}',
          );
        }
        if (run.plan.commands.isNotEmpty) {
          buffer.writeln(
            '- Planned command sample: '
            '${run.plan.commands.take(4).map(_describeCommand).join('; ')}',
          );
        }
        final debug = run.plan.debug;
        if (debug != null && debug.metrics.isNotEmpty) {
          buffer.writeln('- Debug metrics: ${_formatMetrics(debug.metrics)}');
        }
        if (debug != null && debug.notes.isNotEmpty) {
          buffer.writeln('- Notes: ${debug.notes.take(5).join('; ')}');
        }
        buffer.writeln();
      }

      if (result.findings.isNotEmpty) {
        buffer.writeln('Findings:');
        for (final finding in result.findings) {
          buffer.writeln('- [${finding.severity}] ${finding.message}');
        }
        buffer.writeln();
      }
    }

    if (syntheticScenarios.isNotEmpty) {
      buffer
        ..writeln('## Synthetic scenario guards')
        ..writeln();
      for (final scenario in syntheticScenarios) {
        buffer
          ..writeln('### ${scenario.name}')
          ..writeln()
          ..writeln('- ID: `${scenario.id}`')
          ..writeln('- ${scenario.description}');
        for (final detail in scenario.markdownDetails) {
          buffer.writeln('- $detail');
        }
        if (scenario.findings.isEmpty) {
          buffer.writeln('- Findings: none');
        } else {
          buffer.writeln('Findings:');
          for (final finding in scenario.findings) {
            buffer.writeln('- [${finding.severity}] ${finding.message}');
          }
        }
        buffer.writeln();
      }
    }

    buffer
      ..writeln('## Runtime use-case smoke')
      ..writeln()
      ..writeln(
        '- Player-turns: ${runtimeSmoke.players.length}; planning '
        '${runtimeSmoke.totalPlanning.inMilliseconds}ms total; execution '
        '${runtimeSmoke.totalExecution.inMilliseconds}ms total',
      )
      ..writeln(
        '- Estimated visible AI cycle: '
        '${runtimeSmoke.totalEstimatedVisible.inMilliseconds}ms at '
        '${_singlePlayerDelay.inMilliseconds}ms/visible command',
      )
      ..writeln(
        '- Commands: ${runtimeSmoke.totalPlannedCommands} planned, '
        '${runtimeSmoke.totalDispatchedCommands} dispatched, '
        '${runtimeSmoke.totalHumanAttacks} human attacks, '
        '${runtimeSmoke.totalPressureTargetAttacks} pressure-target attacks, '
        '${runtimeSmoke.totalSubmittedAfterTerminal}/'
        '${runtimeSmoke.totalTerminalSubmitCommands} terminal submits persisted, '
        '${runtimeSmoke.totalRejectedCommands} rejected, '
        '${runtimeSmoke.totalStaleCommands} stale',
      );
    if (runtimeSmoke.findings.isEmpty) {
      buffer.writeln('- Findings: none');
    } else {
      buffer.writeln('Runtime smoke findings:');
      for (final finding in runtimeSmoke.findings) {
        buffer.writeln('- [${finding.severity}] ${finding.message}');
      }
    }
    for (final player in runtimeSmoke.players) {
      buffer.writeln(
        '- ${player.player.id}: '
        '${player.report.planningDuration.inMilliseconds}ms plan, '
        '${player.estimatedVisibleDuration.inMilliseconds}ms estimated visible, '
        '${player.report.plannedCommands.length} planned, '
        '${player.report.dispatchedCommands.length} dispatched, '
        '${player.commandStats.attackHumans} human attacks, '
        'submitted ${_formatNullableBool(player.submittedAfterTerminal)}, '
        '${player.report.rejectedCommands.length} rejected, '
        '${player.report.skippedStaleCommands.length} stale',
      );
    }
    buffer.writeln();

    final replay = multiTurnReplay;
    if (replay != null) {
      buffer
        ..writeln('## Multi-turn replay')
        ..writeln()
        ..writeln(
          '- Cycles: ${replay.cycles.length}; turns ${replay.startTurn} -> ${replay.endTurn}',
        )
        ..writeln(
          '- Planning avg ${replay.averagePlanning.inMilliseconds}ms, '
          'p90 ${replay.p90Planning.inMilliseconds}ms, '
          'p95 ${replay.p95Planning.inMilliseconds}ms, '
          'max ${replay.maxPlanning.inMilliseconds}ms',
        )
        ..writeln(
          '- Execution avg ${replay.averageExecution.inMilliseconds}ms, '
          'p95 ${replay.p95Execution.inMilliseconds}ms, '
          'max ${replay.maxExecution.inMilliseconds}ms; '
          'compute avg ${replay.averageCompute.inMilliseconds}ms, '
          'p95 ${replay.p95Compute.inMilliseconds}ms',
        )
        ..writeln(
          '- Estimated visible wait: '
          '${replay.averageEstimatedVisibleTurn.inMilliseconds}ms/player-turn avg, '
          '${replay.p95EstimatedVisibleTurn.inMilliseconds}ms p95, '
          '${replay.maxEstimatedVisibleTurn.inMilliseconds}ms max; '
          '${replay.averageEstimatedVisibleCycle.inMilliseconds}ms/cycle avg '
          'at ${_singlePlayerDelay.inMilliseconds}ms/visible command',
        )
        ..writeln(
          '- Visible command pacing: '
          '${replay.totalEstimatedVisibleDelayCommands} delayed command(s), '
          'p95 ${replay.p95EstimatedVisibleDelayCommands}/turn, '
          'max ${replay.maxEstimatedVisibleDelayCommands}/turn',
        )
        ..writeln(
          '- Commands: ${replay.totalCommands} planned, '
          '${replay.totalHumanAttacks} human attacks, '
          '${replay.totalPressureTargetAttacks} pressure-target attacks, '
          '${replay.totalRejected} rejected, ${replay.totalStale} stale',
        )
        ..writeln(
          '- Attack target owners: ${_formatIntMap(replay.attackTargetOwners)}',
        )
        ..writeln(
          '- Non-human attack reasons: '
          '${_formatIntMap(replay.nonHumanAttackReasons)}',
        )
        ..writeln(
          '- Human cities: ${replay.startHumanCities} -> ${replay.endHumanCities}; '
          'AI captures: ${replay.totalCityCaptures}',
        )
        ..writeln(
          '- Soft passivity: ${replay.totalMissingWarGoalTurns} missing war-goal turns, '
          '${replay.totalPassiveWarPressureTurns} passive pressure turns, '
          'longest streaks ${_formatIntMap(replay.longestPassiveWarPressureStreakByPlayer)}',
        )
        ..writeln(
          '- Human pressure idle: ${replay.totalPressureTargetIdleTurns} turns, '
          '${replay.totalPressureTargetSiegeTurns} siege/contact turns, '
          'longest no-contact streaks ${_formatIntMap(replay.longestPressureTargetIdleStreakByPlayer)}',
        )
        ..writeln();

      if (replay.endHumanCityStates.isNotEmpty) {
        buffer.writeln('Remaining human city states:');
        for (final cityState in replay.endHumanCityStates) {
          buffer.writeln('- ${cityState.toMarkdown()}');
        }
        buffer.writeln();
      }

      for (final cycle in replay.cycles) {
        buffer.writeln(
          'Cycle ${cycle.index}: turn ${cycle.startTurn} -> ${cycle.endTurn}, '
          'human cities ${cycle.humanCitiesStart} -> ${cycle.humanCitiesEnd}, '
          '${cycle.estimatedVisibleDuration.inMilliseconds}ms estimated visible',
        );
        for (final turn in cycle.playerTurns) {
          final stats = turn.commandStats;
          buffer.writeln(
            '- ${turn.playerId}: ${turn.planningDuration.inMilliseconds}ms plan, '
            '${turn.executionDuration.inMilliseconds}ms replay, '
            '${turn.estimatedVisibleDuration.inMilliseconds}ms estimated visible, '
            '${stats.total} commands, ${stats.attackHumans} human attacks, '
            '${stats.attackPressureTargets} pressure attacks, '
            'mode ${turn.strategicMode}, goals ${turn.warGoals.length}, '
            'military ${turn.militaryCount}, targets '
            '${turn.targetableHumanCityCount}/${turn.targetableHumanUnitCount}, '
            '${turn.applied} applied, ${turn.rejected} rejected, '
            '${turn.stale} stale',
          );
          if (stats.attackTargetOwners.isNotEmpty) {
            buffer.writeln(
              '  Attack owners: ${_formatIntMap(stats.attackTargetOwners)}',
            );
          }
          if (turn.staleMoveDiagnostics.isNotEmpty) {
            buffer.writeln(
              '  Stale move sample: '
              '${turn.staleMoveDiagnostics.take(2).map((diagnostic) => diagnostic.toMarkdown()).join('; ')}',
            );
          }
          if (turn.rejectedCommandSample.isNotEmpty) {
            buffer.writeln(
              '  Rejected command sample: '
              '${turn.rejectedCommandSample.take(2).join('; ')}',
            );
          }
        }
        buffer.writeln();
      }

      if (replay.findings.isNotEmpty) {
        buffer.writeln('Multi-turn findings:');
        for (final finding in replay.findings) {
          buffer.writeln('- [${finding.severity}] ${finding.message}');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
