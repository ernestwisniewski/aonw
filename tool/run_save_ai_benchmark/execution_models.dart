part of '../run_save_ai_benchmark.dart';

class _PlayerBenchmarkResult {
  const _PlayerBenchmarkResult({
    required this.player,
    required this.ai,
    required this.effectiveStrategyId,
    required this.view,
    required this.context,
    required this.assessment,
    required this.strategicPlan,
    required this.profileRuns,
    required this.humanPlayerIds,
  });

  final Player player;
  final AiPlayer ai;
  final AiStrategyId effectiveStrategyId;
  final GameView view;
  final AiContext context;
  final AiEmpireAssessment assessment;
  final StrategicPlan strategicPlan;
  final List<_ProfileRun> profileRuns;
  final Set<String> humanPlayerIds;

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

  int get immediateHumanAttackCount {
    return _immediateHumanAttackTargets(view, context, humanPlayerIds).length;
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

  String get humanDiplomacySummary {
    if (humanPlayerIds.isEmpty) return 'none';
    return [
      for (final humanId in humanPlayerIds)
        '$humanId=${view.relationStatusFor(humanId).name}',
    ].join(', ');
  }

  List<_Finding> get findings {
    final findings = <_Finding>[];
    final atWarWithHuman = humanPlayerIds.any(
      (id) => view.relationStatusFor(id) == DiplomaticRelationStatus.war,
    );
    if (!atWarWithHuman) return findings;

    final autoRun = profileRuns.firstWhere(
      (run) => run.profile.name == 'auto',
      orElse: () => profileRuns.first,
    );
    final stats = autoRun.commandStats;
    if (targetableHumanCityCount == 0 && targetableHumanUnitCount == 0) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message:
              'AI is at war with a human but has no targetable human anchors.',
        ),
      );
    }
    if (militaryCount >= 2 && strategicPlan.warGoals.isEmpty) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'AI has $militaryCount military units and is at war, '
              'but generated no war goal.',
        ),
      );
    }
    if (militaryCount >= 2 &&
        stats.attackHumans == 0 &&
        stats.movesTowardHumans == 0 &&
        stats.movesTowardWarGoals == 0) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'AI is at war and has $militaryCount military units, '
              'but planned no direct attack or approach move toward the human.',
        ),
      );
    }
    if (immediateHumanAttackCount > 0 && stats.attackHumans == 0) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'AI has $immediateHumanAttackCount immediate human attack '
              'opportunity/opportunities but planned no human attack.',
        ),
      );
    }
    if (autoRun.execution.rejectedCommands.isNotEmpty) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'Reducer rejected ${autoRun.execution.rejectedCommands.length} '
              'planned AI command(s) in execution simulation.',
        ),
      );
    }
    if (!autoRun.execution.terminalChangedState) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'AI terminal command ${_describeCommand(autoRun.execution.terminalCommand)} '
              'did not change game state.',
        ),
      );
    }
    if (autoRun.average > const Duration(milliseconds: 650)) {
      findings.add(
        _Finding(
          severity: 'warn',
          message:
              'Average planning time ${autoRun.average.inMilliseconds}ms '
              'exceeds the interactive fresh-turn threshold of 650ms.',
        ),
      );
    }
    return findings;
  }

  Map<String, Object?> toJson() {
    return {
      'playerId': player.id,
      'name': player.name,
      'country': player.country.name,
      'ai': {
        'strategyId': ai.strategyId.name,
        'difficulty': ai.difficulty.name,
        'persona': ai.persona.name,
        'seed': ai.seed,
      },
      'effectiveStrategyId': effectiveStrategyId.name,
      'empire': {
        'cities': view.ownCities.length,
        'units': view.ownUnits.length,
        'military': militaryCount,
        'gold': view.ownGold,
        'targetableHumanCities': targetableHumanCityCount,
        'targetableHumanUnits': targetableHumanUnitCount,
        'immediateHumanAttacks': immediateHumanAttackCount,
        'nearestHumanDistance': nearestHumanDistance,
        'diplomacyVsHumans': {
          for (final humanId in humanPlayerIds)
            humanId: view.relationStatusFor(humanId).name,
        },
      },
      'strategy': {
        'mode': strategicPlan.mode.name,
        'targetability': [
          for (final target in const TargetabilityScorer().rank(
            assessment: assessment,
            rivals: RivalSnapshot.fromView(view),
            context: context,
            priorityTargetPlayerIds: view.pressureTargetPlayerIds,
          ))
            {
              'playerId': target.playerId,
              'score': target.score,
              'territoryValue': target.territoryValue,
              'relativeMilitary': target.relativeMilitary,
              'distanceFactor': target.distanceFactor,
              'priorityTarget': target.priorityTarget,
              'isHostile': target.rival.isHostile,
              'recentlyHostile': target.rival.recentlyHostile,
            },
        ],
        'assignments': {
          'defenses': strategicPlan.defenses.length,
          'defenseUnitIds': [
            for (final defense in strategicPlan.defenses.values)
              ...defense.assignedUnitIds,
          ],
          'frontierClearing': strategicPlan.frontierClearingAssignments.length,
          'frontierClearingUnitIds': strategicPlan
              .frontierClearingAssignments
              .keys
              .toList(),
          'workerAssignments': strategicPlan.workerAssignments.length,
          'settlerAssignments': strategicPlan.settlerAssignments.length,
        },
        'warGoals': [
          for (final goal in strategicPlan.warGoals)
            {
              'targetPlayerId': goal.targetPlayerId,
              'kind': goal.kind.name,
              'targetHex': {
                'col': goal.targetHex.col,
                'row': goal.targetHex.row,
              },
              'targetCity': goal.targetCity == null
                  ? null
                  : {'col': goal.targetCity!.col, 'row': goal.targetCity!.row},
              'turnsBudget': goal.turnsBudget,
              'assignedUnitIds': goal.assignedUnitIds,
              'priority': goal.priority,
            },
        ],
        'rivals': [
          for (final threat in strategicPlan.rivalRanking)
            {
              'playerId': threat.rival.playerId,
              'score': threat.score,
              'rememberedCityCount': threat.rival.rememberedCityCount,
              'visibleUnitCount': threat.rival.visibleUnitCount,
              'visibleMilitaryCount': threat.rival.visibleMilitaryCount,
              'nearestDistance': threat.rival.nearestDistance,
              'isHostile': threat.rival.isHostile,
              'recentlyHostile': threat.rival.recentlyHostile,
            },
        ],
      },
      'runs': [for (final run in profileRuns) run.toJson()],
      'findings': [for (final finding in findings) finding.toJson()],
    };
  }
}

