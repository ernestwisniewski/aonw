import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';

abstract final class HudCityProductionCommands {
  static DomainCommand startBuilding(
    String cityId,
    CityBuildingType buildingType,
  ) {
    return StartBuildingCommand(cityId, buildingType);
  }

  static DomainCommand startUnitProduction(
    String cityId,
    GameUnitType unitType,
  ) {
    return StartUnitProductionCommand(cityId, unitType);
  }

  static DomainCommand startProject(
    String cityId,
    CityProjectType projectType,
  ) {
    return StartCityProjectCommand(cityId, projectType);
  }

  static DomainCommand startWonder(String cityId, WonderType wonderType) {
    return StartWonderCommand(cityId, wonderType);
  }

  static DomainCommand setSpecialization(
    String cityId,
    CitySpecializationType specialization,
  ) {
    return SetCitySpecializationCommand(cityId, specialization);
  }

  static DomainCommand rushProduction(String cityId) {
    return RushProductionCommand(cityId);
  }
}
