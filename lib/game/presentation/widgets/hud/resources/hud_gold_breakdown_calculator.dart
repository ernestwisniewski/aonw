import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/resources/resource_breakdown_popup.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class HudGoldResourceCalculator {
  static HudGoldForecast forecastForPlayer({
    required GameState state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
  }) {
    return _computeForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
      collectSources: false,
    ).forecast;
  }

  static GoldBreakdown breakdownForPlayer({
    required GameState state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
  }) {
    return _computeForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
      collectSources: true,
    ).toBreakdown();
  }

  static _GoldComputation _computeForPlayer({
    required GameState state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
    required bool collectSources,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: playerId,
      research: state.research,
      ruleset: technologyRuleset,
    );
    final citySources = <GoldCitySource>[];
    final projectSources = <GoldProjectSource>[];
    var cityIncome = 0;
    var projectIncome = 0;

    for (final city in state.cities) {
      if (city.ownerPlayerId != playerId) continue;
      final economy = _economyForCity(
        city: city,
        state: state,
        mapData: mapData,
        cityRuleset: cityRuleset,
        technologyEffects: technologyEffects,
        stabilityModifier: stabilityModifier,
      );
      if (economy.netYield.gold > 0) {
        cityIncome += economy.netYield.gold;
        if (collectSources) {
          citySources.add(
            GoldCitySource(city: city, amount: economy.netYield.gold),
          );
        }
      }

      if (_projectTypeFor(city) == CityProjectType.wealth) {
        final output = CityProjectRules.outputFor(
          type: CityProjectType.wealth,
          productionPerTurn: CityProductionRules.productionPerTurn(
            economy.netYield.production,
          ),
        );
        projectIncome += output;
        if (collectSources) {
          projectSources.add(GoldProjectSource(city: city, amount: output));
        }
      }
    }

    return _GoldComputation(
      treasury: state.playerGold[playerId] ?? 0,
      cityIncome: cityIncome,
      projectIncome: projectIncome,
      citySources: collectSources ? List.unmodifiable(citySources) : const [],
      projectSources: collectSources
          ? List.unmodifiable(projectSources)
          : const [],
      upkeep: UnitUpkeepRules.forPlayer(
        playerId: playerId,
        units: state.units,
        cities: state.cities,
      ),
    );
  }
}

CityEconomyBreakdown _economyForCity({
  required GameCity city,
  required GameState state,
  required MapData mapData,
  required CityRuleset cityRuleset,
  required TechnologyEffectSummary technologyEffects,
  required StabilityModifier stabilityModifier,
}) {
  final cityYield = CityYieldCalculator.totalFor(
    city,
    mapData,
    fieldImprovements: state.fieldImprovements,
    units: state.units,
    artifacts: state.artifacts,
    ruleset: cityRuleset,
  );
  return CityEconomyBreakdown.from(
    city: city,
    tileYield: cityYield,
    mapData: mapData,
    ruleset: cityRuleset,
    technologyEffects: technologyEffects,
    stabilityModifier: stabilityModifier,
  );
}

CityProjectType? _projectTypeFor(GameCity city) {
  return switch (city.productionQueue?.target) {
    ProjectProductionTarget(:final projectType) => projectType,
    _ => null,
  };
}

final class HudGoldForecast {
  const HudGoldForecast({
    required this.treasury,
    required this.grossIncome,
    required this.unitUpkeep,
    required this.netPerTurn,
  });

  final int treasury;
  final int grossIncome;
  final int unitUpkeep;
  final int netPerTurn;
}

final class _GoldComputation {
  const _GoldComputation({
    required this.treasury,
    required this.cityIncome,
    required this.projectIncome,
    required this.citySources,
    required this.projectSources,
    required this.upkeep,
  });

  final int treasury;
  final int cityIncome;
  final int projectIncome;
  final List<GoldCitySource> citySources;
  final List<GoldProjectSource> projectSources;
  final UnitUpkeepBreakdown upkeep;

  HudGoldForecast get forecast {
    final grossIncome = cityIncome + projectIncome;
    return HudGoldForecast(
      treasury: treasury,
      grossIncome: grossIncome,
      unitUpkeep: upkeep.total,
      netPerTurn: grossIncome - upkeep.total,
    );
  }

  GoldBreakdown toBreakdown() {
    return GoldBreakdown(
      treasury: treasury,
      citySources: citySources,
      projectSources: projectSources,
      upkeep: upkeep,
    );
  }
}
