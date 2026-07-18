import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/mcts/mcts_simulated_command_application.dart';
import 'package:aonw_core/ai/mcts/mcts_simulation_projection.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class MctsSimulatedEconomyCommandApplier {
  MctsSimulatedEconomyCommandApplier({
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
    final result = CityFoundingCommandResolver.foundCity(
      units: [...ownUnits, ...visibleEnemyUnits],
      cities: [...ownCities, ...rememberedEnemyCities],
      cityFoundingDraft: null,
      command: command,
      actorPlayerId: view.forPlayerId,
      mapTiles: view.mapData,
    );
    if (!result.accepted) return unchangedCommandApplication;
    return (
      nextOwnUnits: List<GameUnit>.unmodifiable(
        result.units.take(ownUnits.length),
      ),
      nextVisibleEnemyUnits: visibleEnemyUnits,
      nextOwnCities: ownCities,
      nextRememberedEnemyCities: rememberedEnemyCities,
      nextOwnResearch: ownResearch,
    );
  }

  PlayerResearchState applySelectTechnology(SelectTechnologyCommand command) {
    final result = SelectTechnologyResolver.selectTechnology(
      research: _researchState,
      cities: ownCities,
      fieldImprovements: view.ownImprovements,
      command: command,
      actorPlayerId: view.forPlayerId,
      mapTiles: view.mapData,
      ruleset: view.ruleset.technology,
      // Preserve the current MCTS approximation; pace convergence is a
      // separate, behavior-changing fix with its own characterization.
      paceBalance: PaceBalance.unlimited,
    );
    return result.accepted
        ? result.research.forPlayer(command.playerId)
        : ownResearch;
  }

  MctsSimulatedCommandApplication applySelectWorkerImprovement(
    SelectWorkerImprovementCommand command,
  ) {
    final result = const PersistentWorkerCommandResolver()
        .selectWorkerImprovement(
          state: _persistentState(),
          command: command,
          actorPlayerId: view.forPlayerId,
          mapTiles: view.mapData,
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
      mapTiles: view.mapData,
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
      mapTiles: view.mapData,
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
      mapTiles: view.mapData,
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
      mapTiles: view.mapData,
    )) {
      return ownCities;
    }
    final hasSupply = CityUnitSupplyRules.canQueueUnit(
      playerId: city.ownerPlayerId,
      unitType: command.unitType,
      cities: ownCities,
      units: ownUnits,
      artifacts: view.artifacts,
      fieldImprovements: view.ownImprovements,
      mapView: view.mapData,
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
    final result = CityProductionCommandResolver.startCityProject(
      cities: ownCities,
      command: command,
      actorPlayerId: view.forPlayerId,
      cityRuleset: view.ruleset.city,
      paceBalance: view.ruleset.paceBalance,
    );
    return result.accepted ? result.cities : ownCities;
  }

  List<GameCity> applySetCitySpecialization(
    SetCitySpecializationCommand command,
  ) {
    final result = CityProductionCommandResolver.setCitySpecialization(
      cities: ownCities,
      research: _researchState,
      command: command,
      actorPlayerId: view.forPlayerId,
    );
    return result.accepted ? result.cities : ownCities;
  }

  MctsSimulatedCommandApplication get unchangedCommandApplication => (
    nextOwnUnits: ownUnits,
    nextVisibleEnemyUnits: visibleEnemyUnits,
    nextOwnCities: ownCities,
    nextRememberedEnemyCities: rememberedEnemyCities,
    nextOwnResearch: ownResearch,
  );

  ResearchState get _researchState {
    return view.research.updatePlayer(view.forPlayerId, ownResearch);
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
}
