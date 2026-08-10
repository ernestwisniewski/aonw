part of '../run_save_ai_benchmark.dart';

class _MultiTurnReplayReport {
  const _MultiTurnReplayReport({
    required this.savePath,
    required this.startTurn,
    required this.endTurn,
    required this.startHumanCities,
    required this.endHumanCities,
    required this.endHumanCityStates,
    required this.cycles,
  });

  final String savePath;
  final int startTurn;
  final int endTurn;
  final int startHumanCities;
  final int endHumanCities;
  final List<_HumanCityEndState> endHumanCityStates;
  final List<_MultiTurnCycleReport> cycles;

  List<_Finding> get findings {
    final findings = <_Finding>[];
    if (endTurn <= startTurn && cycles.isNotEmpty) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message: 'Multi-turn replay did not advance the game turn.',
        ),
      );
    }
    if (totalRejected > 0) {
      findings.add(
        _Finding(
          severity: 'fail',
          message: 'Multi-turn replay rejected $totalRejected AI command(s).',
        ),
      );
    }
    if (totalImmediateHumanAttacks > 0 && totalHumanAttacks == 0) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'AI had $totalImmediateHumanAttacks immediate human attack '
              'opportunities across replay but made no human attacks.',
        ),
      );
    }
    for (final turn in playerTurns) {
      if (turn.immediateHumanAttacks > 0 &&
          turn.commandStats.attackHumans == 0) {
        findings.add(
          _Finding(
            severity: 'fail',
            message:
                '${turn.playerId} had ${turn.immediateHumanAttacks} immediate '
                'human attack opportunity/opportunities on a replayed turn but '
                'planned no human attack.',
          ),
        );
      }
      if (!turn.terminalChangedState) {
        findings.add(
          _Finding(
            severity: 'fail',
            message: '${turn.playerId} terminal command was a no-op in replay.',
          ),
        );
      }
    }
    for (final entry in missingWarGoalTurnsByPlayer.entries) {
      final sample = _firstTurnMatching(
        entry.key,
        (turn) => turn.missingWarGoalWhileAtWar,
      );
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              '${entry.key} had ${entry.value} at-war replay turn(s) with '
              'military units and targetable human anchors but no war goal'
              '${sample == null ? '.' : ' (first: ${sample.toMarkdown()}).'}',
        ),
      );
    }
    for (final entry in longestPassiveWarPressureStreakByPlayer.entries) {
      if (entry.value < 6) continue;
      final totalTurns = passiveWarPressureTurnsByPlayer[entry.key] ?? 0;
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              '${entry.key} had a ${entry.value}-turn passive war-pressure '
              'streak and $totalTurns passive at-war turn(s) total.',
        ),
      );
    }
    for (final entry in longestPressureTargetIdleStreakByPlayer.entries) {
      if (entry.value < 8) continue;
      final totalTurns = pressureTargetIdleTurnsByPlayer[entry.key] ?? 0;
      final sample = _firstTurnMatching(
        entry.key,
        (turn) => turn.pressureTargetIdleTurn,
      );
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              '${entry.key} had a ${entry.value}-turn human pressure-target '
              'idle streak and $totalTurns idle at-war turn(s) total'
              '${sample == null ? '.' : ' (first: ${sample.toMarkdown()}).'}',
        ),
      );
    }
    if (totalDistractingNonHumanAttacks >= 5) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn replay had $totalDistractingNonHumanAttacks '
              'non-human attack(s) classified as distracting from human '
              'pressure: ${_formatIntMap(distractingNonHumanAttacksByPlayer)}.',
        ),
      );
    }
    if (averagePlanning > const Duration(milliseconds: 650)) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn average planning time ${averagePlanning.inMilliseconds}ms '
              'exceeds 650ms.',
        ),
      );
    }
    if (p95Planning > _comfortP95PlanningLimit) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn p95 planning time ${p95Planning.inMilliseconds}ms '
              'exceeds the comfort target of '
              '${_comfortP95PlanningLimit.inMilliseconds}ms.',
        ),
      );
    }
    if (maxPlanning > const Duration(milliseconds: 900)) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn max planning time ${maxPlanning.inMilliseconds}ms '
              'exceeds 900ms.',
        ),
      );
    }
    if (p95EstimatedVisibleCycle > _comfortP95EstimatedVisibleCycleLimit) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'Multi-turn p95 estimated visible AI cycle time '
              '${p95EstimatedVisibleCycle.inMilliseconds}ms exceeds the '
              'comfort gate of '
              '${_comfortP95EstimatedVisibleCycleLimit.inMilliseconds}ms '
              'at ${_singlePlayerDelay.inMilliseconds}ms/command.',
        ),
      );
    }
    if (averageEstimatedVisibleCycle > const Duration(milliseconds: 2000)) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn estimated visible AI cycle time '
              '${averageEstimatedVisibleCycle.inMilliseconds}ms exceeds '
              '2000ms at ${_singlePlayerDelay.inMilliseconds}ms/command.',
        ),
      );
    }
    if (maxEstimatedVisibleCycle > _comfortMaxEstimatedVisibleCycleLimit) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'Multi-turn max estimated visible AI cycle time '
              '${maxEstimatedVisibleCycle.inMilliseconds}ms exceeds the '
              'comfort gate of '
              '${_comfortMaxEstimatedVisibleCycleLimit.inMilliseconds}ms '
              'at ${_singlePlayerDelay.inMilliseconds}ms/command.',
        ),
      );
    }
    if (maxEstimatedVisibleCycle > const Duration(milliseconds: 3500)) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn max estimated visible AI cycle time '
              '${maxEstimatedVisibleCycle.inMilliseconds}ms exceeds '
              '3500ms at ${_singlePlayerDelay.inMilliseconds}ms/command.',
        ),
      );
    }
    if (p95EstimatedVisibleDelayCommands > 16) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn p95 visible command pacing '
              '$p95EstimatedVisibleDelayCommands command(s)/player-turn exceeds '
              '16 at ${_singlePlayerDelay.inMilliseconds}ms/command.',
        ),
      );
    }
    if (maxEstimatedVisibleDelayCommands > 24) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Multi-turn max visible command pacing '
              '$maxEstimatedVisibleDelayCommands command(s)/player-turn exceeds '
              '24 at ${_singlePlayerDelay.inMilliseconds}ms/command.',
        ),
      );
    }
    if (totalStale > 0) {
      findings.add(
        _Finding(
          severity: 'warn',
          message: 'Multi-turn replay skipped $totalStale stale move(s).',
        ),
      );
    }
    return findings;
  }

  _MultiTurnFindingSample? _firstTurnMatching(
    String playerId,
    bool Function(_MultiTurnPlayerReport turn) test,
  ) {
    for (final cycle in cycles) {
      for (final turn in cycle.playerTurns) {
        if (turn.playerId != playerId || !test(turn)) continue;
        return _MultiTurnFindingSample(cycle: cycle, turn: turn);
      }
    }
    return null;
  }

  Map<String, Object?> toJson() {
    return {
      'savePath': savePath,
      'startTurn': startTurn,
      'endTurn': endTurn,
      'startHumanCities': startHumanCities,
      'endHumanCities': endHumanCities,
      'endHumanCityStates': [
        for (final cityState in endHumanCityStates) cityState.toJson(),
      ],
      'summary': {
        'cycles': cycles.length,
        'playerTurns': playerTurns.length,
        'totalPlanningMs': totalPlanning.inMilliseconds,
        'totalExecutionMs': totalExecution.inMilliseconds,
        'totalComputeMs': totalCompute.inMilliseconds,
        'totalEstimatedInterCommandDelayMs':
            totalEstimatedInterCommandDelay.inMilliseconds,
        'totalEstimatedVisibleMs': totalEstimatedVisible.inMilliseconds,
        'totalEstimatedVisibleDelayCommands':
            totalEstimatedVisibleDelayCommands,
        'p95EstimatedVisibleDelayCommands': p95EstimatedVisibleDelayCommands,
        'maxEstimatedVisibleDelayCommands': maxEstimatedVisibleDelayCommands,
        'averagePlanningMs': averagePlanning.inMilliseconds,
        'p90PlanningMs': p90Planning.inMilliseconds,
        'p95PlanningMs': p95Planning.inMilliseconds,
        'maxPlanningMs': maxPlanning.inMilliseconds,
        'averageExecutionMs': averageExecution.inMilliseconds,
        'p90ExecutionMs': p90Execution.inMilliseconds,
        'p95ExecutionMs': p95Execution.inMilliseconds,
        'maxExecutionMs': maxExecution.inMilliseconds,
        'averageComputeMs': averageCompute.inMilliseconds,
        'p90ComputeMs': p90Compute.inMilliseconds,
        'p95ComputeMs': p95Compute.inMilliseconds,
        'maxComputeMs': maxCompute.inMilliseconds,
        'averageEstimatedVisibleTurnMs':
            averageEstimatedVisibleTurn.inMilliseconds,
        'p90EstimatedVisibleTurnMs': p90EstimatedVisibleTurn.inMilliseconds,
        'p95EstimatedVisibleTurnMs': p95EstimatedVisibleTurn.inMilliseconds,
        'maxEstimatedVisibleTurnMs': maxEstimatedVisibleTurn.inMilliseconds,
        'averageEstimatedVisibleCycleMs':
            averageEstimatedVisibleCycle.inMilliseconds,
        'p90EstimatedVisibleCycleMs': p90EstimatedVisibleCycle.inMilliseconds,
        'p95EstimatedVisibleCycleMs': p95EstimatedVisibleCycle.inMilliseconds,
        'maxEstimatedVisibleCycleMs': maxEstimatedVisibleCycle.inMilliseconds,
        'totalCommands': totalCommands,
        'totalHumanAttacks': totalHumanAttacks,
        'totalPressureTargetAttacks': totalPressureTargetAttacks,
        'totalNonHumanAttacks': totalNonHumanAttacks,
        'totalDistractingNonHumanAttacks': totalDistractingNonHumanAttacks,
        'attackTargetOwners': attackTargetOwners,
        'nonHumanAttackReasons': nonHumanAttackReasons,
        'distractingNonHumanAttacksByPlayer':
            distractingNonHumanAttacksByPlayer,
        'totalImmediateHumanAttacks': totalImmediateHumanAttacks,
        'totalRejected': totalRejected,
        'totalStale': totalStale,
        'staleMoveReasons': staleMoveReasons,
        'totalCityCaptures': totalCityCaptures,
        'totalMissingWarGoalTurns': totalMissingWarGoalTurns,
        'missingWarGoalTurnsByPlayer': missingWarGoalTurnsByPlayer,
        'totalPassiveWarPressureTurns': totalPassiveWarPressureTurns,
        'passiveWarPressureTurnsByPlayer': passiveWarPressureTurnsByPlayer,
        'longestPassiveWarPressureStreakByPlayer':
            longestPassiveWarPressureStreakByPlayer,
        'totalPressureTargetIdleTurns': totalPressureTargetIdleTurns,
        'pressureTargetIdleTurnsByPlayer': pressureTargetIdleTurnsByPlayer,
        'longestPressureTargetIdleStreakByPlayer':
            longestPressureTargetIdleStreakByPlayer,
        'totalPressureTargetSiegeTurns': totalPressureTargetSiegeTurns,
        'pressureTargetSiegeTurnsByPlayer': pressureTargetSiegeTurnsByPlayer,
      },
      'cycles': [for (final cycle in cycles) cycle.toJson()],
      'findings': [for (final finding in findings) finding.toJson()],
    };
  }
}