class _ProfileRun {
  const _ProfileRun({
    required this.profile,
    required this.durations,
    required this.plan,
    required this.humanPlayerIds,
    required this.view,
    required this.strategicPlan,
    required this.execution,
  });

  final _ProfileSelection profile;
  final List<Duration> durations;
  final AiTurnPlan plan;
  final Set<String> humanPlayerIds;
  final GameView view;
  final StrategicPlan strategicPlan;
  final _ExecutionRun execution;

  Duration get average {
    if (durations.isEmpty) return Duration.zero;
    final totalMicros = durations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );
    return Duration(microseconds: totalMicros ~/ durations.length);
  }

  Duration get min => durations.reduce((a, b) => a < b ? a : b);

  Duration get max => durations.reduce((a, b) => a > b ? a : b);

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
      'profile': profile.name,
      'durationsMs': [
        for (final duration in durations) duration.inMilliseconds,
      ],
      'averageMs': average.inMilliseconds,
      'minMs': min.inMilliseconds,
      'maxMs': max.inMilliseconds,
      'commands': commandStats.toJson(),
      'plannedCommands': [
        for (final command in plan.commands.take(12)) _describeCommand(command),
      ],
      'execution': execution.toJson(),
      'debug': {
        'strategyId': plan.debug?.strategyId,
        'notes': plan.debug?.notes ?? const [],
        'metrics': plan.debug?.metrics ?? const {},
      },
    };
  }
}

class _ExecutionRun {
  const _ExecutionRun({
    required this.plannedCommandCount,
    required this.dispatchedCommands,
    required this.rejectedCommands,
    required this.rejectedReasons,
    required this.skippedTerminalCommands,
    required this.skippedStaleCommands,
    required this.terminalCommand,
    required this.terminalChangedState,
    required this.totalDuration,
    required this.dispatchDuration,
    required this.terminalDuration,
    required this.eventCounts,
    required this.humanPlayerIds,
    required this.view,
  });

