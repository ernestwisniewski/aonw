class CityProgression {
  final int startPopulation;
  final int startStoredFood;
  final int startMaxHexes;
  final int midGameMaxHexes;
  final int lateGameMaxHexes;
  final int startTerritoryRadius;
  final int expandedTerritoryRadius;
  final int foodUpkeepPerPopulation;
  final int growthBaseCost;
  final int growthCostPerPopulation;
  final int growthCostPerControlledHex;
  final int workedHexLimitBase;
  final int workedHexesPerPopulation;

  const CityProgression({
    required this.startPopulation,
    required this.startStoredFood,
    required this.startMaxHexes,
    required this.midGameMaxHexes,
    required this.lateGameMaxHexes,
    required this.startTerritoryRadius,
    required this.expandedTerritoryRadius,
    required this.foodUpkeepPerPopulation,
    required this.growthBaseCost,
    required this.growthCostPerPopulation,
    required this.growthCostPerControlledHex,
    this.workedHexLimitBase = 0,
    this.workedHexesPerPopulation = 1,
  });

  int growthCost({required int population, required int territoryHexCount}) {
    return growthBaseCost +
        growthCostPerPopulation * population +
        growthCostPerControlledHex * territoryHexCount;
  }

  int foodUpkeepForPopulation(int population) {
    return population * foodUpkeepPerPopulation;
  }

  int workedHexLimitForPopulation(int population) {
    final limit = workedHexLimitBase + population * workedHexesPerPopulation;
    return limit < 0 ? 0 : limit;
  }
}
