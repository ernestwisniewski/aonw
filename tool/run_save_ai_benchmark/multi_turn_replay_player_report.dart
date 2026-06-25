part of '../run_save_ai_benchmark.dart';

class _MultiTurnPlayerReport {
  const _MultiTurnPlayerReport({
    required this.playerId,
    required this.playerName,
    required this.strategicMode,
    required this.warGoals,
    required this.strategicPlan,
    required this.defenseAssignedUnitCount,
    required this.defenseAssignmentCount,
    required this.frontierClearingAssignedUnitCount,
    required this.planningDuration,
    required this.plan,
    required this.view,
    required this.humanPlayerIds,
    required this.immediateHumanAttackTargets,
    required this.applied,
    required this.rejected,
    required this.stale,
    required this.skippedTerminal,
    required this.terminalChangedState,
    required this.executionDuration,
    required this.eventCounts,
    required this.staleMoveDiagnostics,
    required this.rejectedCommandSample,
    required this.plannedCommandSample,
  });

  final String playerId;
  final String playerName;
  final String strategicMode;
  final List<String> warGoals;
  final StrategicPlan strategicPlan;
  final int defenseAssignedUnitCount;
  final int defenseAssignmentCount;
  final int frontierClearingAssignedUnitCount;
  final Duration planningDuration;
  final AiTurnPlan plan;
  final GameView view;
  final Set<String> humanPlayerIds;
  final List<String> immediateHumanAttackTargets;
  final int applied;
  final int rejected;
  final int stale;
  final int skippedTerminal;
  final bool terminalChangedState;
  final Duration executionDuration;
  final _ExecutionEventCountsSnapshot eventCounts;
  final List<_StaleMoveDiagnostic> staleMoveDiagnostics;
  final List<String> rejectedCommandSample;
  final List<String> plannedCommandSample;

  int get immediateHumanAttacks => immediateHumanAttackTargets.length;

  Duration get computeDuration => planningDuration + executionDuration;

  Duration get estimatedInterCommandDelayDuration => Duration(
    milliseconds:
        commandStats.estimatedVisibleDelayCommands *
        _singlePlayerDelay.inMilliseconds,
  );

  Duration get estimatedVisibleDuration =>
      computeDuration + estimatedInterCommandDelayDuration;

  int get militaryCount {
    return view.ownUnits
        .where((unit) => _isMilitaryUnit(unit, view.ruleset.combat))
        .length;
  }

  int get targetableHumanCityCount {
    return view.rememberedTargetableEnemyCities
        .where((city) => humanPlayerIds.contains(city.ownerPlayerId))
        .length;
  }

  int get targetableHumanUnitCount {
    return view.visibleTargetableEnemyUnits
        .where((unit) => humanPlayerIds.contains(unit.ownerPlayerId))
        .length;
  }

  int? get nearestHumanDistance {
    final ownAnchors = <HexCoordinate>[
      for (final city in view.ownCities) city.center.toCoordinate(),
      for (final unit in view.ownUnits)
        HexCoordinate(col: unit.col, row: unit.row),
    ];
    final humanAnchors = _humanTargetAnchors(view, humanPlayerIds);
    if (ownAnchors.isEmpty || humanAnchors.isEmpty) return null;

    var nearest = 1 << 30;
    for (final own in ownAnchors) {
      for (final target in humanAnchors) {
        nearest = math.min(nearest, HexDistance.between(own, target));
      }
    }
    return nearest;
  }

  int? get nearestPressureTargetMilitaryDistance {
    final pressureAnchors = _targetAnchorsForOwners(
      view,
      _humanPressureTargetPlayerIds,
    );
    if (pressureAnchors.isEmpty) return null;

    int? nearest;
    for (final unit in _militaryUnits) {
      final distance = _nearestDistance(
        HexCoordinate(col: unit.col, row: unit.row),
        pressureAnchors,
      );
      nearest = nearest == null ? distance : math.min(nearest, distance);
    }
    return nearest;
  }

  int get pressureContactMilitaryCount {
    return _pressureMilitaryCountWithin(maxDistance: 1);
  }

  int get pressureStagingMilitaryCount {
    return _pressureMilitaryCountWithin(maxDistance: 3);
  }

  int get pressureEngagementMilitaryCount {
    final pressureAnchors = _targetAnchorsForOwners(
      view,
      _humanPressureTargetPlayerIds,
    );
    if (pressureAnchors.isEmpty) return 0;

    var count = 0;
    for (final unit in _militaryUnits) {
      final stats = UnitCombatStats.derive(unit, ruleset: view.ruleset.combat);
      if (stats.attack <= 0) continue;
      final distance = _nearestDistance(
        HexCoordinate(col: unit.col, row: unit.row),
        pressureAnchors,
      );
      if (distance <= stats.range) count += 1;
    }
    return count;
  }

  int _pressureMilitaryCountWithin({required int maxDistance}) {
    final pressureAnchors = _targetAnchorsForOwners(
      view,
      _humanPressureTargetPlayerIds,
    );
    if (pressureAnchors.isEmpty) return 0;

    var count = 0;
    for (final unit in _militaryUnits) {
      final distance = _nearestDistance(
        HexCoordinate(col: unit.col, row: unit.row),
        pressureAnchors,
      );
      if (distance <= maxDistance) count += 1;
    }
    return count;
  }

