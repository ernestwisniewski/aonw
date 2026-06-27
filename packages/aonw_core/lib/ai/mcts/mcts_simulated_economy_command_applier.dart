import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_command_application.dart';
import 'package:aonw_core/ai/mcts/mcts_simulation_projection.dart';
import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class MctsSimulatedEconomyCommandApplier {
  const MctsSimulatedEconomyCommandApplier({
    required this.view,
    required this.ownUnits,
    required this.visibleEnemyUnits,
    required this.ownCities,
    required this.rememberedEnemyCities,
    required this.ownResearch,
  });

  final GameView view;
  final List<GameUnit> ownUnits;
  final List<GameUnit> visibleEnemyUnits;
  final List<GameCity> ownCities;
  final List<GameCity> rememberedEnemyCities;
  final PlayerResearchState ownResearch;

  MctsSimulatedCommandApplication applyFoundCity(FoundCityCommand command) {
    final result = const PersistentCityFoundingResolver().foundCity(
      state: _persistentState(),
      command: command,
      actorPlayerId: view.forPlayerId,
      mapDefinition: _mapDefinition(),
      cityRuleset: view.ruleset.city,
    );
    if (!result.accepted) return unchangedCommandApplication;
    return _applicationFromPersistent(result.state);
  }

  PlayerResearchState applySelectTechnology(SelectTechnologyCommand command) {
    if (command.playerId != view.forPlayerId) return ownResearch;

    final availability = TechnologyAvailabilityService.availabilityFor(
      technologyId: command.technologyId,
      playerResearch: ownResearch,
      ruleset: view.ruleset.technology,
    );
    if (availability != TechnologyAvailability.available) return ownResearch;

    return ResearchOverflowRules.applyToSelectedTechnology(
      playerId: command.playerId,
      playerResearch: ownResearch,
      technologyId: command.technologyId,
      cities: ownCities,
      fieldImprovements: view.ownImprovements,
      mapData: view.mapData,
      ruleset: view.ruleset.technology,
    );
  }

  MctsSimulatedCommandApplication applySelectWorkerImprovement(
    SelectWorkerImprovementCommand command,
  ) {
    final result = const PersistentWorkerCommandResolver()
        .selectWorkerImprovement(
          state: _persistentState(),
          command: command,
          actorPlayerId: view.forPlayerId,
          mapDefinition: _mapDefinition(),
          cityRuleset: view.ruleset.city,
          technologyRuleset: view.ruleset.technology,
          paceBalance: view.ruleset.paceBalance,
        );
    if (!result.accepted) return unchangedCommandApplication;
    return _applicationFromPersistent(result.state);
  }

  MctsSimulatedCommandApplication applyAssignWorkerToHex(
    AssignWorkerToHexCommand command,
  ) {
    final result = const PersistentWorkerCommandResolver().assignWorkerToHex(
      state: _persistentState(),
      command: command,
      actorPlayerId: view.forPlayerId,
      mapDefinition: _mapDefinition(),
    );
    if (!result.accepted) return unchangedCommandApplication;
    return _applicationFromPersistent(result.state);
  }

  List<GameCity> applyStartBuilding(StartBuildingCommand command) {
    final lookup = _cityLookup(command.cityId);
    if (lookup == null) return ownCities;
    final (:cityIndex, :city) = lookup;

    final technologyUnlocked = TechnologyUnlockQuery.hasBuildingUnlocked(
      playerId: city.ownerPlayerId,
      buildingType: command.buildingType,
      research: _researchState,
      ruleset: view.ruleset.technology,
    );
    final requirementsMet = CityBuildingRequirementRules.meetsRequirements(
      city: city,
      buildingType: command.buildingType,
      mapData: view.mapData,
      ruleset: view.ruleset.city,
      research: _researchState,
    );
    if (!CityProductionRules.canBuild(
      city.buildings,
      command.buildingType,
      ruleset: view.ruleset.city,
      technologyUnlocked: technologyUnlocked,
      requirementsMet: requirementsMet,
    )) {
      return ownCities;
    }

    return _replaceCity(
      cityIndex,
      _queueProduction(city, BuildingProductionTarget(command.buildingType)),
    );
  }

  List<GameCity> applyStartUnitProduction(StartUnitProductionCommand command) {
    final lookup = _cityLookup(command.cityId);
    if (lookup == null) return ownCities;
    final (:cityIndex, :city) = lookup;

    final technologyUnlocked = TechnologyUnlockQuery.hasUnitUnlocked(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      research: _researchState,
      ruleset: view.ruleset.technology,
    );
    final requirementsMet = UnitProductionRequirementRules.meetsRequirements(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      cities: ownCities,
      mapData: view.mapData,
      ruleset: view.ruleset.city,
      research: _researchState,
    );
    if (!CityProductionRules.canProduceUnit(
      command.unitType,
      ruleset: view.ruleset.city,
      technologyUnlocked: technologyUnlocked,
      requirementsMet: requirementsMet,
    )) {
      return ownCities;
    }
    if (!CityUnitProductionRules.canProduceInCity(
      city: city,
      unitType: command.unitType,
      mapData: view.mapData,
    )) {
      return ownCities;
    }
    final hasSupply = CityUnitSupplyRules.canQueueUnit(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      cities: ownCities,
      units: ownUnits,
      fieldImprovements: view.ownImprovements,
      mapData: view.mapData,
      cityRuleset: view.ruleset.city,
      research: _researchState,
      technologyRuleset: view.ruleset.technology,
      replacingCityId: city.id,
    );
    if (!hasSupply) return ownCities;

    return _replaceCity(
      cityIndex,
      _queueProduction(city, UnitProductionTarget(command.unitType)),
    );
  }

  List<GameCity> applyStartCityProject(StartCityProjectCommand command) {
    final lookup = _cityLookup(command.cityId);
    if (lookup == null) return ownCities;
    final (:cityIndex, :city) = lookup;
    return _replaceCity(
      cityIndex,
      _queueProduction(city, ProjectProductionTarget(command.projectType)),
    );
  }

  List<GameCity> applySetCitySpecialization(
    SetCitySpecializationCommand command,
  ) {
    final lookup = _cityLookup(command.cityId);
    if (lookup == null) return ownCities;
    final (:cityIndex, :city) = lookup;
    if (!_researchState
        .forPlayer(city.ownerPlayerId)
        .hasUnlocked(TechnologyId.specialization)) {
      return ownCities;
    }
    if (city.specialization == command.specialization) return ownCities;
    if (!CitySpecializationRules.hasRequiredBuilding(
      city.buildings,
      command.specialization,
    )) {
      return ownCities;
    }

    return _replaceCity(
      cityIndex,
      city.copyWith(specialization: command.specialization),
    );
  }

  MctsSimulatedCommandApplication get unchangedCommandApplication => (
    nextOwnUnits: ownUnits,
    nextVisibleEnemyUnits: visibleEnemyUnits,
    nextOwnCities: ownCities,
    nextRememberedEnemyCities: rememberedEnemyCities,
    nextOwnResearch: ownResearch,
  );

  ResearchState get _researchState {
    return ResearchState(players: {view.forPlayerId: ownResearch});
  }

  ({int cityIndex, GameCity city})? _cityLookup(String cityId) {
    for (var i = 0; i < ownCities.length; i++) {
      final city = ownCities[i];
      if (city.id == cityId) return (cityIndex: i, city: city);
    }
    return null;
  }

  List<GameCity> _replaceCity(int index, GameCity updated) {
    return [
      for (var i = 0; i < ownCities.length; i++)
        if (i == index) updated else ownCities[i],
    ];
  }

  GameCity _queueProduction(GameCity city, CityProductionTarget target) {
    final activeInvestment = city.productionQueue?.investedProduction;
    final rolloverInvestment = activeInvestment == null
        ? CityProductionRules.rolloverInvestment(
            storedOverflow: city.productionOverflow,
            productionCost: CityProductionRules.targetCost(
              target,
              ruleset: view.ruleset.city,
              paceBalance: view.ruleset.paceBalance,
            ),
          )
        : 0;
    return city.copyWith(
      productionQueue: CityProductionQueue.target(
        target: target,
        investedProduction: activeInvestment ?? rolloverInvestment,
      ),
      productionOverflow: activeInvestment == null
          ? 0
          : city.productionOverflow,
    );
  }

  PersistentGameState _persistentState() {
    return MctsSimulationProjection.persistentStateFromView(
      view,
      units: [...ownUnits, ...visibleEnemyUnits],
      cities: [...ownCities, ...rememberedEnemyCities],
      research: _researchState,
    );
  }

  MctsSimulatedCommandApplication _applicationFromPersistent(
    PersistentGameState state,
  ) {
    final nextView = GameView.fromPersistentState(
      state,
      forPlayerId: view.forPlayerId,
      turn: view.turn,
      mapData: view.mapData,
      ruleset: view.ruleset,
      activeHostilePlayerIds: view.activeHostilePlayerIds,
      recentHostilePlayerIds: view.recentHostilePlayerIds,
      pressureTargetPlayerIds: view.pressureTargetPlayerIds,
      defaultNeutralPlayerIds: view.defaultNeutralPlayerIds,
      pendingCityAttackThreats: view.pendingCityAttackThreats,
      ignoreFogOfWar: !view.visibility.isEnabled,
    );
    return (
      nextOwnUnits: nextView.ownUnits,
      nextVisibleEnemyUnits: nextView.visibleEnemyUnits,
      nextOwnCities: nextView.ownCities,
      nextRememberedEnemyCities: nextView.rememberedEnemyCities,
      nextOwnResearch: nextView.ownResearch,
    );
  }

  MapDefinition _mapDefinition() {
    return MctsSimulationProjection.mapDefinitionFrom(view.mapData);
  }
}
