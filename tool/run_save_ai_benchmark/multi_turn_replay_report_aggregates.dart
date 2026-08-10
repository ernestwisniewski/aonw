part of '../run_save_ai_benchmark.dart';

extension _MultiTurnReplayReportAggregates on _MultiTurnReplayReport {
  Iterable<_MultiTurnPlayerReport> get playerTurns sync* {
    for (final cycle in cycles) {
      yield* cycle.playerTurns;
    }
  }

  int get totalCommands =>
      playerTurns.fold(0, (sum, turn) => sum + turn.commandStats.total);

  int get totalHumanAttacks {
    return playerTurns.fold(
      0,
      (sum, turn) => sum + turn.commandStats.attackHumans,
    );
  }

  int get totalPressureTargetAttacks {
    return playerTurns.fold(
      0,
      (sum, turn) => sum + turn.commandStats.attackPressureTargets,
    );
  }

  int get totalNonHumanAttacks {
    return playerTurns.fold(
      0,
      (sum, turn) => sum + turn.commandStats.attackNonHumans,
    );
  }

  int get totalDistractingNonHumanAttacks {
    return playerTurns.fold(
      0,
      (sum, turn) => sum + turn.commandStats.distractingNonHumanAttacks,
    );
  }

  int get totalImmediateHumanAttacks =>
      playerTurns.fold(0, (sum, turn) => sum + turn.immediateHumanAttacks);

  int get totalRejected =>
      playerTurns.fold(0, (sum, turn) => sum + turn.rejected);

  int get totalStale => playerTurns.fold(0, (sum, turn) => sum + turn.stale);

  Map<String, int> get staleMoveReasons {
    final reasons = <String, int>{};
    for (final turn in playerTurns) {
      for (final diagnostic in turn.staleMoveDiagnostics) {
        reasons.update(
          diagnostic.reason,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return reasons;
  }

  int get totalCityCaptures {
    return playerTurns.fold(
      0,
      (sum, turn) => sum + turn.eventCounts.cityCaptures,
    );
  }

  Map<String, int> get attackTargetOwners {
    final owners = <String, int>{};
    for (final turn in playerTurns) {
      for (final entry in turn.commandStats.attackTargetOwners.entries) {
        owners.update(
          entry.key,
          (count) => count + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }
    return _sortedIntMap(owners);
  }

  Map<String, int> get nonHumanAttackReasons {
    final reasons = <String, int>{};
    for (final turn in playerTurns) {
      for (final entry in turn.commandStats.nonHumanAttackReasons.entries) {
        reasons.update(
          entry.key,
          (count) => count + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }
    return _sortedIntMap(reasons);
  }

  Map<String, int> get distractingNonHumanAttacksByPlayer {
    final counts = <String, int>{};
    for (final turn in playerTurns) {
      final count = turn.commandStats.distractingNonHumanAttacks;
      if (count <= 0) continue;
      counts.update(
        turn.playerId,
        (value) => value + count,
        ifAbsent: () => count,
      );
    }
    return _sortedIntMap(counts);
  }

  int get totalMissingWarGoalTurns {
    var count = 0;
    for (final turn in playerTurns) {
      if (turn.missingWarGoalWhileAtWar) count += 1;
    }
    return count;
  }

  int get totalPassiveWarPressureTurns {
    var count = 0;
    for (final turn in playerTurns) {
      if (turn.passiveWarPressureTurn) count += 1;
    }
    return count;
  }

  int get totalPressureTargetIdleTurns {
    var count = 0;
    for (final turn in playerTurns) {
      if (turn.pressureTargetIdleTurn) count += 1;
    }
    return count;
  }

  int get totalPressureTargetSiegeTurns {
    var count = 0;
    for (final turn in playerTurns) {
      if (turn.pressureTargetSiegeTurn) count += 1;
    }
    return count;
  }

  Map<String, int> get missingWarGoalTurnsByPlayer {
    final counts = <String, int>{};
    for (final turn in playerTurns) {
      if (!turn.missingWarGoalWhileAtWar) continue;
      counts.update(turn.playerId, (count) => count + 1, ifAbsent: () => 1);
    }
    return _sortedIntMap(counts);
  }

  Map<String, int> get passiveWarPressureTurnsByPlayer {
    final counts = <String, int>{};
    for (final turn in playerTurns) {
      if (!turn.passiveWarPressureTurn) continue;
      counts.update(turn.playerId, (count) => count + 1, ifAbsent: () => 1);
    }
    return _sortedIntMap(counts);
  }

  Map<String, int> get pressureTargetIdleTurnsByPlayer {
    final counts = <String, int>{};
    for (final turn in playerTurns) {
      if (!turn.pressureTargetIdleTurn) continue;
      counts.update(turn.playerId, (count) => count + 1, ifAbsent: () => 1);
    }
    return _sortedIntMap(counts);
  }

  Map<String, int> get pressureTargetSiegeTurnsByPlayer {
    final counts = <String, int>{};
    for (final turn in playerTurns) {
      if (!turn.pressureTargetSiegeTurn) continue;
      counts.update(turn.playerId, (count) => count + 1, ifAbsent: () => 1);
    }
    return _sortedIntMap(counts);
  }

  Map<String, int> get longestPassiveWarPressureStreakByPlayer {
    final current = <String, int>{};
    final longest = <String, int>{};
    for (final cycle in cycles) {
      for (final turn in cycle.playerTurns) {
        final next = turn.passiveWarPressureTurn
            ? (current[turn.playerId] ?? 0) + 1
            : 0;
        current[turn.playerId] = next;
        if (next > (longest[turn.playerId] ?? 0)) {
          longest[turn.playerId] = next;
        }
      }
    }
    return _sortedIntMap(longest);
  }

  Map<String, int> get longestPressureTargetIdleStreakByPlayer {
    final current = <String, int>{};
    final longest = <String, int>{};
    for (final cycle in cycles) {
      for (final turn in cycle.playerTurns) {
        final next = turn.pressureTargetIdleTurn
            ? (current[turn.playerId] ?? 0) + 1
            : 0;
        current[turn.playerId] = next;
        if (next > (longest[turn.playerId] ?? 0)) {
          longest[turn.playerId] = next;
        }
      }
    }
    return _sortedIntMap(longest);
  }
}
