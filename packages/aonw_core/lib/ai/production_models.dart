import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/unit_roles.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/unit.dart';

class AiProductionPlanState {
  final bool hasPlannedResearch;
  final int workerCount;
  final int settlerCount;
  final int militaryCount;
  final int reconCount;
  final int reservedUnitSupply;
  final int wealthProjectCount;
  final int researchProjectCount;

  const AiProductionPlanState({
    required this.hasPlannedResearch,
    required this.workerCount,
    required this.settlerCount,
    required this.militaryCount,
    required this.reconCount,
    this.reservedUnitSupply = 0,
    this.wealthProjectCount = 0,
    this.researchProjectCount = 0,
  });

  factory AiProductionPlanState.fromAssessment(
    AiEmpireAssessment assessment, {
    required bool hasPlannedResearch,
    Iterable<GameCity> cities = const [],
    int reconCount = 0,
  }) {
    return AiProductionPlanState(
      hasPlannedResearch: hasPlannedResearch,
      workerCount: assessment.workerCount,
      settlerCount: assessment.settlerCount,
      militaryCount: assessment.militaryCount,
      reconCount: reconCount,
      wealthProjectCount: _projectQueueCount(cities, CityProjectType.wealth),
      researchProjectCount: _projectQueueCount(
        cities,
        CityProjectType.research,
      ),
    );
  }

  bool get hasResearchTarget => hasPlannedResearch;

  AiProductionPlanState after(CityProductionTarget target) {
    return switch (target) {
      UnitProductionTarget(:final unitType) => _afterUnit(unitType),
      BuildingProductionTarget() => this,
      ProjectProductionTarget(:final projectType) => _afterProject(projectType),
    };
  }

  AiProductionPlanState afterReplacing(
    CityProductionTarget? previous,
    CityProductionTarget target,
  ) {
    final withoutPrevious = switch (previous) {
      ProjectProductionTarget(:final projectType) => _withoutProject(
        projectType,
      ),
      _ => this,
    };
    return withoutPrevious.after(target);
  }

  AiProductionPlanState _afterUnit(GameUnitType unitType) {
    return AiProductionPlanState(
      hasPlannedResearch: hasPlannedResearch,
      workerCount: workerCount + (unitType == GameUnitType.worker ? 1 : 0),
      settlerCount: settlerCount + (unitType == GameUnitType.settler ? 1 : 0),
      militaryCount:
          militaryCount + (AiUnitRoles.isMilitaryType(unitType) ? 1 : 0),
      reconCount: reconCount + (AiUnitRoles.isReconType(unitType) ? 1 : 0),
      reservedUnitSupply:
          reservedUnitSupply + CityUnitSupplyRules.supplyCostForType(unitType),
      wealthProjectCount: wealthProjectCount,
      researchProjectCount: researchProjectCount,
    );
  }

  AiProductionPlanState _afterProject(CityProjectType projectType) {
    return AiProductionPlanState(
      hasPlannedResearch: hasPlannedResearch,
      workerCount: workerCount,
      settlerCount: settlerCount,
      militaryCount: militaryCount,
      reconCount: reconCount,
      reservedUnitSupply: reservedUnitSupply,
      wealthProjectCount:
          wealthProjectCount + (projectType == CityProjectType.wealth ? 1 : 0),
      researchProjectCount:
          researchProjectCount +
          (projectType == CityProjectType.research ? 1 : 0),
    );
  }

  AiProductionPlanState _withoutProject(CityProjectType projectType) {
    return AiProductionPlanState(
      hasPlannedResearch: hasPlannedResearch,
      workerCount: workerCount,
      settlerCount: settlerCount,
      militaryCount: militaryCount,
      reconCount: reconCount,
      reservedUnitSupply: reservedUnitSupply,
      wealthProjectCount: projectType == CityProjectType.wealth
          ? (wealthProjectCount - 1).clamp(0, 1 << 30).toInt()
          : wealthProjectCount,
      researchProjectCount: projectType == CityProjectType.research
          ? (researchProjectCount - 1).clamp(0, 1 << 30).toInt()
          : researchProjectCount,
    );
  }
}

class AiProductionRecommendation {
  final String cityId;
  final CityProductionTarget target;
  final double score;
  final String reason;

  const AiProductionRecommendation({
    required this.cityId,
    required this.target,
    required this.score,
    required this.reason,
  });
}

int _projectQueueCount(Iterable<GameCity> cities, CityProjectType projectType) {
  return cities
      .where(
        (city) =>
            city.productionQueue?.target ==
            ProjectProductionTarget(projectType),
      )
      .length;
}