  final int plannedCommandCount;
  final List<GameCommand> dispatchedCommands;
  final List<GameCommand> rejectedCommands;
  final List<String> rejectedReasons;
  final List<GameCommand> skippedTerminalCommands;
  final List<GameCommand> skippedStaleCommands;
  final GameCommand terminalCommand;
  final bool terminalChangedState;
  final Duration totalDuration;
  final Duration dispatchDuration;
  final Duration terminalDuration;
  final _ExecutionEventCountsSnapshot eventCounts;
  final Set<String> humanPlayerIds;
  final GameView view;

  _CommandStats get appliedCommandStats {
    return _CommandStats.fromCommands(
      dispatchedCommands,
      view: view,
      humanPlayerIds: humanPlayerIds,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'planned': plannedCommandCount,
      'applied': dispatchedCommands.length,
      'rejected': rejectedCommands.length,
      'skippedTerminal': skippedTerminalCommands.length,
      'skippedStale': skippedStaleCommands.length,
      'durationMs': totalDuration.inMilliseconds,
      'dispatchMs': dispatchDuration.inMilliseconds,
      'terminalMs': terminalDuration.inMilliseconds,
      'terminal': {
        'command': _describeCommand(terminalCommand),
        'changedState': terminalChangedState,
      },
      'appliedCommands': appliedCommandStats.toJson(),
      'events': eventCounts.toJson(),
      'rejectedCommands': [
        for (final command in rejectedCommands.take(10))
          _describeCommand(command),
      ],
      'rejectedReasons': rejectedReasons.take(10).toList(),
    };
  }
}

class _ExecutionEventCounts {
  var total = 0;
  var commandRejected = 0;
  var unitAttacks = 0;
  var combatResolved = 0;
  var unitKills = 0;
  var cityCaptures = 0;
  var cityDestroyed = 0;
  var allPlayersSubmitted = 0;

  void add(GameStateTransition transition) {
    addEvents(transition.events);
  }

  void addEvents(Iterable<GameEvent> events) {
    final eventsList = events.toList();
    total += eventsList.length;
    for (final event in eventsList) {
      switch (event) {
        case CommandRejectedEvent():
          commandRejected += 1;
        case UnitAttackedEvent():
          unitAttacks += 1;
        case CombatResolvedEvent():
          combatResolved += 1;
        case UnitKilledEvent():
          unitKills += 1;
        case CityCapturedEvent():
          cityCaptures += 1;
        case CityDestroyedEvent():
          cityDestroyed += 1;
        case AllPlayersSubmittedEvent():
          allPlayersSubmitted += 1;
        default:
          break;
      }
    }
  }

  _ExecutionEventCountsSnapshot snapshot() {
    return _ExecutionEventCountsSnapshot(
      total: total,
      commandRejected: commandRejected,
      unitAttacks: unitAttacks,
      combatResolved: combatResolved,
      unitKills: unitKills,
      cityCaptures: cityCaptures,
      cityDestroyed: cityDestroyed,
      allPlayersSubmitted: allPlayersSubmitted,
    );
  }
}

class _ExecutionEventCountsSnapshot {
  const _ExecutionEventCountsSnapshot({
    required this.total,
    required this.commandRejected,
    required this.unitAttacks,
    required this.combatResolved,
    required this.unitKills,
    required this.cityCaptures,
    required this.cityDestroyed,
    required this.allPlayersSubmitted,
  });

  final int total;
  final int commandRejected;
  final int unitAttacks;
  final int combatResolved;
  final int unitKills;
  final int cityCaptures;
  final int cityDestroyed;
  final int allPlayersSubmitted;

  Map<String, Object?> toJson() {
    return {
      'total': total,
      'commandRejected': commandRejected,
      'unitAttacks': unitAttacks,
      'combatResolved': combatResolved,
      'unitKills': unitKills,
      'cityCaptures': cityCaptures,
      'cityDestroyed': cityDestroyed,
      'allPlayersSubmitted': allPlayersSubmitted,
    };
  }
}

