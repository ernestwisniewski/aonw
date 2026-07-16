part of 'city_yield_breakdown_view_model.dart';

typedef _CityYieldAdjustments = ({
  TileYield goldMultiplierYield,
  TileYield wonderYield,
  TileYield stabilityYield,
  int consumedFoodUpkeep,
});

List<CityYieldBreakdownRow> _cityYieldRows({
  required GameCity city,
  required CityTileYieldBreakdown tileBreakdown,
  required CityEconomyBreakdown economy,
  required CityYieldBreakdownText text,
}) {
  final adjustments = _yieldAdjustmentsFor(
    tileBreakdown: tileBreakdown,
    economy: economy,
  );
  return List.unmodifiable([
    ..._tileSourceRows(tileBreakdown: tileBreakdown, text: text),
    ..._citySourceRows(
      city: city,
      economy: economy,
      wonderYield: adjustments.wonderYield,
      text: text,
    ),
    ..._modifierRows(
      city: city,
      economy: economy,
      adjustments: adjustments,
      text: text,
    ),
  ]);
}

List<CityYieldBreakdownRow> _tileSourceRows({
  required CityTileYieldBreakdown tileBreakdown,
  required CityYieldBreakdownText text,
}) {
  return [
    CityYieldBreakdownRow(
      label: text.center,
      detail: text.centerDetail,
      yield: tileBreakdown.centerYield,
    ),
    CityYieldBreakdownRow(
      label: text.populationFields,
      detail: text.workedHexDetail(tileBreakdown.population.length),
      yield: tileBreakdown.populationYield,
    ),
    CityYieldBreakdownRow(
      label: text.workers,
      detail: text.workerDetail(tileBreakdown.workers.length),
      yield: tileBreakdown.workerYield,
    ),
    CityYieldBreakdownRow(
      label: text.improvements,
      detail: text.passiveImprovementDetail(
        tileBreakdown.passiveImprovements.length,
      ),
      yield: tileBreakdown.passiveImprovementYield,
    ),
    if (!CityYieldBreakdownViewModel._isZero(tileBreakdown.artifactYield))
      CityYieldBreakdownRow(
        label: text.artifact,
        detail: text.artifactDetail,
        yield: tileBreakdown.artifactYield,
      ),
  ];
}

List<CityYieldBreakdownRow> _citySourceRows({
  required GameCity city,
  required CityEconomyBreakdown economy,
  required TileYield wonderYield,
  required CityYieldBreakdownText text,
}) {
  return [
    CityYieldBreakdownRow(
      label: text.buildings,
      detail: text.buildingDetail(city, economy.buildingYield),
      yield: economy.buildingYield,
    ),
    CityYieldBreakdownRow(
      label: text.technologies,
      detail: text.technologyDetail(economy.technologyYield),
      yield: economy.technologyYield,
    ),
    if (!CityYieldBreakdownViewModel._isZero(economy.specializationYield) ||
        city.specialization != null)
      CityYieldBreakdownRow(
        label: text.specialization,
        detail: text.specializationDetail(city.specialization),
        yield: economy.specializationYield,
      ),
    if (!CityYieldBreakdownViewModel._isZero(wonderYield))
      CityYieldBreakdownRow(
        label: text.wonders,
        detail: text.wonderDetail,
        yield: wonderYield,
      ),
  ];
}

List<CityYieldBreakdownRow> _modifierRows({
  required GameCity city,
  required CityEconomyBreakdown economy,
  required _CityYieldAdjustments adjustments,
  required CityYieldBreakdownText text,
}) {
  return [
    if (!CityYieldBreakdownViewModel._isZero(adjustments.goldMultiplierYield))
      CityYieldBreakdownRow(
        label: text.goldMultiplier,
        detail: text.goldMultiplierDetail,
        yield: adjustments.goldMultiplierYield,
      ),
    if (economy.stabilityModifier != StabilityModifier.stable)
      CityYieldBreakdownRow(
        label: text.stability,
        detail: text.stabilityDetail(economy.stabilityModifier),
        yield: adjustments.stabilityYield,
      ),
    if (economy.populationUpkeep != 0)
      CityYieldBreakdownRow(
        label: text.upkeep,
        detail: text.upkeepDetail(
          city: city,
          populationUpkeep: economy.populationUpkeep,
          consumedUpkeep: adjustments.consumedFoodUpkeep,
        ),
        yield: TileYield(
          food: -adjustments.consumedFoodUpkeep,
          production: 0,
          gold: 0,
          defense: 0,
        ),
      ),
  ];
}

_CityYieldAdjustments _yieldAdjustmentsFor({
  required CityTileYieldBreakdown tileBreakdown,
  required CityEconomyBreakdown economy,
}) {
  final preMultiplier =
      tileBreakdown.total +
      economy.buildingYield +
      economy.specializationYield +
      economy.technologyYield;
  final sourceYield = preMultiplier + economy.wonderYield;
  final goldMultiplierYield = TileYield(
    food: 0,
    production: 0,
    gold: economy.grossYield.gold - sourceYield.gold,
    defense: 0,
  );
  final stableProduction = _scaleYield(
    economy.grossYield.production,
    1 + economy.wonderProductionMultiplier,
  );
  final wonderYield =
      economy.wonderYield +
      TileYield(
        food: 0,
        production: stableProduction - economy.grossYield.production,
        gold: 0,
        defense: 0,
      );
  return (
    goldMultiplierYield: goldMultiplierYield,
    wonderYield: wonderYield,
    stabilityYield: _stabilityYieldFor(
      economy,
      stableProduction: stableProduction,
    ),
    consumedFoodUpkeep: economy.grossYield.food - economy.netFood,
  );
}

TileYield _stabilityYieldFor(
  CityEconomyBreakdown economy, {
  required int stableProduction,
}) {
  return TileYield(
    food: 0,
    production: economy.netYield.production - stableProduction,
    gold: economy.netYield.gold - economy.grossYield.gold,
    defense: 0,
  );
}

int _scaleYield(int value, double multiplier) {
  if (multiplier == 1.0) return value;
  return (value * multiplier).floor();
}
