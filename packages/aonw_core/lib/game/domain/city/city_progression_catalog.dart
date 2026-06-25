import 'package:aonw_core/game/domain/city/city_progression.dart';

abstract final class CityProgressionCatalog {
  static const startPopulation = 3;
  static const startStoredFood = 0;
  static const startMaxHexes = 6;
  static const midGameMaxHexes = 8;
  static const lateGameMaxHexes = 10;
  static const startTerritoryRadius = 2;
  static const expandedTerritoryRadius = 3;
  static const foodUpkeepPerPopulation = 1;
  static const growthBaseCost = 10;
  static const growthCostPerPopulation = 4;
  static const growthCostPerControlledHex = 3;
  static const workedHexLimitBase = 0;
  static const workedHexesPerPopulation = 1;

  static const standard = CityProgression(
    startPopulation: startPopulation,
    startStoredFood: startStoredFood,
    startMaxHexes: startMaxHexes,
    midGameMaxHexes: midGameMaxHexes,
    lateGameMaxHexes: lateGameMaxHexes,
    startTerritoryRadius: startTerritoryRadius,
    expandedTerritoryRadius: expandedTerritoryRadius,
    foodUpkeepPerPopulation: foodUpkeepPerPopulation,
    growthBaseCost: growthBaseCost,
    growthCostPerPopulation: growthCostPerPopulation,
    growthCostPerControlledHex: growthCostPerControlledHex,
    workedHexLimitBase: workedHexLimitBase,
    workedHexesPerPopulation: workedHexesPerPopulation,
  );
}