class _CommandStats {
  _CommandStats({
    required this.total,
    required this.attacks,
    required this.attackHumans,
    required this.attackPressureTargets,
    required this.attackNonHumans,
    required this.attackUnknownTargets,
    required Map<String, int> attackTargetOwners,
    required Map<String, int> nonHumanAttackReasons,
    required this.moves,
    required this.movesTowardHumans,
    required this.movesAwayFromHumans,
    required this.movesTowardWarGoals,
    required this.movesAwayFromWarGoals,
    required this.movesTowardPressureTargets,
    required this.movesAwayFromPressureTargets,
    required this.production,
    required this.workerActions,
    required this.estimatedVisibleDelayCommands,
  }) : attackTargetOwners = Map.unmodifiable(attackTargetOwners),
       nonHumanAttackReasons = Map.unmodifiable(nonHumanAttackReasons);

  final int total;
  final int attacks;
  final int attackHumans;
  final int attackPressureTargets;
  final int attackNonHumans;
  final int attackUnknownTargets;
  final Map<String, int> attackTargetOwners;
  final Map<String, int> nonHumanAttackReasons;
  final int moves;
  final int movesTowardHumans;
  final int movesAwayFromHumans;
  final int movesTowardWarGoals;
  final int movesAwayFromWarGoals;
  final int movesTowardPressureTargets;
  final int movesAwayFromPressureTargets;
  final int production;
  final int workerActions;
  final int estimatedVisibleDelayCommands;

  int get distractingNonHumanAttacks {
    return nonHumanAttackReasons[_nonHumanAttackReasonDistracting] ?? 0;
  }

  factory _CommandStats.fromPlan(
    AiTurnPlan plan, {
    required GameView view,
    required Set<String> humanPlayerIds,
    StrategicPlan? strategicPlan,
  }) {
    return _CommandStats.fromCommands(
      plan.commands,
      view: view,
      humanPlayerIds: humanPlayerIds,
      strategicPlan: strategicPlan,
    );
  }

