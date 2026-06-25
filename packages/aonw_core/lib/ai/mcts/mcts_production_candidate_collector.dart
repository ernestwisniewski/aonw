import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class MctsProductionCandidateCollector {
  const MctsProductionCandidateCollector();

  Iterable<GameCommand> commandsFor(GameView view) sync* {
    final cities = [...view.citiesWithReassignableProduction]
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final city in cities) {
      for (final unitType in _unitCandidateOrder) {
        if (!_canProduceUnit(view, city: city, unitType: unitType)) continue;
        yield StartUnitProductionCommand(city.id, unitType);
      }

      for (final buildingType in _buildingCandidateOrder) {
        if (!_canBuild(view, city: city, buildingType: buildingType)) continue;
        yield StartBuildingCommand(city.id, buildingType);
      }

      for (final projectType in CityProjectType.values) {
        if (city.productionQueue?.target ==
            ProjectProductionTarget(projectType)) {
          continue;
        }
        yield StartCityProjectCommand(city.id, projectType);
      }
    }
  }

  bool _canProduceUnit(
    GameView view, {
    required GameCity city,
    required GameUnitType unitType,
  }) {
    final research = _researchFor(view);
    final technologyUnlocked = TechnologyUnlockQuery.hasUnitUnlocked(
      playerId: view.forPlayerId,
      unitType: unitType,
      research: research,
      ruleset: view.ruleset.technology,
    );
    final requirementsMet = UnitProductionRequirementRules.meetsRequirements(
      playerId: view.forPlayerId,
      unitType: unitType,
      cities: view.ownCities,
      mapData: view.mapData,
      ruleset: view.ruleset.city,
      research: research,
    );
    if (!CityProductionRules.canProduceUnit(
      unitType,
      ruleset: view.ruleset.city,
      technologyUnlocked: technologyUnlocked,
      requirementsMet: requirementsMet,
    )) {
      return false;
    }
    if (!CityUnitProductionRules.canProduceInCity(
      city: city,
      unitType: unitType,
      mapData: view.mapData,
    )) {
      return false;
    }
    return CityUnitSupplyRules.canQueueUnit(
      playerId: view.forPlayerId,
      unitType: unitType,
      cities: view.ownCities,
      units: view.ownUnits,
      fieldImprovements: view.ownImprovements,
      mapData: view.mapData,
      cityRuleset: view.ruleset.city,
      research: research,
      technologyRuleset: view.ruleset.technology,
      replacingCityId: city.id,
    );
  }

  bool _canBuild(
    GameView view, {
    required GameCity city,
    required CityBuildingType buildingType,
  }) {
    final research = _researchFor(view);
    final technologyUnlocked = TechnologyUnlockQuery.hasBuildingUnlocked(
      playerId: view.forPlayerId,
      buildingType: buildingType,
      research: research,
      ruleset: view.ruleset.technology,
    );
    final requirementsMet = CityBuildingRequirementRules.meetsRequirements(
      city: city,
      buildingType: buildingType,
      mapData: view.mapData,
      ruleset: view.ruleset.city,
      research: research,
    );
    return CityProductionRules.canBuild(
      city.buildings,
      buildingType,
      ruleset: view.ruleset.city,
      technologyUnlocked: technologyUnlocked,
      requirementsMet: requirementsMet,
    );
  }
}

ResearchState _researchFor(GameView view) {
  return ResearchState(players: {view.forPlayerId: view.ownResearch});
}

const _unitCandidateOrder = [
  GameUnitType.worker,
  GameUnitType.warrior,
  GameUnitType.archer,
  GameUnitType.settler,
  GameUnitType.commander,
  GameUnitType.scout,
  GameUnitType.spearman,
  GameUnitType.cavalry,
  GameUnitType.catapult,
  GameUnitType.heavyInfantry,
  GameUnitType.fieldCannon,
  GameUnitType.rifleman,
  GameUnitType.tank,
  GameUnitType.scoutShip,
  GameUnitType.warship,
  GameUnitType.reconPlane,
];

const _buildingCandidateOrder = CityBuildingType.values;
