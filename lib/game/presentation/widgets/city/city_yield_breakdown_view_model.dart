import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';

class CityYieldBreakdownViewModel {
  const CityYieldBreakdownViewModel({
    required this.totalYield,
    required this.rows,
    required this.growthLabel,
    required this.growthEta,
    this.scienceRows = const [],
  });

  final TileYield totalYield;
  final List<CityYieldBreakdownRow> rows;
  final String growthLabel;
  final TurnEta growthEta;
  final List<CityScienceBreakdownRow> scienceRows;

  TileYield get rowsTotal => _sum(rows.map((row) => row.yield));

  bool get rowsMatchTotal => rowsTotal == totalYield;

  int get scienceTotal {
    var total = 0;
    for (final row in scienceRows) {
      total += row.value;
    }
    return total;
  }

  factory CityYieldBreakdownViewModel.from({
    required GameCity city,
    required CityTileYieldBreakdown tileBreakdown,
    required CityEconomyBreakdown economy,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    int? currentTurn,
    required AppLocalizations l10n,
  }) {
    final text = CityYieldBreakdownText(l10n);
    final preMultiplier =
        tileBreakdown.total +
        economy.buildingYield +
        economy.specializationYield +
        economy.technologyYield;
    final goldMultiplierYield = TileYield(
      food: 0,
      production: 0,
      gold: economy.grossYield.gold - preMultiplier.gold,
      defense: 0,
    );
    final consumedFoodUpkeep = preMultiplier.food < economy.populationUpkeep
        ? preMultiplier.food
        : economy.populationUpkeep;

    final rows = [
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
      if (!_isZero(economy.specializationYield) || city.specialization != null)
        CityYieldBreakdownRow(
          label: text.specialization,
          detail: text.specializationDetail(city.specialization),
          yield: economy.specializationYield,
        ),
      if (!_isZero(goldMultiplierYield))
        CityYieldBreakdownRow(
          label: text.goldMultiplier,
          detail: text.goldMultiplierDetail,
          yield: goldMultiplierYield,
        ),
      if (economy.populationUpkeep != 0)
        CityYieldBreakdownRow(
          label: text.upkeep,
          detail: text.upkeepDetail(
            city: city,
            populationUpkeep: economy.populationUpkeep,
            consumedUpkeep: consumedFoodUpkeep,
          ),
          yield: TileYield(
            food: -consumedFoodUpkeep,
            production: 0,
            gold: 0,
            defense: 0,
          ),
        ),
    ];

    return CityYieldBreakdownViewModel(
      totalYield: economy.netYield,
      rows: List.unmodifiable(rows),
      growthLabel: text.growthFood(city.storedFood, economy.growthCost),
      growthEta: _growthEta(
        city: city,
        economy: economy,
        currentTurn: currentTurn,
        text: text,
      ),
      scienceRows: _scienceRowsFor(
        city,
        economy: economy,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        text: text,
      ),
    );
  }

  factory CityYieldBreakdownViewModel.fromCity({
    required GameCity city,
    required MapData mapData,
    required List<FieldImprovement> fieldImprovements,
    required List<GameUnit> units,
    List<WorldArtifact> artifacts = const [],
    required CityRuleset cityRuleset,
    required ResearchState research,
    required TechnologyRuleset technologyRuleset,
    int? currentTurn,
    PaceBalance paceBalance = PaceBalance.unlimited,
    required AppLocalizations l10n,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: research,
      ruleset: technologyRuleset,
    );
    final tileBreakdown = CityYieldCalculator.breakdownFor(
      city,
      mapData,
      fieldImprovements: fieldImprovements,
      units: units,
      artifacts: artifacts,
      ruleset: cityRuleset,
    );
    final economy = CityEconomyBreakdown.from(
      city: city,
      tileYield: tileBreakdown.total,
      mapData: mapData,
      ruleset: cityRuleset,
      paceBalance: paceBalance,
      technologyEffects: technologyEffects,
    );
    return CityYieldBreakdownViewModel.from(
      city: city,
      tileBreakdown: tileBreakdown,
      economy: economy,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      currentTurn: currentTurn,
      l10n: l10n,
    );
  }

