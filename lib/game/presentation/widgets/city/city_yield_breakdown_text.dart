part of 'city_yield_breakdown_view_model.dart';

class CityYieldBreakdownText {
  const CityYieldBreakdownText(this.l10n);

  final AppLocalizations l10n;

  String get center => l10n.cityYieldBreakdownCenter;
  String get populationFields => l10n.cityYieldBreakdownPopulationFields;
  String get workers => l10n.cityYieldBreakdownWorkers;
  String get improvements => l10n.commonImprovements;
  String get artifact => l10n.citySelectionArtifactLabel;
  String get buildings => l10n.cityYieldBreakdownBuildings;
  String get technologies => l10n.cityYieldBreakdownTechnologies;
  String get specialization => l10n.cityYieldBreakdownSpecialization;
  String get wonders => l10n.cityProductionWondersSection;
  String get goldMultiplier => l10n.cityYieldBreakdownGoldMultiplier;
  String get stability => l10n.stabilityBreakdownBand;
  String get upkeep => l10n.cityYieldBreakdownUpkeep;
  String get fieldsBucket => l10n.cityYieldBreakdownFieldsBucket;
  String get multipliers => l10n.commonMultipliers;
  String get other => l10n.commonOther;
  String get centerDetail => l10n.cityYieldBreakdownCenterDetail;
  String get artifactDetail => l10n.worldArtifactLocationStored;
  String get goldMultiplierDetail =>
      l10n.cityYieldBreakdownGoldMultiplierDetail;
  String get wonderDetail => l10n.wonderDetailsStandingEffects;
  String get baseScience => l10n.cityYieldBreakdownBaseScience;
  String get baseScienceDetail => l10n.cityYieldBreakdownBaseScienceDetail;
  String get researchProject => l10n.cityYieldBreakdownResearchProject;
  String get researchProjectDetail =>
      l10n.cityYieldBreakdownResearchProjectDetail;
  String get scienceSpecializationDetail =>
      l10n.cityYieldBreakdownScienceSpecializationDetail;
  String get scienceTechnologyDetail =>
      l10n.cityYieldBreakdownScienceTechnologyDetail;
  String get noScienceBuildings => l10n.cityYieldBreakdownNoScienceBuildings;
  String get oneScienceBuilding => l10n.cityYieldBreakdownOneScienceBuilding;
  String get stagnation => l10n.cityYieldBreakdownStagnation;

  String workedHexDetail(int count) {
    if (count <= 0) {
      return l10n.cityYieldBreakdownNoWorkedPopulationFields;
    }
    if (count == 1) {
      return l10n.cityYieldBreakdownOneWorkedPopulationField;
    }
    return l10n.cityYieldBreakdownManyWorkedPopulationFields(count);
  }

  String workerDetail(int count) {
    if (count <= 0) {
      return l10n.cityYieldBreakdownNoAssignedWorkers;
    }
    if (count == 1) {
      return l10n.cityYieldBreakdownOneAssignedWorker;
    }
    return l10n.cityYieldBreakdownManyAssignedWorkers(count);
  }

  String passiveImprovementDetail(int count) {
    if (count <= 0) {
      return l10n.cityYieldBreakdownNoPassiveImprovements;
    }
    if (count == 1) {
      return l10n.cityYieldBreakdownOnePassiveImprovement;
    }
    return l10n.cityYieldBreakdownManyPassiveImprovements(count);
  }

  String buildingDetail(GameCity city, TileYield yield) {
    if (city.buildings.isEmpty) {
      return l10n.cityYieldBreakdownNoBuildings;
    }
    if (CityYieldBreakdownViewModel._isZero(yield)) {
      return l10n.cityYieldBreakdownBuildingsNoDirectYield;
    }
    if (city.buildings.length == 1) {
      return l10n.cityYieldBreakdownOneBuildingEconomicEffect;
    }
    return l10n.cityYieldBreakdownManyBuildingEconomicEffects(
      city.buildings.length,
    );
  }

  String technologyDetail(TileYield yield) {
    if (CityYieldBreakdownViewModel._isZero(yield)) {
      return l10n.cityYieldBreakdownNoTechnologyYield;
    }
    return l10n.cityYieldBreakdownTechnologyYield;
  }

  String upkeepDetail({
    required GameCity city,
    required int populationUpkeep,
    required int consumedUpkeep,
  }) {
    if (consumedUpkeep < populationUpkeep) {
      return l10n.cityYieldBreakdownUpkeepBlocked(
        city.population,
        populationUpkeep,
      );
    }
    return l10n.cityYieldBreakdownUpkeepCost(city.population);
  }

  String specializationDetail(CitySpecializationType? specialization) {
    return switch (specialization) {
      CitySpecializationType.growth =>
        l10n.cityYieldBreakdownGrowthSpecializationDetail,
      CitySpecializationType.industry =>
        l10n.cityYieldBreakdownIndustrySpecializationDetail,
      CitySpecializationType.commerce =>
        l10n.cityYieldBreakdownCommerceSpecializationDetail,
      CitySpecializationType.science =>
        l10n.cityYieldBreakdownScienceSpecializationCityDetail,
      CitySpecializationType.military =>
        l10n.cityYieldBreakdownMilitarySpecializationDetail,
      null => l10n.cityYieldBreakdownNoSpecialization,
    };
  }

  String stabilityDetail(StabilityModifier modifier) {
    if (modifier == StabilityPolicy.modifierFor(StabilityBand.content)) {
      return l10n.stabilityBandContent;
    }
    if (modifier == StabilityPolicy.modifierFor(StabilityBand.strained)) {
      return l10n.stabilityBandStrained;
    }
    if (modifier == StabilityPolicy.modifierFor(StabilityBand.unrest)) {
      return l10n.stabilityBandUnrest;
    }
    return l10n.stabilityBandStable;
  }

  String manyScienceBuildings(int count) =>
      l10n.cityYieldBreakdownManyScienceBuildings(count);

  String growthFood(int storedFood, int growthCost) =>
      l10n.cityYieldBreakdownGrowthFood(storedFood, growthCost);
}

class CityYieldBreakdownRow {
  const CityYieldBreakdownRow({
    required this.label,
    required this.detail,
    required this.yield,
  });

  final String label;
  final String detail;
  final TileYield yield;
}

class CityScienceBreakdownRow {
  const CityScienceBreakdownRow({
    required this.label,
    required this.detail,
    required this.value,
  });

  final String label;
  final String detail;
  final int value;
}
