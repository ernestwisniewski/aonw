import 'dart:collection';

import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_city_economy_calculator.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/foundation.dart';

part 'hud_resource_economy_forecast_cache.dart';

final class HudResourceEconomyForecast {
  const HudResourceEconomyForecast({
    required this.gold,
    required this.goldIncome,
    required this.unitUpkeep,
    required this.goldPerTurn,
    required this.sciencePerTurn,
  });

  final int gold;
  final int goldIncome;
  final int unitUpkeep;
  final int goldPerTurn;
  final int sciencePerTurn;

  factory HudResourceEconomyForecast.forPlayer({
    required GameClientState state,
    required String playerId,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
    HudResourceEconomyForecastCache? cache,
  }) {
    final forecastCache = cache;
    if (forecastCache != null) {
      return forecastCache.forPlayer(
        state: state,
        playerId: playerId,
        mapData: mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        stabilityModifier: stabilityModifier,
      );
    }
    return _computeForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
    );
  }

  static HudResourceEconomyForecast _computeForPlayer({
    required GameClientState state,
    required String playerId,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
    CityEconomyBreakdown Function(
      GameCity city,
      TechnologyEffectSummary technologyEffects,
    )?
    economyForCity,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: playerId,
      research: state.research,
      ruleset: technologyRuleset,
    );
    var cityGoldIncome = 0;
    var projectGoldIncome = 0;
    var projectScience = 0;

    for (final city in state.cities) {
      if (city.ownerPlayerId != playerId) continue;
      final economy =
          economyForCity?.call(city, technologyEffects) ??
          HudCityEconomyCalculator.forCity(
            city: city,
            state: state,
            mapData: mapData,
            cityRuleset: cityRuleset,
            technologyEffects: technologyEffects,
            stabilityModifier: stabilityModifier,
          );
      if (economy.netYield.gold > 0) {
        cityGoldIncome += economy.netYield.gold;
      }

      final projectOutput = city.productionQueue?.projectOutput(
        productionPerTurn: CityProductionRules.productionPerTurn(
          economy.netYield.production,
        ),
      );
      if (projectOutput == null) continue;
      projectGoldIncome += projectOutput.gold;
      projectScience += projectOutput.science;
    }

    final grossIncome = cityGoldIncome + projectGoldIncome;
    final unitUpkeep = UnitUpkeepRules.forPlayer(
      playerId: playerId,
      units: state.units,
      cities: state.cities,
    ).total;
    return HudResourceEconomyForecast(
      gold: state.playerGold[playerId] ?? 0,
      goldIncome: grossIncome,
      unitUpkeep: unitUpkeep,
      goldPerTurn: grossIncome - unitUpkeep,
      sciencePerTurn:
          ScienceYieldCalculator.totalAmountForPlayer(
            playerId: playerId,
            cities: state.cities,
            research: state.research,
            ruleset: technologyRuleset,
            artifacts: state.artifacts,
            cityRuleset: cityRuleset,
          ) +
          projectScience,
    );
  }
}
