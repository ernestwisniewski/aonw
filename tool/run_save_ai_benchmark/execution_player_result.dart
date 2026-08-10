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
