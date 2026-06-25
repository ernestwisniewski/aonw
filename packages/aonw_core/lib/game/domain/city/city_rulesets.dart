import 'package:aonw_core/game/domain/city/city_building_catalog.dart';
import 'package:aonw_core/game/domain/city/city_progression_catalog.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_yield_catalog.dart';
import 'package:aonw_core/game/domain/city/field_improvement_catalog.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class CityRulesets {
  static const standard = CityRuleset(
    progression: CityProgressionCatalog.standard,
    cityCenterYield: CityYieldCatalog.standardCityCenter,
    riverYield: CityYieldCatalog.standardRiver,
    terrainYields: CityYieldCatalog.standardTerrainYields,
    resourceYields: CityYieldCatalog.standardResourceYields,
    improvements: FieldImprovementCatalog.standard,
    buildings: CityBuildingCatalog.standard,
    units: UnitProductionCatalog.standard,
  );
}
