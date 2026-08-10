part of 'city_production_dialog_view_model.dart';

extension CityProductionDialogViewModelQueries
    on CityProductionDialogViewModel {
  bool get hasItems =>
      buildings.isNotEmpty ||
      futureBuildings.isNotEmpty ||
      wonders.isNotEmpty ||
      units.isNotEmpty ||
      projects.isNotEmpty ||
      specializations.isNotEmpty;

  CityProductionItem? get activeItem {
    for (final item in [
      ...buildings,
      ...futureBuildings,
      ...wonders,
      ...units,
      ...projects,
    ]) {
      if (item.active) return item;
    }
    return null;
  }

  CityProductionItem? itemForBuilding(CityBuildingType? buildingType) {
    if (buildingType == null) return null;
    for (final item in [...buildings, ...futureBuildings]) {
      if (item.buildingType == buildingType) return item;
    }
    return null;
  }

  CityProductionItem? itemForUnit(GameUnitType? unitType) {
    if (unitType == null) return null;
    for (final item in units) {
      if (item.unitType == unitType) return item;
    }
    return null;
  }

  CityProductionItem? itemForWonder(WonderType? wonderType) {
    if (wonderType == null) return null;
    for (final item in wonders) {
      if (item.wonderType == wonderType) return item;
    }
    return null;
  }
}