  factory _CommandStats.fromCommands(
    Iterable<GameCommand> commands, {
    required GameView view,
    required Set<String> humanPlayerIds,
    StrategicPlan? strategicPlan,
  }) {
    var attacks = 0;
    var attackHumans = 0;
    var attackPressureTargets = 0;
    var attackNonHumans = 0;
    var attackUnknownTargets = 0;
    var moves = 0;
    var movesTowardHumans = 0;
    var movesAwayFromHumans = 0;
    var movesTowardWarGoals = 0;
    var movesAwayFromWarGoals = 0;
    var movesTowardPressureTargets = 0;
    var movesAwayFromPressureTargets = 0;
    var production = 0;
    var workerActions = 0;
    var estimatedVisibleDelayCommands = 0;
    final attackTargetOwners = <String, int>{};
    final nonHumanAttackReasons = <String, int>{};
    final unitsById = {for (final unit in view.ownUnits) unit.id: unit};
    final humanAnchors = _humanTargetAnchors(view, humanPlayerIds);
    final humanPressureTargetIds = {
      for (final playerId in view.pressureTargetPlayerIds)
        if (humanPlayerIds.contains(playerId)) playerId,
    };
    final humanPressureAnchors = _targetAnchorsForOwners(
      view,
      humanPressureTargetIds,
    );
    final pressureAnchors = _targetAnchorsForOwners(
      view,
      view.pressureTargetPlayerIds,
    );
    final warGoalAnchors = _warGoalTargetAnchors(
      strategicPlan,
      view,
      humanPlayerIds,
    );
    final warGoalAnchorsByUnitId = _warGoalTargetAnchorsByUnitId(
      strategicPlan,
      view,
      humanPlayerIds,
    );
    final hasHumanPressureContact = _hasPressureContact(
      view,
      humanPressureAnchors,
    );

    var total = 0;
    for (final command in commands) {
      total += 1;
      switch (command) {
        case AttackHexCommand():
          estimatedVisibleDelayCommands += 1;
          attacks += 1;
          final targetOwner = _ownerAt(
            view,
            command.defenderCol,
            command.defenderRow,
          );
          if (targetOwner == null) {
            attackUnknownTargets += 1;
          } else {
            attackTargetOwners.update(
              targetOwner,
              (count) => count + 1,
              ifAbsent: () => 1,
            );
            if (humanPlayerIds.contains(targetOwner)) {
              attackHumans += 1;
            } else {
              attackNonHumans += 1;
              final reason = _nonHumanAttackReason(
                command,
                view: view,
                targetOwner: targetOwner,
                humanPressureAnchors: humanPressureAnchors,
                hasHumanPressureContact: hasHumanPressureContact,
              );
              nonHumanAttackReasons.update(
                reason,
                (count) => count + 1,
                ifAbsent: () => 1,
              );
            }
            if (view.pressureTargetPlayerIds.contains(targetOwner)) {
              attackPressureTargets += 1;
            }
          }
        case MoveUnitCommand():
          estimatedVisibleDelayCommands += 1;
          moves += 1;
          final unit = unitsById[command.unitId];
          if (unit != null && humanAnchors.isNotEmpty) {
            final before = _nearestDistance(
              HexCoordinate(col: unit.col, row: unit.row),
              humanAnchors,
            );
            final after = _nearestDistance(
              HexCoordinate(col: command.targetCol, row: command.targetRow),
              humanAnchors,
            );
            if (after < before) movesTowardHumans += 1;
            if (after > before) movesAwayFromHumans += 1;
          }
          if (unit != null && pressureAnchors.isNotEmpty) {
            final before = _nearestDistance(
              HexCoordinate(col: unit.col, row: unit.row),
              pressureAnchors,
            );
            final after = _nearestDistance(
              HexCoordinate(col: command.targetCol, row: command.targetRow),
              pressureAnchors,
            );
            if (after < before) movesTowardPressureTargets += 1;
            if (after > before) movesAwayFromPressureTargets += 1;
          }
          if (unit != null) {
            final anchors = warGoalAnchorsByUnitId[unit.id] ?? warGoalAnchors;
            if (anchors.isNotEmpty) {
              final before = _nearestDistance(
                HexCoordinate(col: unit.col, row: unit.row),
                anchors,
              );
              final after = _nearestDistance(
                HexCoordinate(col: command.targetCol, row: command.targetRow),
                anchors,
              );
              if (after < before) movesTowardWarGoals += 1;
              if (after > before) movesAwayFromWarGoals += 1;
            }
          }
        case FoundCityCommand():
          estimatedVisibleDelayCommands += 1;
        case StartBuildingCommand() ||
            StartUnitProductionCommand() ||
            StartCityProjectCommand() ||
            RushProductionCommand():
          production += 1;
        case SelectWorkerImprovementCommand() ||
            ConfirmWorkerImprovementCommand() ||
            AssignWorkerToHexCommand() ||
            CancelWorkerAssignmentCommand() ||
            CancelWorkerJobCommand():
          estimatedVisibleDelayCommands += 1;
          workerActions += 1;
        default:
          break;
      }
    }

    return _CommandStats(
      total: total,
      attacks: attacks,
      attackHumans: attackHumans,
      attackPressureTargets: attackPressureTargets,
      attackNonHumans: attackNonHumans,
      attackUnknownTargets: attackUnknownTargets,
      attackTargetOwners: _sortedIntMap(attackTargetOwners),
      nonHumanAttackReasons: _sortedIntMap(nonHumanAttackReasons),
      moves: moves,
      movesTowardHumans: movesTowardHumans,
      movesAwayFromHumans: movesAwayFromHumans,
      movesTowardWarGoals: movesTowardWarGoals,
      movesAwayFromWarGoals: movesAwayFromWarGoals,
      movesTowardPressureTargets: movesTowardPressureTargets,
      movesAwayFromPressureTargets: movesAwayFromPressureTargets,
      production: production,
      workerActions: workerActions,
      estimatedVisibleDelayCommands: estimatedVisibleDelayCommands,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'total': total,
      'attacks': attacks,
      'attackHumans': attackHumans,
      'attackPressureTargets': attackPressureTargets,
      'attackNonHumans': attackNonHumans,
      'attackUnknownTargets': attackUnknownTargets,
      'attackTargetOwners': attackTargetOwners,
      'nonHumanAttackReasons': nonHumanAttackReasons,
      'distractingNonHumanAttacks': distractingNonHumanAttacks,
      'moves': moves,
      'movesTowardHumans': movesTowardHumans,
      'movesAwayFromHumans': movesAwayFromHumans,
      'movesTowardWarGoals': movesTowardWarGoals,
      'movesAwayFromWarGoals': movesAwayFromWarGoals,
      'movesTowardPressureTargets': movesTowardPressureTargets,
      'movesAwayFromPressureTargets': movesAwayFromPressureTargets,
      'production': production,
      'workerActions': workerActions,
      'estimatedVisibleDelayCommands': estimatedVisibleDelayCommands,
    };
  }
}
