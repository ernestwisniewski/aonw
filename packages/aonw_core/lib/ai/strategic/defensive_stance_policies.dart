part of 'defensive_stance_planner.dart';

class _DefenseAssignmentPolicy {
  const _DefenseAssignmentPolicy();

  int neededGarrisonCount(_CityThreatProfile threat, StrategicMode mode) {
    if (mode == StrategicMode.military && threat.threatLevel >= 18) return 2;
    if (threat.threatLevel >= 24) return 2;
    return 1;
  }

  bool isUrgentThreat(
    _CityThreatProfile threat, {
    required bool offensivePressure,
  }) {
    if (threat.urgent) return true;
    if (offensivePressure) return false;
    return threat.threatLevel >= 36;
  }

  int? flexibleDefenseBudget({
    required GameView view,
    required AiEmpireAssessment assessment,
    required List<PlayerThreatScore> threats,
    required StrategicMode mode,
  }) {
    if (!_hasOffensivePressure(view, threats)) return null;
    if (assessment.militaryCount <= 0) return null;

    final cityCount = view.ownCities.length;
    if (cityCount <= 2) return null;

    final cityDivisor = mode == StrategicMode.military ? 2 : 3;
    final armyShare = mode == StrategicMode.military ? 0.25 : 0.2;
    final visibleThreatBudget = math.max(
      1,
      (assessment.visibleEnemyMilitaryCount / 2).ceil() + 1,
    );
    final armyBudget = math.max(
      1,
      (assessment.militaryCount * armyShare).floor(),
    );
    final cityBudget = math.max(1, (cityCount / cityDivisor).ceil());
    return math.min(cityBudget, math.min(visibleThreatBudget, armyBudget));
  }

  int baselineGarrisonCount({
    required GameView view,
    required AiContext context,
    required AiEmpireAssessment assessment,
    required List<PlayerThreatScore> threats,
    required StrategicMode mode,
  }) {
    final cityCount = view.ownCities.length;
    if (cityCount == 0) return 0;
    if (cityCount == 1) {
      if (context.turn <= 40) return 1;
      if (mode != StrategicMode.military) return 1;
      return assessment.militaryCount <= cityCount + 1 ? 1 : 0;
    }
    if (cityCount == 2) {
      if (context.turn <= 60) return 2;
      if (assessment.visibleEnemyMilitaryCount > 0) return 2;
      if (threats.any((threat) => threat.rival.recentlyHostile)) return 2;
      if (mode == StrategicMode.military &&
          assessment.militaryCount <= cityCount + 1) {
        return 2;
      }
      if (mode != StrategicMode.military &&
          context.effectiveWeights.aggression < 0.95) {
        return 2;
      }
    }
    return 0;
  }

  bool _hasOffensivePressure(GameView view, List<PlayerThreatScore> threats) {
    return view.activeHostilePlayerIds.isNotEmpty ||
        view.pressureTargetPlayerIds.isNotEmpty ||
        view.recentHostilePlayerIds.isNotEmpty ||
        threats.any((threat) => threat.rival.isHostile);
  }
}

bool _isMilitaryUnit(GameUnit unit, CombatRuleset ruleset) {
  final stats = UnitCombatStats.derive(unit, ruleset: ruleset);
  return stats.attack > 0 || stats.defense > 0;
}
