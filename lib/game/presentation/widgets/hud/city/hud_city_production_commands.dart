import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class HudCityProductionCommands {
  static GameCommand startBuilding(
    String cityId,
    CityBuildingType buildingType,
  ) {
    return StartBuildingCommand(cityId, buildingType);
  }

  static GameCommand startUnitProduction(String cityId, GameUnitType unitType) {
    return StartUnitProductionCommand(cityId, unitType);
  }

  static GameCommand startProject(String cityId, CityProjectType projectType) {
    return StartCityProjectCommand(cityId, projectType);
  }

  static GameCommand setSpecialization(
    String cityId,
    CitySpecializationType specialization,
  ) {
    return SetCitySpecializationCommand(cityId, specialization);
  }

  static GameCommand rushProduction(String cityId) {
    return RushProductionCommand(cityId);
  }
}
