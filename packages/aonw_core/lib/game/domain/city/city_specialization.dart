import 'package:aonw_core/game/domain/city/city_building.dart';
import 'package:aonw_core/game/domain/city/city_production_target.dart';
import 'package:aonw_core/game/domain/city/city_project_type.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/game/domain/unit/game_unit_type.dart';

enum CitySpecializationType {
  growth,
  industry,
  commerce,
  science,
  military;

  static CitySpecializationType fromString(String value) {
    return CitySpecializationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError('Unknown city specialization: $value'),
    );
  }
}

abstract final class CitySpecializationRules {
  static const int scienceSpecializationScience = 2;

  static CityBuildingType requiredBuildingFor(CitySpecializationType type) {
    return switch (type) {
      CitySpecializationType.growth => CityBuildingType.granary,
      CitySpecializationType.industry => CityBuildingType.workshop,
      CitySpecializationType.commerce => CityBuildingType.merchantHall,
      CitySpecializationType.science => CityBuildingType.archive,
      CitySpecializationType.military => CityBuildingType.barracks,
    };
  }

  static bool hasRequiredBuilding(
    Set<CityBuildingType> buildings,
    CitySpecializationType type,
  ) {
    return buildings.contains(requiredBuildingFor(type));
  }

  static TileYield yieldFor(CitySpecializationType? specialization) {
    return switch (specialization) {
      CitySpecializationType.growth => const TileYield(
        food: 2,
        production: 0,
        gold: 0,
        defense: 0,
      ),
      CitySpecializationType.industry => const TileYield(
        food: 0,
        production: 2,
        gold: 0,
        defense: 0,
      ),
      CitySpecializationType.commerce => const TileYield(
        food: 0,
        production: 0,
        gold: 3,
        defense: 0,
      ),
      CitySpecializationType.science => TileYield.zero,
      CitySpecializationType.military => const TileYield(
        food: 0,
        production: 1,
        gold: 0,
        defense: 2,
      ),
      null => TileYield.zero,
    };
  }

  static int scienceFor(CitySpecializationType? specialization) {
    return specialization == CitySpecializationType.science
        ? scienceSpecializationScience
        : 0;
  }

  static int productionPerTurnForTarget({
    required int productionPerTurn,
    required CityProductionTarget target,
    required CitySpecializationType? specialization,
  }) {
    if (productionPerTurn <= 0) return 0;
    final boosted = switch ((specialization, target)) {
      (CitySpecializationType.growth, UnitProductionTarget(:final unitType))
          when unitType == GameUnitType.worker ||
              unitType == GameUnitType.settler =>
        true,
      (CitySpecializationType.industry, BuildingProductionTarget()) => true,
      (
        CitySpecializationType.commerce,
        ProjectProductionTarget(:final projectType),
      )
          when projectType == CityProjectType.wealth =>
        true,
      (
        CitySpecializationType.science,
        ProjectProductionTarget(:final projectType),
      )
          when projectType == CityProjectType.research =>
        true,
      (CitySpecializationType.military, UnitProductionTarget()) => true,
      _ => false,
    };
    if (boosted) {
      return productionPerTurn + 1;
    }
    return productionPerTurn;
  }
}
