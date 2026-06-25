part of 'war_goal_generator.dart';

final class _WarGoalGenerationRequest {
  const _WarGoalGenerationRequest({
    required this.view,
    required this.context,
    required this.assessment,
    required this.threats,
    required this.mode,
    required this.maxGoals,
    required this.reservedUnitIds,
    required this.citySitePlan,
    required this.targetabilityScorer,
  });

  final GameView view;
  final AiContext context;
  final AiEmpireAssessment assessment;
  final List<PlayerThreatScore> threats;
  final StrategicMode mode;
  final int maxGoals;
  final Set<String> reservedUnitIds;
  final CitySitePlan? citySitePlan;
  final TargetabilityScorer targetabilityScorer;

  bool get hasMinimumInputs =>
      maxGoals > 0 && threats.isNotEmpty && view.ownUnits.isNotEmpty;

  bool get boxedInExpansion {
    return _WarGoalCampaignPolicy.isBoxedInExpansion(
      view: view,
      assessment: assessment,
      citySitePlan: citySitePlan,
    );
  }

  double get aggression {
    return context.civProfile.belligerence *
        context.effectiveWeights.aggression;
  }
}

final class _WarGoalTargetPlan {
  const _WarGoalTargetPlan({
    required this.targetability,
    required this.orderedTargets,
    required this.boxedInExpansion,
    required this.request,
  });

  final List<TargetabilityScore> targetability;
  final List<TargetabilityScore> orderedTargets;
  final bool boxedInExpansion;
  final _WarGoalGenerationRequest request;

  factory _WarGoalTargetPlan.fromRequest(_WarGoalGenerationRequest request) {
    final boxedInExpansion = request.boxedInExpansion;
    final targetability = _targetabilityFor(request);
    final orderedTargets = _WarGoalTargetOrdering(
      request: request,
      boxedInExpansion: boxedInExpansion,
    ).order(targetability);

    return _WarGoalTargetPlan(
      targetability: targetability,
      orderedTargets: orderedTargets,
      boxedInExpansion: boxedInExpansion,
      request: request,
    );
  }

  bool get canGenerateGoals {
    return targetability.isNotEmpty &&
        _WarGoalCampaignPolicy(request).allowsGoals(
          targetability: targetability,
          boxedInExpansion: boxedInExpansion,
        );
  }

  static List<TargetabilityScore> _targetabilityFor(
    _WarGoalGenerationRequest request,
  ) {
    return [
      for (final target in request.targetabilityScorer.rank(
        assessment: request.assessment,
        rivals: [for (final threat in request.threats) threat.rival],
        context: request.context,
        priorityTargetPlayerIds: {
          ...request.view.activeHostilePlayerIds,
          ...request.view.pressureTargetPlayerIds,
        },
      ))
        if (request.view.canTargetPlayer(target.playerId)) target,
    ];
  }
}

final class _WarGoalTargetOrdering {
  const _WarGoalTargetOrdering({
    required this.request,
    required this.boxedInExpansion,
  });

  final _WarGoalGenerationRequest request;
  final bool boxedInExpansion;

  List<TargetabilityScore> order(List<TargetabilityScore> targetability) {
    final activePriorityTargets = [
      for (final target in targetability)
        if (target.priorityTarget && target.rival.isHostile) target,
    ];
    if (activePriorityTargets.isNotEmpty) return activePriorityTargets;
    if (boxedInExpansion) return _boxedExpansionOrder(targetability);
    return targetability;
  }

  List<TargetabilityScore> _boxedExpansionOrder(
    List<TargetabilityScore> targetability,
  ) {
    final cityTargets = [
      for (final target in targetability)
        if (_WarGoalMapQueries.nearestRememberedCityForBoxedExpansion(
              request.view,
              target.playerId,
            ) !=
            null)
          target,
    ];
    if (cityTargets.isEmpty) return targetability;

    cityTargets.sort((a, b) {
      final distanceCompare = _boxedExpansionTargetDistance(
        a,
      ).compareTo(_boxedExpansionTargetDistance(b));
      if (distanceCompare != 0) return distanceCompare;
      final militaryCompare = a.relativeMilitary.compareTo(b.relativeMilitary);
      if (militaryCompare != 0) return militaryCompare;
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.playerId.compareTo(b.playerId);
    });
    return List.unmodifiable(cityTargets);
  }

  int _boxedExpansionTargetDistance(TargetabilityScore target) {
    final city = _WarGoalMapQueries.nearestRememberedCityForBoxedExpansion(
      request.view,
      target.playerId,
    );
    if (city == null) return 99;
    return _WarGoalMapQueries.nearestExpansionAnchorDistance(
      request.view,
      city.center.toCoordinate(),
    );
  }
}
