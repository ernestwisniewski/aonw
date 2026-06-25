part of 'war_goal_generator.dart';

final class _WarGoalCampaignPolicy {
  const _WarGoalCampaignPolicy(this.request);

  final _WarGoalGenerationRequest request;

  bool allowsGoals({
    required List<TargetabilityScore> targetability,
    required bool boxedInExpansion,
  }) {
    if (request.mode == StrategicMode.military) return true;
    if (targetability.first.rival.isHostile) return true;
    if (boxedInExpansion) return true;
    if (_shouldFinishOpeningExpansionBeforeWar(targetability.first)) {
      return false;
    }
    if (_shouldPressurePriorityTarget(targetability.first)) return true;

    final difficultyProfile = request.context.difficultyProfile;
    final opportunityThreshold =
        2.2 *
        difficultyProfile.warOpportunityThresholdMultiplier /
        request.aggression;
    return request.aggression >= 1.35 &&
        _hasArmyReadyForOpportunisticWar &&
        targetability.first.score >= opportunityThreshold;
  }

  static bool isBoxedInExpansion({
    required GameView view,
    required AiEmpireAssessment assessment,
    required CitySitePlan? citySitePlan,
  }) {
    if (view.ownCities.isEmpty) return false;
    if (!_hasActiveFounder(view)) return false;
    if (!assessment.wantsExpansion && assessment.settlerCount <= 0) {
      return false;
    }
    if ((citySitePlan?.candidates.isNotEmpty ?? false)) return false;

    final nearestEnemyCityDistance =
        _WarGoalMapQueries.nearestRememberedEnemyCityDistance(view);
    return nearestEnemyCityDistance != null && nearestEnemyCityDistance <= 6;
  }

  bool get _hasArmyReadyForOpportunisticWar {
    return request.assessment.militaryCount >=
        math.max(1, (request.assessment.desiredMilitaryCount * 0.8).ceil());
  }

  bool _shouldFinishOpeningExpansionBeforeWar(TargetabilityScore target) {
    final assessment = request.assessment;
    if (assessment.cityCount <= 0 || assessment.cityCount >= 3) return false;
    if (!assessment.wantsExpansion || assessment.settlerCount > 0) {
      return false;
    }
    if (target.rival.recentlyHostile) return false;
    if (target.priorityTarget &&
        assessment.militaryCount >= assessment.desiredMilitaryCount + 1) {
      return false;
    }

    final safeSurplus =
        assessment.desiredMilitaryCount +
        request.context.difficultyProfile.openingWarSurplus;
    return assessment.militaryCount < safeSurplus;
  }

  bool _shouldPressurePriorityTarget(TargetabilityScore target) {
    return _PriorityTargetPressurePolicy(request).canPressure(target);
  }

  static bool _hasActiveFounder(GameView view) {
    return view.ownUnits.any(
      (unit) =>
          CityFoundingRules.canFoundCityWith(unit) &&
          !unit.isWorking &&
          unit.queuedPath == null,
    );
  }
}

final class _WarGoalKindPolicy {
  const _WarGoalKindPolicy(this.request);

  final _WarGoalGenerationRequest request;

  WarGoalKind kindFor({
    required TargetabilityScore target,
    required GameCity? city,
  }) {
    final priorityPressure = _PriorityTargetPressurePolicy(request);
    final priorityPressureReady = priorityPressure.canPressure(target);
    final counterAttackReady = _canCounterAttackHostile(target);

    if (_canCaptureForBoxedExpansion(target, city)) {
      return WarGoalKind.captureCity;
    }
    if (_shouldDefendAgainstHostile(
      target: target,
      counterAttackReady: counterAttackReady,
      priorityPressureReady: priorityPressureReady,
    )) {
      return WarGoalKind.defend;
    }
    if (_shouldHoldRecentHostilePressure(target: target, city: city)) {
      return WarGoalKind.defend;
    }
    if (_shouldDefendAgainstStrongerHostile(
      target: target,
      counterAttackReady: counterAttackReady,
      priorityPressureReady: priorityPressureReady,
    )) {
      return WarGoalKind.defend;
    }
    if (_canAttemptCityCapture(
      target: target,
      city: city,
      counterAttackReady: counterAttackReady,
      priorityPressureReady: priorityPressureReady,
    )) {
      return WarGoalKind.captureCity;
    }
    if (target.rival.visibleMilitaryCount > 0) {
      return WarGoalKind.eliminateUnits;
    }
    return city == null ? WarGoalKind.defend : WarGoalKind.harass;
  }

  bool _canCaptureForBoxedExpansion(TargetabilityScore target, GameCity? city) {
    if (!request.boxedInExpansion || city == null) return false;
    if (request.aggression < 0.85) return false;

    final minimumArmy = math.max(3, request.assessment.cityCount + 2);
    if (request.assessment.militaryCount < minimumArmy) return false;

    final maximumRelativeMilitary = request.mode == StrategicMode.military
        ? 1.8
        : 1.55;
    return target.relativeMilitary <= maximumRelativeMilitary;
  }

