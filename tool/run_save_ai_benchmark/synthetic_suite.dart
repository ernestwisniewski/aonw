part of '../run_save_ai_benchmark.dart';

class _SyntheticBenchmarkSuite {
  const _SyntheticBenchmarkSuite({
    required this.includeDeadline,
    required this.strategyOverride,
  });

  final bool includeDeadline;
  final AiStrategyId? strategyOverride;

  List<_SyntheticScenarioReport> run() {
    return [_runDiplomacyTargetingGuard(), _runFortifiedWakeUpGuard()];
  }

  _SyntheticScenarioReport _runDiplomacyTargetingGuard() {
    const aiId = 'ai_synthetic';
    const aiTankId = 'ai_tank';
    const warHumanId = 'human_war';
    const hostileHumanId = 'human_hostile';
    const friendlyHumanId = 'human_friendly';
    const neutralHumanId = 'human_neutral';
    const defaultNeutralAiId = 'ai_default_neutral';
    final mapData = _syntheticMapData(
      cols: 5,
      rows: 3,
      mapName: 'synthetic_diplomacy_guard',
    );
    final snapshot = _syntheticDiplomacySnapshot(mapData);
    final prepared = _prepareSyntheticPlayer(
      snapshot: snapshot,
      mapData: mapData,
      playerId: aiId,
      humanPlayerIds: const {
        warHumanId,
        hostileHumanId,
        friendlyHumanId,
        neutralHumanId,
      },
      includeDeadline: includeDeadline,
    );
    final result = prepared.run(
      profiles: const [_ProfileSelection.auto()],
      repeats: 1,
      strategyOverride: strategyOverride,
    );
    final run = result.profileRuns.first;
    final findings = <_Finding>[];
    _appendFailingPlannerFindings(findings, result);

    final pressureTargets = _sortedStrings(
      prepared.view.pressureTargetPlayerIds,
    );
    if (!prepared.view.pressureTargetPlayerIds.contains(warHumanId)) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message: 'At-war human is missing from AI pressure targets.',
        ),
      );
    }
    if (!prepared.view.pressureTargetPlayerIds.contains(hostileHumanId)) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message: 'Hostile human is missing from AI pressure targets.',
        ),
      );
    }
    for (final nonHostileHumanId in [friendlyHumanId, neutralHumanId]) {
      if (prepared.view.pressureTargetPlayerIds.contains(nonHostileHumanId)) {
        findings.add(
          _Finding(
            severity: 'fail',
            message:
                'Non-hostile human $nonHostileHumanId was included as a '
                'pressure target.',
          ),
        );
      }
    }

    final targetableOwners = _targetableOwnerIds(prepared.view);
    for (final nonHostilePlayerId in [
      friendlyHumanId,
      neutralHumanId,
      defaultNeutralAiId,
    ]) {
      if (targetableOwners.contains(nonHostilePlayerId)) {
        findings.add(
          _Finding(
            severity: 'fail',
            message:
                'Non-hostile player $nonHostilePlayerId is visible as a '
                'targetable enemy.',
          ),
        );
      }
    }
    for (final hostilePlayerId in [warHumanId, hostileHumanId]) {
      if (!targetableOwners.contains(hostilePlayerId)) {
        findings.add(
          _Finding(
            severity: 'fail',
            message:
                'Hostile player $hostilePlayerId is not visible as a '
                'targetable enemy.',
          ),
        );
      }
    }

    final plannedAttackOwners = _attackTargetOwnerIds(
      run.plan.commands,
      prepared.view,
    );
    for (final nonHostilePlayerId in [
      friendlyHumanId,
      neutralHumanId,
      defaultNeutralAiId,
    ]) {
      if (plannedAttackOwners.contains(nonHostilePlayerId)) {
        findings.add(
          _Finding(
            severity: 'fail',
            message:
                'AI planned an attack against non-hostile player '
                '$nonHostilePlayerId.',
          ),
        );
      }
    }

    final immediateWarTargets = _immediateHumanAttackTargets(
      prepared.view,
      prepared.context,
      const {warHumanId},
    );
    if (immediateWarTargets.isNotEmpty &&
        !plannedAttackOwners.contains(warHumanId)) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'AI had ${immediateWarTargets.length} immediate at-war target(s) '
              'but did not attack the hostile human.',
        ),
      );
    }

    final friendlyAttackChangedState = _syntheticCommandChangesState(
      prepared,
      const AttackHexCommand(aiTankId, 1, 0),
    );
    if (friendlyAttackChangedState) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message: 'Reducer allowed an attack against a friendly unit.',
        ),
      );
    }

    if (run.execution.rejectedCommands.isNotEmpty) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'Synthetic diplomacy plan had '
              '${run.execution.rejectedCommands.length} rejected command(s).',
        ),
      );
    }

    return _SyntheticScenarioReport(
      id: 'diplomacy_target_filter',
      name: 'Diplomacy target filter',
      description:
          'War and hostile targets must stay aggressive while friendly and '
          'explicit neutral humans remain non-targetable.',
      details: {
        'strategy': result.effectiveStrategyId.name,
        'pressureTargetPlayerIds': pressureTargets,
        'targetableOwnerPlayerIds': _sortedStrings(targetableOwners),
        'plannedAttackOwnerPlayerIds': _sortedStrings(plannedAttackOwners),
        'immediateWarTargets': immediateWarTargets.take(8).toList(),
        'plannedCommands': [
          for (final command in run.plan.commands.take(8))
            _describeCommand(command),
        ],
      },
      markdownDetails: [
        'Strategy: `${result.effectiveStrategyId.name}`',
        'Pressure targets: `${pressureTargets.join(', ')}`',
        'Targetable owners: `${_sortedStrings(targetableOwners).join(', ')}`',
        'Planned attack owners: `${_sortedStrings(plannedAttackOwners).join(', ')}`',
        'Commands: ${run.plan.commands.take(5).map(_describeCommand).join('; ')}',
      ],
      findings: findings,
    );
  }

  _SyntheticScenarioReport _runFortifiedWakeUpGuard() {
    const aiId = 'ai_synthetic';
    const humanId = 'human_war';
    const fortifiedUnitId = 'aa_fortified_vanguard';
    final mapData = _syntheticMapData(
      cols: 6,
      rows: 3,
      mapName: 'synthetic_fortified_wakeup_guard',
    );
    final snapshot = _syntheticFortifiedWakeUpSnapshot(mapData);
    final prepared = _prepareSyntheticPlayer(
      snapshot: snapshot,
      mapData: mapData,
      playerId: aiId,
      humanPlayerIds: const {humanId},
      includeDeadline: includeDeadline,
    );
    final result = prepared.run(
      profiles: const [_ProfileSelection.auto()],
      repeats: 1,
      strategyOverride: strategyOverride,
    );
    final run = result.profileRuns.first;
    final findings = <_Finding>[];
    _appendFailingPlannerFindings(findings, result);

    final offensiveGoals = [
      for (final goal in result.strategicPlan.warGoals)
        if (goal.kind != WarGoalKind.defend) goal,
    ];
    if (offensiveGoals.isEmpty) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message:
              'Fortified wake-up scenario generated no offensive war goal.',
        ),
      );
    } else if (!offensiveGoals.any(
      (goal) => goal.assignedUnitIds.contains(fortifiedUnitId),
    )) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message: 'Fortified unit was not assigned to an offensive war goal.',
        ),
      );
    }

    final commands = run.plan.commands;
    final hasWakeCommand = commands.any(
      (command) =>
          command is CancelUnitActionCommand &&
          command.unitId == fortifiedUnitId,
    );
    if (!hasWakeCommand) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message:
              'AI did not emit CancelUnitActionCommand for an offensive '
              'fortified unit.',
        ),
      );
    }

    final firstFortifiedCommand = _firstCommandForUnit(
      commands,
      fortifiedUnitId,
    );
    if (firstFortifiedCommand != null &&
        firstFortifiedCommand is! CancelUnitActionCommand) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'First command for fortified unit was '
              '${_describeCommand(firstFortifiedCommand)} instead of wake-up.',
        ),
      );
    }
    if (commands.any(
      (command) =>
          command is MoveUnitCommand && command.unitId == fortifiedUnitId,
    )) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message:
              'AI planned a direct move for a fortified unit in the same '
              'turn it should only wake it.',
        ),
      );
    }

    final wakeTransition = _reduceSyntheticCommand(
      prepared,
      const CancelUnitActionCommand(fortifiedUnitId),
    );
    final woken = _unitByIdOrNull(wakeTransition.state.units, fortifiedUnitId);
    if (woken == null) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message: 'Fortified unit disappeared after wake-up command.',
        ),
      );
    } else {
      if (woken.posture != UnitPosture.active) {
        findings.add(
          _Finding(
            severity: 'fail',
            message:
                'Wake-up command left fortified unit in ${woken.posture.name} '
                'posture.',
          ),
        );
      }
      if (woken.movementPoints <= 0) {
        findings.add(
          const _Finding(
            severity: 'fail',
            message: 'Wake-up command did not restore movement points.',
          ),
        );
      }
    }

    if (run.execution.rejectedCommands.isNotEmpty) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'Synthetic fortified wake-up plan had '
              '${run.execution.rejectedCommands.length} rejected command(s).',
        ),
      );
    }

    final warGoalSummaries = [
      for (final goal in result.strategicPlan.warGoals) _warGoalSummary(goal),
    ];
    return _SyntheticScenarioReport(
      id: 'fortified_offensive_wakeup',
      name: 'Fortified offensive wake-up',
      description:
          'A fortified military unit assigned to a non-defensive war goal must '
          'wake before any movement order.',
      details: {
        'strategy': result.effectiveStrategyId.name,
        'warGoals': warGoalSummaries,
        'plannedCommands': [
          for (final command in commands.take(8)) _describeCommand(command),
        ],
        'wokenUnit': woken == null
            ? null
            : {
                'posture': woken.posture.name,
                'movementPoints': woken.movementPoints,
              },
      },
      markdownDetails: [
        'Strategy: `${result.effectiveStrategyId.name}`',
        'War goals: `${warGoalSummaries.join(', ')}`',
        'Commands: ${commands.take(5).map(_describeCommand).join('; ')}',
        if (woken != null)
          'Woken unit: `${woken.posture.name}`, movement ${woken.movementPoints}',
      ],
      findings: findings,
    );
  }
}

class _SyntheticScenarioReport {
  const _SyntheticScenarioReport({
    required this.id,
    required this.name,
    required this.description,
    required this.details,
    required this.markdownDetails,
    required this.findings,
  });

  final String id;
  final String name;
  final String description;
  final Map<String, Object?> details;
  final List<String> markdownDetails;
  final List<_Finding> findings;

  bool get hasFailingFindings {
    return findings.any((finding) => finding.severity == 'fail');
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'details': details,
      'findings': [for (final finding in findings) finding.toJson()],
    };
  }
}
