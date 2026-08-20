import 'package:aonw/game/presentation/widgets/hud/city/hud_city_production_commands.dart';
import 'package:aonw/game/presentation/widgets/hud/command/hud_command_dispatcher.dart';
import 'package:aonw/game/presentation/widgets/hud/panel/hud_panel_controller.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';

extension HudCommandDispatcherCityResearch on HudCommandDispatcher {
  Future<void> startCityBuilding(String cityId, CityBuildingType buildingType) {
    return _closeCityProductionAndDispatch(
      HudCityProductionCommands.startBuilding(cityId, buildingType),
    );
  }

  Future<void> startCityUnitProduction(
    String cityId,
    GameUnitType unitType, {
    int? resourceOptionIndex,
  }) {
    return _closeCityProductionAndDispatch(
      HudCityProductionCommands.startUnitProduction(
        cityId,
        unitType,
        resourceOptionIndex: resourceOptionIndex,
      ),
    );
  }

  Future<void> startCityProject(String cityId, CityProjectType projectType) {
    return _closeCityProductionAndDispatch(
      HudCityProductionCommands.startProject(cityId, projectType),
    );
  }

  Future<void> startCityWonder(String cityId, WonderType wonderType) {
    return _closeCityProductionAndDispatch(
      HudCityProductionCommands.startWonder(cityId, wonderType),
    );
  }

  Future<void> setCitySpecialization(
    String cityId,
    CitySpecializationType specialization,
  ) {
    return _closeCityProductionAndDispatch(
      HudCityProductionCommands.setSpecialization(cityId, specialization),
    );
  }

  Future<void> rushCityProduction(String cityId) {
    return _closeCityProductionAndDispatch(
      HudCityProductionCommands.rushProduction(cityId),
    );
  }

  Future<void> selectTechnology({
    required String activePlayerId,
    required TechnologyId technologyId,
  }) {
    if (activePlayerId.isEmpty || !canInteract) return Future.value();
    final modes = ref.read(hudPanelControllerProvider);
    if (modes.technology) {
      applyPanelModes(modes.closeTechnology(), playSound: false);
    }
    return dispatch(SelectTechnologyCommand(activePlayerId, technologyId));
  }

  Future<void> _closeCityProductionAndDispatch(DomainCommand command) {
    return dispatchTransition(command).then((result) {
      if (result.accepted) closeCityProductionPanel(playSound: false);
    });
  }
}
