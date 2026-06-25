part of 'defensive_stance_planner.dart';

class _DefensiveStancePlanningEngine {
  const _DefensiveStancePlanningEngine({required this.threatRange});

  final int threatRange;

  DefensiveStancePlan compute({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required List<PlayerThreatScore> threats,
    required StrategicMode mode,
  }) {
    if (view.ownCities.isEmpty || threatRange <= 0) {
      return DefensiveStancePlan.empty;
    }

    final threatProfiles = _DefenseThreatProfileCollector(
      threatRange: threatRange,
    ).collect(view: view, context: context, threats: threats);
    final garrisonPool = _GarrisonPool.fromView(view);
    const policy = _DefenseAssignmentPolicy();
    final committedUnitIds = <String>{};
    final assignments = <String, StrategicDefenseAssignment>{};
    final flexibleDefenseBudget = policy.flexibleDefenseBudget(
      view: view,
      assessment: assessment,
      threats: threats,
      mode: mode,
    );
    var flexibleAssignedCount = 0;

    for (final threat in threatProfiles) {
      final urgent = policy.isUrgentThreat(
        threat,
        offensivePressure: flexibleDefenseBudget != null,
      );
      final neededCount = policy.neededGarrisonCount(threat, mode);
      final remainingFlexible = flexibleDefenseBudget == null
          ? neededCount
          : flexibleDefenseBudget - flexibleAssignedCount;
      if (!urgent && remainingFlexible <= 0) continue;

      final requestedCount = urgent
          ? neededCount
          : math.min(neededCount, remainingFlexible);
      if (requestedCount <= 0) continue;

      final assigned = garrisonPool.nearestAvailable(
        city: threat.city,
        committedUnitIds: committedUnitIds,
        neededCount: requestedCount,
      );
      committedUnitIds.addAll(assigned.map((unit) => unit.id));
      if (!urgent) flexibleAssignedCount += requestedCount;
      assignments[threat.city.id] = _assignmentForThreat(threat, assigned);
    }

    _assignBaselineGarrisons(
      view: view,
      context: context,
      assessment: assessment,
      threats: threats,
      mode: mode,
      policy: policy,
      garrisonPool: garrisonPool,
      committedUnitIds: committedUnitIds,
      assignments: assignments,
    );

    if (assignments.isEmpty) return DefensiveStancePlan.empty;
    return DefensiveStancePlan(defenses: assignments);
  }

  void _assignBaselineGarrisons({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required List<PlayerThreatScore> threats,
    required StrategicMode mode,
    required _DefenseAssignmentPolicy policy,
    required _GarrisonPool garrisonPool,
    required Set<String> committedUnitIds,
    required Map<String, StrategicDefenseAssignment> assignments,
  }) {
    final baselineGarrisonCount = policy.baselineGarrisonCount(
      view: view,
      context: context,
      assessment: assessment,
      threats: threats,
      mode: mode,
    );
    if (baselineGarrisonCount <= 0) return;

    final homeCities = [...view.ownCities]
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final city in homeCities.take(baselineGarrisonCount)) {
      if (assignments.containsKey(city.id)) continue;
      final assigned = garrisonPool.nearestAvailable(
        city: city,
        committedUnitIds: committedUnitIds,
        neededCount: 1,
      );
      committedUnitIds.addAll(assigned.map((unit) => unit.id));
      assignments[city.id] = _baselineAssignment(city, assigned);
    }
  }

  StrategicDefenseAssignment _assignmentForThreat(
    _CityThreatProfile threat,
    List<GameUnit> assigned,
  ) {
    return StrategicDefenseAssignment(
      cityId: threat.city.id,
      cityCenter: threat.city.center,
      threatLevel: threat.threatLevel,
      primaryThreatPlayerId: threat.primaryThreatPlayerId,
      assignedUnitIds: assigned.map((unit) => unit.id),
    );
  }

  StrategicDefenseAssignment _baselineAssignment(
    GameCity city,
    List<GameUnit> assigned,
  ) {
    return StrategicDefenseAssignment(
      cityId: city.id,
      cityCenter: city.center,
      threatLevel: 0,
      primaryThreatPlayerId: '',
      assignedUnitIds: assigned.map((unit) => unit.id),
    );
  }
}
