part of 'economy_simulation.dart';

final class _EconomySimulationTurnRowFactory {
  const _EconomySimulationTurnRowFactory();

  EconomySimulationTurnRow rowFor({
    required int turn,
    required PersistentGameState state,
    required String playerId,
    required MapData mapData,
    required GameRuleset ruleset,
    required EconomySimulationCommandStats commandStats,
    required DominationProgressEntry? domination,
    required BalanceTelemetryObjectiveActionSample? objectiveAction,
  }) {
    final ownUnits = [
      for (final unit in state.units)
        if (unit.ownerPlayerId == playerId) unit,
    ];
    final ownCities = [
      for (final city in state.cities)
        if (city.ownerPlayerId == playerId) city,
    ];
    final research = state.research.forPlayer(playerId);
    final unitSupply = CityUnitSupplyRules.forPlayer(
      playerId: playerId,
      cities: state.cities,
      units: state.units,
      fieldImprovements: state.fieldImprovements,
      mapData: mapData,
      cityRuleset: ruleset.city,
      research: state.research,
      technologyRuleset: ruleset.technology,
    );
    final goldBreakdown = _goldBreakdownForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      ruleset: ruleset,
    );
    final researchProjectScience = _researchProjectScienceForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      ruleset: ruleset,
    );
    final baseScience = ScienceYieldCalculator.totalForPlayer(
      playerId: playerId,
      cities: state.cities,
      research: state.research,
      ruleset: ruleset.technology,
      cityRuleset: ruleset.city,
    ).total;
    return EconomySimulationTurnRow(
      turn: turn,
      cityCount: ownCities.length,
      unitCount: ownUnits.length,
      unitSupplyCapacity: unitSupply.capacity,
      unitSupplyUsed: unitSupply.used,
      unitSupplyAvailable: unitSupply.available,
      militaryCount: ownUnits
          .where(
            (unit) => _militaryAssessment.canServeAsMilitaryUnit(
              unit,
              ruleset.combat,
            ),
          )
          .length,
      settlerCount: _unitCount(ownUnits, GameUnitType.settler),
      workerCount: _unitCount(ownUnits, GameUnitType.worker),
      warriorCount: _unitCount(ownUnits, GameUnitType.warrior),
      archerCount: _unitCount(ownUnits, GameUnitType.archer),
      gold: state.playerGold[playerId] ?? 0,
      cityGoldIncome: goldBreakdown.cityGoldIncome,
      wealthProjectGold: goldBreakdown.wealthProjectGold,
      unitUpkeep: goldBreakdown.unitUpkeep,
      netGoldPerTurn: goldBreakdown.netGoldPerTurn,
      sciencePerTurn: baseScience + researchProjectScience,
      researchProjectScience: researchProjectScience,
      completedTechCount: research.unlockedTechnologyIds.length,
      activeTechnology: research.activeTechnologyId?.name ?? '',
      unlockedTechnologies:
          (research.unlockedTechnologyIds.toList()
                ..sort((a, b) => a.name.compareTo(b.name)))
              .map((technology) => technology.name)
              .join(';'),
      buildingQueues: ownCities.where(_hasBuildingQueue).length,
      unitQueues: ownCities.where(_hasUnitQueue).length,
      projectQueues: ownCities.where(_hasProjectQueue).length,
      wealthProjectQueues: _projectQueueCount(
        ownCities,
        CityProjectType.wealth,
      ),
      researchProjectQueues: _projectQueueCount(
        ownCities,
        CityProjectType.research,
      ),
      foundCityCommands: commandStats.foundCity,
      startUnitCommands: commandStats.startUnit,
      startBuildingCommands: commandStats.startBuilding,
      startProjectCommands: commandStats.startProject,
      workerJobCommands: commandStats.workerJob,
      moveCommands: commandStats.move,
      attackCommands: commandStats.attack,
      rejectedCommands: commandStats.rejected,
      objectiveActionAdvice: objectiveAction?.advice.name ?? '',
      objectiveActionTarget: objectiveAction?.target.name ?? '',
      dominationControlPercent: domination?.controlPercent ?? 0,
      dominationHoldTurns: domination?.holdTurns ?? 0,
      dominationRequiredControlPercent:
          domination?.requiredControlPercent ??
          MatchRules.standard.victory.dominationControlPercent,
      dominationRequiredHoldTurns:
          domination?.requiredHoldTurns ??
          MatchRules.standard.victory.dominationHoldTurns,
    );
  }

  _GoldBreakdown _goldBreakdownForPlayer({
    required PersistentGameState state,
    required String playerId,
    required MapData mapData,
    required GameRuleset ruleset,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: playerId,
      research: state.research,
      ruleset: ruleset.technology,
    );
    var cityGoldIncome = 0;
    var wealthProjectGold = 0;
    for (final city in state.cities) {
      if (city.ownerPlayerId != playerId) continue;
      final economy = _economyFor(
        city: city,
        state: state,
        mapData: mapData,
        ruleset: ruleset,
        technologyEffects: technologyEffects,
      );
      cityGoldIncome += economy.netYield.gold < 0 ? 0 : economy.netYield.gold;
      if (city.productionQueue?.target case ProjectProductionTarget(
        projectType: CityProjectType.wealth,
      )) {
        wealthProjectGold += CityProjectRules.outputFor(
          type: CityProjectType.wealth,
          productionPerTurn: CityProductionRules.productionPerTurn(
            economy.netYield.production,
          ),
        );
      }
    }
    final upkeep = UnitUpkeepRules.forPlayer(
      playerId: playerId,
      units: state.units,
      cities: state.cities,
    );
    return _GoldBreakdown(
      cityGoldIncome: cityGoldIncome,
      wealthProjectGold: wealthProjectGold,
      unitUpkeep: upkeep.total,
    );
  }

  int _researchProjectScienceForPlayer({
    required PersistentGameState state,
    required String playerId,
    required MapData mapData,
    required GameRuleset ruleset,
  }) {
    var total = 0;
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: playerId,
      research: state.research,
      ruleset: ruleset.technology,
    );
    for (final city in state.cities) {
      if (city.ownerPlayerId != playerId) continue;
      if (city.productionQueue?.target case ProjectProductionTarget(
        projectType: CityProjectType.research,
      )) {
        final economy = _economyFor(
          city: city,
          state: state,
          mapData: mapData,
          ruleset: ruleset,
          technologyEffects: technologyEffects,
        );
        total += CityProjectRules.outputFor(
          type: CityProjectType.research,
          productionPerTurn: CityProductionRules.productionPerTurn(
            economy.netYield.production,
          ),
        );
      }
    }
    return total;
  }

  CityEconomyBreakdown _economyFor({
    required GameCity city,
    required PersistentGameState state,
    required MapData mapData,
    required GameRuleset ruleset,
    required TechnologyEffectSummary technologyEffects,
  }) {
    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapData,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      ruleset: ruleset.city,
    );
    return CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapData: mapData,
      ruleset: ruleset.city,
      paceBalance: ruleset.paceBalance,
      technologyEffects: technologyEffects,
    );
  }

  int _unitCount(List<GameUnit> units, GameUnitType type) {
    return units.where((unit) => unit.type == type).length;
  }

  bool _hasBuildingQueue(GameCity city) {
    return city.productionQueue?.target is BuildingProductionTarget;
  }

  bool _hasUnitQueue(GameCity city) {
    return city.productionQueue?.target is UnitProductionTarget;
  }

  bool _hasProjectQueue(GameCity city) {
    return city.productionQueue?.target is ProjectProductionTarget;
  }

  int _projectQueueCount(
    Iterable<GameCity> cities,
    CityProjectType projectType,
  ) {
    return cities.where((city) => _projectTypeFor(city) == projectType).length;
  }

  CityProjectType? _projectTypeFor(GameCity city) {
    return switch (city.productionQueue?.target) {
      ProjectProductionTarget(:final projectType) => projectType,
      _ => null,
    };
  }
}

class _GoldBreakdown {
  const _GoldBreakdown({
    required this.cityGoldIncome,
    required this.wealthProjectGold,
    required this.unitUpkeep,
  });

  final int cityGoldIncome;
  final int wealthProjectGold;
  final int unitUpkeep;

  int get netGoldPerTurn => cityGoldIncome + wealthProjectGold - unitUpkeep;
}
