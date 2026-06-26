part of 'hud_command_dispatcher.dart';

extension HudCommandDispatcherCityResearch on HudCommandDispatcher {
  Future<void> startCityBuilding(String cityId, CityBuildingType buildingType) {
    return _closeCityProductionAndDispatch(
      HudCityProductionCommands.startBuilding(cityId, buildingType),
    );
  }

  Future<void> startCityUnitProduction(String cityId, GameUnitType unitType) {
    return _closeCityProductionAndDispatch(
      HudCityProductionCommands.startUnitProduction(cityId, unitType),
    );
  }

  Future<void> startCityProject(String cityId, CityProjectType projectType) {
    return _closeCityProductionAndDispatch(
      HudCityProductionCommands.startProject(cityId, projectType),
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
    if (activePlayerId.isEmpty) return Future.value();
    final modes = _ref.read(hudPanelControllerProvider);
    if (modes.technology) {
      _applyPanelModes(modes.closeTechnology(), playSound: false);
    }
    return dispatch(SelectTechnologyCommand(activePlayerId, technologyId));
  }

  Future<void> _closeCityProductionAndDispatch(GameCommand command) {
    closeCityProductionPanel(playSound: false);
    return dispatch(command);
  }
}
