import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/hud/resources/hud_city_economy_calculator.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/foundation.dart';

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

  static final _cache = _HudResourceEconomyForecastCache();

  factory HudResourceEconomyForecast.forPlayer({
    required GameState state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
  }) {
    return _cache.forPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
    );
  }

  static HudResourceEconomyForecast _computeForPlayer({
    required GameState state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
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
      final economy = HudCityEconomyCalculator.forCity(
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

      final projectType = city.productionQueue?.projectType;
      if (projectType == null) continue;
      final output = CityProjectRules.outputFor(
        type: projectType,
        productionPerTurn: CityProductionRules.productionPerTurn(
          economy.netYield.production,
        ),
      );
      switch (projectType) {
        case CityProjectType.wealth:
          projectGoldIncome += output;
        case CityProjectType.research:
          projectScience += output;
      }
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

  @visibleForTesting
  static void debugResetCache() {
    _cache.clear();
  }

  @visibleForTesting
  static int get debugComputeCount => _cache.computeCount;
}

final class _HudResourceEconomyForecastCache {
  _HudResourceEconomyForecastKey? _key;
  HudResourceEconomyForecast? _value;
  int computeCount = 0;

  HudResourceEconomyForecast forPlayer({
    required GameState state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
  }) {
    final key = _HudResourceEconomyForecastKey.from(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
    );
    final value = _value;
    if (value != null && key == _key) return value;

    computeCount++;
    final computed = HudResourceEconomyForecast._computeForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
    );
    _key = key;
    _value = computed;
    return computed;
  }

  void clear() {
    _key = null;
    _value = null;
    computeCount = 0;
  }
}

final class _HudResourceEconomyForecastKey {
  const _HudResourceEconomyForecastKey({
    required this.playerId,
    required this.mapData,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.stabilityModifier,
    required this.gold,
    required this.research,
    required this.cities,
    required this.units,
    required this.fieldImprovements,
    required this.artifacts,
  });

  factory _HudResourceEconomyForecastKey.from({
    required GameState state,
    required String playerId,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
  }) {
    return _HudResourceEconomyForecastKey(
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
      gold: state.playerGold[playerId] ?? 0,
      research: state.research,
      cities: _identitySignature(state.cities),
      units: _identitySignature(state.units),
      fieldImprovements: _identitySignature(state.fieldImprovements),
      artifacts: _identitySignature(state.artifacts),
    );
  }

  final String playerId;
  final MapData mapData;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final StabilityModifier stabilityModifier;
  final int gold;
  final ResearchState research;
  final int cities;
  final int units;
  final int fieldImprovements;
  final int artifacts;

  @override
  bool operator ==(Object other) {
    return other is _HudResourceEconomyForecastKey &&
        other.playerId == playerId &&
        identical(other.mapData, mapData) &&
        identical(other.cityRuleset, cityRuleset) &&
        identical(other.technologyRuleset, technologyRuleset) &&
        other.stabilityModifier == stabilityModifier &&
        other.gold == gold &&
        identical(other.research, research) &&
        other.cities == cities &&
        other.units == units &&
        other.fieldImprovements == fieldImprovements &&
        other.artifacts == artifacts;
  }

  @override
  int get hashCode => Object.hash(
    playerId,
    identityHashCode(mapData),
    identityHashCode(cityRuleset),
    identityHashCode(technologyRuleset),
    stabilityModifier,
    gold,
    identityHashCode(research),
    cities,
    units,
    fieldImprovements,
    artifacts,
  );
}

int _identitySignature(Iterable<Object?> values) {
  var hash = 0;
  var count = 0;
  for (final value in values) {
    count++;
    hash = Object.hash(hash, identityHashCode(value));
  }
  return Object.hash(count, hash);
}
