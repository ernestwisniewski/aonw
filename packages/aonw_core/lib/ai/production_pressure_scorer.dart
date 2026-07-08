part of 'production_scorer.dart';

double _essentialProductionPressure(
  AiEmpireAssessment assessment,
  AiProductionPlanState planState,
) {
  final workerDeficit = (assessment.desiredWorkerCount - planState.workerCount)
      .clamp(0, 4)
      .toDouble();
  final needsDefenseCoverage =
      planState.militaryCount > 0 || assessment.visibleEnemyMilitaryCount > 0;
  final defenseCoverageDeficit = needsDefenseCoverage
      ? (assessment.cityCount - planState.militaryCount).clamp(0, 4).toDouble()
      : 0.0;
  return workerDeficit * 3.0 + defenseCoverageDeficit * 2.5;
}

double _stableSecondCityExpansionPressure(
  AiEmpireAssessment assessment,
  AiProductionPlanState planState,
) {
  if (!assessment.wantsExpansion) return 0;
  if (assessment.cityCount != 1 || planState.settlerCount > 0) return 0;
  if (planState.militaryCount < 2) return 0;
  if (assessment.netGoldPerTurn < -2) return 0;
  if (assessment.enemyMilitaryPressure) {
    return planState.militaryCount >= 3 ? 18.0 : 0.0;
  }
  return 22.0;
}

double _stableThirdCityExpansionPressure(
  AiEmpireAssessment assessment,
  AiProductionPlanState planState,
) {
  if (!assessment.wantsExpansion) return 0;
  if (assessment.cityCount != 2 || planState.settlerCount > 0) return 0;
  if (planState.militaryCount < assessment.cityCount) return 0;
  if (assessment.enemyMilitaryPressure) return 0;
  if (assessment.netGoldPerTurn < 0) return 0;

  final expansionDeficit = (assessment.desiredCityCount - assessment.cityCount)
      .clamp(0, 4)
      .toDouble();
  final workerCoverageDeficit = (assessment.cityCount - planState.workerCount)
      .clamp(0, 2)
      .toDouble();
  return 13.0 + expansionDeficit * 1.5 - workerCoverageDeficit * 2.0;
}
