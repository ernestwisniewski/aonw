import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'city_yield_breakdown_rows.dart';
part 'city_yield_breakdown_text.dart';

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

    return CityYieldBreakdownViewModel(
      totalYield: economy.netYield,
      rows: _cityYieldRows(
        city: city,
        tileBreakdown: tileBreakdown,
        economy: economy,
        text: text,
      ),
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
    required WorldMap mapData,
    required List<FieldImprovement> fieldImprovements,
    required List<GameUnit> units,
    List<WorldArtifact> artifacts = const [],
    required CityRuleset cityRuleset,
    required ResearchState research,
    required TechnologyRuleset technologyRuleset,
    CityTileYieldBreakdown? projectedTileBreakdown,
    CityEconomyBreakdown? projectedEconomy,
    int? currentTurn,
    PaceBalance paceBalance = PaceBalance.unlimited,
    required AppLocalizations l10n,
  }) {
    final useProjectedSnapshot =
        projectedTileBreakdown != null && projectedEconomy != null;
    final breakdownCity = useProjectedSnapshot ? projectedEconomy.city : city;
    final tileBreakdown = useProjectedSnapshot
        ? projectedTileBreakdown
        : CityYieldCalculator.breakdownFor(
            city,
            mapData,
            fieldImprovements: fieldImprovements,
            units: units,
            artifacts: artifacts,
            ruleset: cityRuleset,
          );
    final economy = useProjectedSnapshot
        ? projectedEconomy
        : CityEconomyBreakdown.from(
            city: city,
            tileYield: tileBreakdown.total,
            mapTiles: mapData,
            ruleset: cityRuleset,
            paceBalance: paceBalance,
            technologyEffects: TechnologyEffectSummary.forPlayer(
              playerId: city.ownerPlayerId,
              research: research,
              ruleset: technologyRuleset,
            ),
          );
    return CityYieldBreakdownViewModel.from(
      city: breakdownCity,
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

    final projectOutput = city.productionQueue?.projectOutput(
      productionPerTurn: CityProductionRules.productionPerTurn(
        economy.netYield.production,
      ),
    );
    final projectScience = projectOutput?.science ?? 0;
    if (projectScience > 0) {
      rows.add(
        CityScienceBreakdownRow(
          label: text.researchProject,
          detail: text.researchProjectDetail,
          value: projectScience,
        ),
      );
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
