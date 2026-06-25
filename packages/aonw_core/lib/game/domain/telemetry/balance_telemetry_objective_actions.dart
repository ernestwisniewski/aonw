part of 'balance_telemetry.dart';

abstract final class BalanceTelemetryObjectiveActionDiagnostics {
  static Map<String, BalanceTelemetryObjectiveActionSample>
  scorePressureSamplesFor({
    required PersistentGameState state,
    required Iterable<String> playerIds,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    final breakdownByPlayerId = _scoreBreakdownsFor(
      state: state,
      playerIds: playerIds,
    );
    if (breakdownByPlayerId.isEmpty) return const {};

    const advisor = ScorePressureAdvisor();
    return {
      for (final playerId in breakdownByPlayerId.keys)
        playerId: sampleFor(
          state: state,
          playerId: playerId,
          advice: advisor.adviceFor(
            playerId: playerId,
            breakdownByPlayerId: breakdownByPlayerId,
          ),
          technologyRuleset: technologyRuleset,
        ),
    };
  }

  static BalanceTelemetryObjectiveActionSample sampleFor({
    required PersistentGameState state,
    required String playerId,
    required GameObjectiveAdvice advice,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    return BalanceTelemetryObjectiveActionSample(
      advice: advice,
      target: targetFor(
        state: state,
        playerId: playerId,
        advice: advice,
        technologyRuleset: technologyRuleset,
      ),
    );
  }

  static BalanceTelemetryObjectiveActionTarget targetFor({
    required PersistentGameState state,
    required String playerId,
    required GameObjectiveAdvice advice,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
  }) {
    for (final candidate in _objectiveActionTargetCandidates(
      state: state,
      playerId: playerId,
      advice: advice,
      technologyRuleset: technologyRuleset,
    )) {
      if (candidate.matches) return candidate.target;
    }
    return BalanceTelemetryObjectiveActionTarget.none;
  }

  static Map<String, EmpireScoreBreakdown> _scoreBreakdownsFor({
    required PersistentGameState state,
    required Iterable<String> playerIds,
  }) {
    return {
      for (final playerId in _orderedDistinctPlayerIds(playerIds))
        playerId: const EmpireScoreCalculator().scoreFor(
          playerId: playerId,
          state: state,
        ),
    };
  }

  static Iterable<_ObjectiveActionTargetCandidate>
  _objectiveActionTargetCandidates({
    required PersistentGameState state,
    required String playerId,
    required GameObjectiveAdvice advice,
    required TechnologyRuleset technologyRuleset,
  }) sync* {
    yield _ObjectiveActionTargetCandidate(
      target: BalanceTelemetryObjectiveActionTarget.unit,
      matches: _hasMatchingUnit(
        state: state,
        playerId: playerId,
        advice: advice,
      ),
    );
    yield _ObjectiveActionTargetCandidate(
      target: BalanceTelemetryObjectiveActionTarget.cityProduction,
      matches:
          _hasCityWithoutProduction(state: state, playerId: playerId) &&
          _cityActionMatchesAdvice(advice),
    );
    yield _ObjectiveActionTargetCandidate(
      target: BalanceTelemetryObjectiveActionTarget.research,
      matches:
          _needsResearchSelection(
            state: state,
            playerId: playerId,
            technologyRuleset: technologyRuleset,
          ) &&
          _researchActionMatchesAdvice(advice),
    );
  }

  static bool _hasMatchingUnit({
    required PersistentGameState state,
    required String playerId,
    required GameObjectiveAdvice advice,
  }) {
    return state.units.any(
      (unit) =>
          _needsManualUnitAction(unit, playerId) &&
          _unitActionMatchesAdvice(unit, advice),
    );
  }

  static bool _needsManualUnitAction(GameUnit unit, String playerId) {
    return unit.ownerPlayerId == playerId &&
        !unit.isWorking &&
        !unit.isAutoExploring &&
        unit.movementPoints > 0 &&
        unit.queuedPath == null;
  }

  static bool _unitActionMatchesAdvice(
    GameUnit unit,
    GameObjectiveAdvice advice,
  ) {
    return switch (advice) {
      GameObjectiveAdvice.improveField => unit.type == GameUnitType.worker,
      GameObjectiveAdvice.foundCity ||
      GameObjectiveAdvice.claimTerritory => unit.type == GameUnitType.settler,
      GameObjectiveAdvice.trainUnit || GameObjectiveAdvice.protectLead =>
        UnitCombatStats.derive(unit).attack > 0,
      _ => false,
    };
  }

  static bool _hasCityWithoutProduction({
    required PersistentGameState state,
    required String playerId,
  }) {
    return state.cities.any(
      (city) => city.ownerPlayerId == playerId && city.productionQueue == null,
    );
  }

  static bool _cityActionMatchesAdvice(GameObjectiveAdvice advice) {
    return switch (advice) {
      GameObjectiveAdvice.constructBuilding ||
      GameObjectiveAdvice.trainUnit ||
      GameObjectiveAdvice.foundCity ||
      GameObjectiveAdvice.growPopulation ||
      GameObjectiveAdvice.improveField ||
      GameObjectiveAdvice.claimTerritory ||
      GameObjectiveAdvice.collectGold ||
      GameObjectiveAdvice.protectLead => true,
      GameObjectiveAdvice.unlockTechnology => false,
    };
  }

  static bool _needsResearchSelection({
    required PersistentGameState state,
    required String playerId,
    required TechnologyRuleset technologyRuleset,
  }) {
    final playerResearch = state.research.forPlayer(playerId);
    return playerResearch.activeTechnologyId == null &&
        technologyRuleset.technologies.keys.any(
          (technologyId) =>
              TechnologyAvailabilityService.availabilityFor(
                technologyId: technologyId,
                playerResearch: playerResearch,
                ruleset: technologyRuleset,
              ) ==
              TechnologyAvailability.available,
        );
  }

  static bool _researchActionMatchesAdvice(GameObjectiveAdvice advice) {
    return switch (advice) {
      GameObjectiveAdvice.unlockTechnology ||
      GameObjectiveAdvice.protectLead => true,
      _ => false,
    };
  }
}

class _ObjectiveActionTargetCandidate {
  const _ObjectiveActionTargetCandidate({
    required this.target,
    required this.matches,
  });

  final BalanceTelemetryObjectiveActionTarget target;
  final bool matches;
}
