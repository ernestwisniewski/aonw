part of 'economy_simulation.dart';

final class _EconomySimulationTurnRowFactory {
  const _EconomySimulationTurnRowFactory();

  EconomySimulationTurnRow rowFor({
    required int turn,
    required DomainState state,
    required String playerId,
    required MapReadView mapView,
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
    final unitSupply = _unitSupplyForPlayer(state, playerId, mapView, ruleset);
    final goldBreakdown = _goldBreakdownForPlayer(
      state: state,
      playerId: playerId,
      mapView: mapView,
      ruleset: ruleset,
    );
    final researchProjectScience = _researchProjectScienceForPlayer(
      state: state,
      playerId: playerId,
      mapView: mapView,
      ruleset: ruleset,
    );
    final baseScience = _baseScienceForPlayer(state, playerId, ruleset);
    return EconomySimulationTurnRow(
      turn: turn,
      cityCount: ownCities.length,
      unitCount: ownUnits.length,
      unitSupplyCapacity: unitSupply.capacity,
      unitSupplyUsed: unitSupply.used,
      unitSupplyAvailable: unitSupply.available,
      militaryCount: ownUnits
          .where(
            (unit) => const AiMilitaryAssessment().canServeAsMilitaryUnit(
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

  CityUnitSupplyBreakdown _unitSupplyForPlayer(
    DomainState state,
    String playerId,
    MapReadView mapView,
    GameRuleset ruleset,
  ) {
    return CityUnitSupplyRules.forPlayer(
      playerId: playerId,
      cities: state.cities,
      units: state.units,
      artifacts: state.artifacts,
      fieldImprovements: state.fieldImprovements,
      mapView: mapView,
      cityRuleset: ruleset.city,
      research: state.research,
      technologyRuleset: ruleset.technology,
    );
  }

  int _baseScienceForPlayer(
    DomainState state,
    String playerId,
    GameRuleset ruleset,
  ) {
    return ScienceYieldCalculator.totalForPlayer(
      playerId: playerId,
      cities: state.cities,
      research: state.research,
      ruleset: ruleset.technology,
      artifacts: state.artifacts,
      cityRuleset: ruleset.city,
      wonderRegistry: state.wonderRegistry,
      wonderRuleset: ruleset.wonders,
    ).total;
  }

  _GoldBreakdown _goldBreakdownForPlayer({
    required DomainState state,
    required String playerId,
    required MapReadView mapView,
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
        mapView: mapView,
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
    required DomainState state,
    required String playerId,
    required MapReadView mapView,
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
          mapView: mapView,
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
    required DomainState state,
    required MapReadView mapView,
    required GameRuleset ruleset,
    required TechnologyEffectSummary technologyEffects,
  }) {
    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapView,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: ruleset.city,
    );
    return CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapTiles: mapView,
      ruleset: ruleset.city,
      paceBalance: ruleset.paceBalance,
      technologyEffects: technologyEffects,
      cities: state.cities,
      wonderRegistry: state.wonderRegistry,
      wonderRuleset: ruleset.wonders,
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
    return cities
        .where((city) => city.productionQueue?.projectType == projectType)
        .length;
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