  bool _shouldDefendAgainstHostile({
    required TargetabilityScore target,
    required bool counterAttackReady,
    required bool priorityPressureReady,
  }) {
    return target.rival.isHostile &&
        !counterAttackReady &&
        !priorityPressureReady &&
        (request.assessment.cityCount <= 1 || !_hasArmySurplus);
  }

  bool _shouldHoldRecentHostilePressure({
    required TargetabilityScore target,
    required GameCity? city,
  }) {
    return target.rival.recentlyHostile &&
        target.rival.visibleMilitaryCount == 0 &&
        city == null;
  }

  bool _shouldDefendAgainstStrongerHostile({
    required TargetabilityScore target,
    required bool counterAttackReady,
    required bool priorityPressureReady,
  }) {
    return target.rival.isHostile &&
        !counterAttackReady &&
        !priorityPressureReady &&
        target.relativeMilitary > 1.35;
  }

  bool _canAttemptCityCapture({
    required TargetabilityScore target,
    required GameCity? city,
    required bool counterAttackReady,
    required bool priorityPressureReady,
  }) {
    final canReachCity =
        city != null &&
        target.relativeMilitary <= _maximumCaptureRelativeMilitary(target);
    return canReachCity &&
        (request.aggression >= 1.05 ||
            priorityPressureReady ||
            (counterAttackReady && request.aggression >= 0.8));
  }

  double _maximumCaptureRelativeMilitary(TargetabilityScore target) {
    if (request.mode == StrategicMode.military) {
      return target.priorityTarget && target.rival.isHostile ? 2.1 : 1.55;
    }
    if (target.priorityTarget) {
      return target.rival.isHostile ? 1.6 : 1.25;
    }
    return 1.1;
  }

  bool _canCounterAttackHostile(TargetabilityScore target) {
    if (!target.rival.recentlyHostile) return false;
    if (request.assessment.militaryCount <
        math.max(2, request.assessment.cityCount + 1)) {
      return false;
    }
    return target.relativeMilitary <= 0.75;
  }

  bool get _hasArmySurplus {
    return request.assessment.militaryCount >
        request.assessment.desiredMilitaryCount;
  }
}

final class _PriorityTargetPressurePolicy {
  const _PriorityTargetPressurePolicy(this.request);

  final _WarGoalGenerationRequest request;

  bool canPressure(TargetabilityScore target) {
    if (!target.priorityTarget) return false;
    if (request.assessment.cityCount <= 0) return false;
    if (request.assessment.settlerCount > 0 &&
        request.assessment.cityCount < 2) {
      return false;
    }
    if (request.assessment.militaryCount < minimumArmy) return false;
    return target.relativeMilitary <= _maximumRelativeMilitary(target);
  }

  int get minimumArmy => math.max(2, request.assessment.cityCount);

  double _maximumRelativeMilitary(TargetabilityScore target) {
    if (request.mode == StrategicMode.military) {
      return target.rival.isHostile ? 2.25 : 1.55;
    }
    return target.rival.isHostile ? 1.75 : 1.25;
  }
}

abstract final class _WarGoalUnitAllocator {
  static List<GameUnit> availableMilitaryUnits(
    _WarGoalGenerationRequest request,
  ) {
    return [
      for (final unit in request.view.ownUnits)
        if (!request.reservedUnitIds.contains(unit.id) &&
            _isAvailableMilitaryUnit(unit, request.view.ruleset.combat))
          unit,
    ]..sort((a, b) => a.id.compareTo(b.id));
  }

  static List<GameUnit> assignedUnitsForGoal({
    required _WarGoalGenerationRequest request,
    required List<GameUnit> availableUnits,
    required Set<String> committedUnits,
    required bool priorityTarget,
  }) {
    final remaining = [
      for (final unit in availableUnits)
        if (!committedUnits.contains(unit.id)) unit,
    ];
    if (remaining.isEmpty) return const [];

    final share = _assignmentShare(
      request: request,
      priorityTarget: priorityTarget,
    );
    final count = math.max(1, (remaining.length * share).ceil());
    return remaining.take(count).toList(growable: false);
  }

  static double _assignmentShare({
    required _WarGoalGenerationRequest request,
    required bool priorityTarget,
  }) {
    final baseShare = priorityTarget
        ? (request.mode == StrategicMode.military ? 0.82 : 0.62)
        : (request.mode == StrategicMode.military ? 0.72 : 0.48);
    return (baseShare + (request.aggression - 1.0) * 0.12)
        .clamp(0.35, 0.85)
        .toDouble();
  }

  static bool _isAvailableMilitaryUnit(GameUnit unit, CombatRuleset ruleset) {
    return !unit.isWorker &&
        unit.type != GameUnitType.settler &&
        !unit.hasSettlers &&
        !unit.isWorking &&
        unit.queuedPath == null &&
        _isMilitaryUnit(unit, ruleset);
  }

  static bool _isMilitaryUnit(GameUnit unit, CombatRuleset ruleset) {
    final stats = UnitCombatStats.derive(unit, ruleset: ruleset);
    return stats.attack > 0 || stats.defense > 0;
  }
}
