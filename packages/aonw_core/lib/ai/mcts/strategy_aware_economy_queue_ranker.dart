part of 'strategy_aware_economy_ranker.dart';

final class _EconomyQueueRanker {
  const _EconomyQueueRanker();

  CommandRanking? rankBuilding(
    StartBuildingCommand command,
    StrategicMode mode,
  ) {
    final buildingType = command.buildingType;
    return switch (mode) {
      StrategicMode.military when isMilitaryBuilding(buildingType) =>
        const CommandRanking(CandidatePriority.cityRole, 540),
      StrategicMode.techRush when isScienceBuilding(buildingType) =>
        const CommandRanking(CandidatePriority.cityRole, 560),
      StrategicMode.recover when isEconomicBuilding(buildingType) =>
        const CommandRanking(CandidatePriority.cityRole, 540),
      StrategicMode.consolidate when isEconomicBuilding(buildingType) =>
        const CommandRanking(CandidatePriority.cityRole, 520),
      StrategicMode.expand when isGrowthBuilding(buildingType) =>
        const CommandRanking(CandidatePriority.cityRole, 520),
      _ => null,
    };
  }

  CommandRanking? rankProject(
    StartCityProjectCommand command,
    StrategicMode mode,
  ) {
    return switch ((mode, command.projectType)) {
      (StrategicMode.techRush, CityProjectType.research) =>
        const CommandRanking(CandidatePriority.cityRole, 520),
      (StrategicMode.recover, CityProjectType.wealth) => const CommandRanking(
        CandidatePriority.cityRole,
        500,
      ),
      (StrategicMode.consolidate, CityProjectType.wealth) =>
        const CommandRanking(CandidatePriority.cityRole, 480),
      _ => null,
    };
  }
}