  static List<CityScienceBreakdownRow> _scienceRowsFor(
    GameCity city, {
    required CityEconomyBreakdown economy,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required CityYieldBreakdownText text,
  }) {
    final rows = <CityScienceBreakdownRow>[];
    final scienceBalance = technologyRuleset.science;
    if (scienceBalance.baseSciencePerCity > 0) {
      rows.add(
        CityScienceBreakdownRow(
          label: text.baseScience,
          detail: text.baseScienceDetail,
          value: scienceBalance.baseSciencePerCity,
        ),
      );
    }

    final buildingScience = _buildingScienceFor(
      city,
      scienceBalance: scienceBalance,
      cityRuleset: cityRuleset,
      text: text,
    );
    if (buildingScience.value > 0) {
      rows.add(buildingScience);
    }

    final specializationScience = CitySpecializationRules.scienceFor(
      city.specialization,
    );
    if (specializationScience > 0) {
      rows.add(
        CityScienceBreakdownRow(
          label: text.specialization,
          detail: text.scienceSpecializationDetail,
          value: specializationScience,
        ),
      );
    }

    final technologyScience = economy.technologyEffects.cityScienceBonus;
    if (technologyScience > 0) {
      rows.add(
        CityScienceBreakdownRow(
          label: text.technologies,
          detail: text.scienceTechnologyDetail,
          value: technologyScience,
        ),
      );
    }

    if (city.productionQueue?.target case ProjectProductionTarget(
      projectType: CityProjectType.research,
    )) {
      final projectOutput = CityProjectRules.outputFor(
        type: CityProjectType.research,
        productionPerTurn: CityProductionRules.productionPerTurn(
          economy.netYield.production,
        ),
      );
      if (projectOutput > 0) {
        rows.add(
          CityScienceBreakdownRow(
            label: text.researchProject,
            detail: text.researchProjectDetail,
            value: projectOutput,
          ),
        );
      }
    }

    return List.unmodifiable(rows);
  }

  static CityScienceBreakdownRow _buildingScienceFor(
    GameCity city, {
    required ScienceBalance scienceBalance,
    required CityRuleset cityRuleset,
    required CityYieldBreakdownText text,
  }) {
    final amounts = <int>[];
    for (final buildingType in city.buildings) {
      for (final effect
          in cityRuleset.buildingDefinitionFor(buildingType).effects) {
        if (effect case FlatCityScienceEffect(:final amount) when amount > 0) {
          amounts.add(amount);
        }
      }
    }
    if (amounts.isEmpty) {
      return CityScienceBreakdownRow(
        label: text.buildings,
        detail: text.noScienceBuildings,
        value: 0,
      );
    }

    amounts.sort((a, b) => b.compareTo(a));
    var total = 0.0;
    for (var i = 0; i < amounts.length; i++) {
      final multiplier = switch (i) {
        0 => 1.0,
        1 => scienceBalance.secondScienceBuildingMultiplier,
        _ => scienceBalance.thirdScienceBuildingMultiplier,
      };
      total += amounts[i] * multiplier;
    }
    final count = amounts.length;
    return CityScienceBreakdownRow(
      label: text.buildings,
      detail: count == 1
          ? text.oneScienceBuilding
          : text.manyScienceBuildings(count),
      value: total.round(),
    );
  }

  static TurnEta _growthEta({
    required GameCity city,
    required CityEconomyBreakdown economy,
    required int? currentTurn,
    required CityYieldBreakdownText text,
  }) {
    final remaining = economy.growthCost - city.storedFood;
    return TurnEtaFormatter.fromProgress(
      remaining: remaining <= 0 ? 0 : remaining,
      perTurn: economy.foodDeposit,
      currentTurn: currentTurn,
      blockedLabel: text.stagnation,
    );
  }

  static TileYield _sum(Iterable<TileYield> values) {
    var total = TileYield.zero;
    for (final value in values) {
      total = total + value;
    }
    return total;
  }

  static bool _isZero(TileYield yield) {
    return yield.food == 0 &&
        yield.production == 0 &&
        yield.gold == 0 &&
        yield.defense == 0;
  }
}

class CityYieldBreakdownText {
  const CityYieldBreakdownText(this.l10n);

  final AppLocalizations l10n;

  String get center => l10n.cityYieldBreakdownCenter;
  String get populationFields => l10n.cityYieldBreakdownPopulationFields;
  String get workers => l10n.cityYieldBreakdownWorkers;
  String get improvements => l10n.commonImprovements;
  String get buildings => l10n.cityYieldBreakdownBuildings;
  String get technologies => l10n.cityYieldBreakdownTechnologies;
  String get specialization => l10n.cityYieldBreakdownSpecialization;
  String get goldMultiplier => l10n.cityYieldBreakdownGoldMultiplier;
  String get upkeep => l10n.cityYieldBreakdownUpkeep;
  String get fieldsBucket => l10n.cityYieldBreakdownFieldsBucket;
  String get multipliers => l10n.commonMultipliers;
  String get other => l10n.commonOther;
  String get centerDetail => l10n.cityYieldBreakdownCenterDetail;
  String get goldMultiplierDetail =>
      l10n.cityYieldBreakdownGoldMultiplierDetail;
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