  Iterable<GameUnit> get _militaryUnits sync* {
    for (final unit in view.ownUnits) {
      if (_isMilitaryUnit(unit, view.ruleset.combat)) yield unit;
    }
  }

  Set<String> get _humanPressureTargetPlayerIds {
    return {
      for (final playerId in view.pressureTargetPlayerIds)
        if (humanPlayerIds.contains(playerId)) playerId,
    };
  }

  bool get atWarWithHuman {
    return humanPlayerIds.any(
      (id) => view.relationStatusFor(id) == DiplomaticRelationStatus.war,
    );
  }

  bool get hasTargetableHumanAnchors {
    return targetableHumanCityCount + targetableHumanUnitCount > 0;
  }

  bool get hasHumanPressureTarget {
    return view.pressureTargetPlayerIds.any(humanPlayerIds.contains);
  }

  bool get missingWarGoalWhileAtWar {
    return atWarWithHuman &&
        militaryCount >= 2 &&
        hasTargetableHumanAnchors &&
        warGoals.isEmpty;
  }

  bool get passiveWarPressureTurn {
    if (!atWarWithHuman || militaryCount < 2 || !hasTargetableHumanAnchors) {
      return false;
    }
    final stats = commandStats;
    return stats.attacks == 0 &&
        stats.movesTowardHumans == 0 &&
        stats.movesTowardWarGoals == 0;
  }

  bool get pressureTargetIdleTurn {
    if (!atWarWithHuman ||
        !hasHumanPressureTarget ||
        warGoals.isEmpty ||
        militaryCount < 2 ||
        !hasTargetableHumanAnchors) {
      return false;
    }
    final stats = commandStats;
    if (pressureContactMilitaryCount > 0 ||
        pressureEngagementMilitaryCount > 0) {
      return false;
    }
    return stats.attackPressureTargets == 0 &&
        stats.movesTowardPressureTargets == 0 &&
        stats.movesTowardWarGoals == 0;
  }

  bool get pressureTargetSiegeTurn {
    if (!atWarWithHuman ||
        !hasHumanPressureTarget ||
        warGoals.isEmpty ||
        militaryCount < 2 ||
        !hasTargetableHumanAnchors) {
      return false;
    }
    final stats = commandStats;
    if (stats.attackPressureTargets > 0 ||
        stats.movesTowardPressureTargets > 0 ||
        stats.movesTowardWarGoals > 0) {
      return false;
    }
    return pressureContactMilitaryCount > 0 ||
        pressureEngagementMilitaryCount > 0;
  }

  _CommandStats get commandStats {
    return _CommandStats.fromPlan(
      plan,
      view: view,
      humanPlayerIds: humanPlayerIds,
      strategicPlan: strategicPlan,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'strategicMode': strategicMode,
      'warGoals': warGoals,
      'strategicAssignments': {
        'defenseAssignedUnits': defenseAssignedUnitCount,
        'defenseAssignments': defenseAssignmentCount,
        'frontierClearingAssignedUnits': frontierClearingAssignedUnitCount,
      },
      'empire': {
        'cities': view.ownCities.length,
        'units': view.ownUnits.length,
        'military': militaryCount,
        'targetableHumanCities': targetableHumanCityCount,
        'targetableHumanUnits': targetableHumanUnitCount,
        'nearestHumanDistance': nearestHumanDistance,
        'nearestPressureTargetMilitaryDistance':
            nearestPressureTargetMilitaryDistance,
        'pressureContactMilitary': pressureContactMilitaryCount,
        'pressureStagingMilitary': pressureStagingMilitaryCount,
        'pressureEngagementMilitary': pressureEngagementMilitaryCount,
        'atWarWithHuman': atWarWithHuman,
        'hasHumanPressureTarget': hasHumanPressureTarget,
        'missingWarGoalWhileAtWar': missingWarGoalWhileAtWar,
        'passiveWarPressureTurn': passiveWarPressureTurn,
        'pressureTargetIdleTurn': pressureTargetIdleTurn,
        'pressureTargetSiegeTurn': pressureTargetSiegeTurn,
        'pressureTargetPlayerIds': view.pressureTargetPlayerIds.toList()
          ..sort(),
        'recentHostilePlayerIds': view.recentHostilePlayerIds.toList()..sort(),
        'diplomacyVsHumans': {
          for (final humanId in humanPlayerIds)
            humanId: view.relationStatusFor(humanId).name,
        },
      },
      'planningMs': planningDuration.inMilliseconds,
      'executionMs': executionDuration.inMilliseconds,
      'computeMs': computeDuration.inMilliseconds,
      'estimatedInterCommandDelayMs':
          estimatedInterCommandDelayDuration.inMilliseconds,
      'estimatedVisibleMs': estimatedVisibleDuration.inMilliseconds,
      'commands': commandStats.toJson(),
      'immediateHumanAttacks': immediateHumanAttacks,
      'immediateHumanAttackTargets': immediateHumanAttackTargets
          .take(12)
          .toList(),
      'applied': applied,
      'rejected': rejected,
      'stale': stale,
      'skippedTerminal': skippedTerminal,
      'terminalChangedState': terminalChangedState,
      'events': eventCounts.toJson(),
      'staleMoveDiagnostics': [
        for (final diagnostic in staleMoveDiagnostics.take(12))
          diagnostic.toJson(),
      ],
      'rejectedCommands': rejectedCommandSample,
      'plannedCommands': plannedCommandSample,
      'debugMetrics': plan.debug?.metrics ?? const {},
    };
  }
}
