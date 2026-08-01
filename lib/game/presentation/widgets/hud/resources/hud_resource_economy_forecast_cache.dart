part of 'hud_resource_economy_forecast.dart';

final class HudResourceEconomyForecastCache {
  HudResourceEconomyForecastCache({
    this.maxForecastEntries = 8,
    this.maxCityEconomyEntries = 128,
  }) : assert(maxForecastEntries > 0),
       assert(maxCityEconomyEntries > 0);

  final int maxForecastEntries;
  final int maxCityEconomyEntries;
  final LinkedHashMap<
    _HudResourceEconomyForecastKey,
    HudResourceEconomyForecast
  >
  _forecasts = LinkedHashMap();
  final LinkedHashMap<_HudCityEconomyForecastKey, CityEconomyBreakdown>
  _cityEconomies = LinkedHashMap();
  int _computeCount = 0;
  int _cityEconomyComputeCount = 0;

  HudResourceEconomyForecast forPlayer({
    required GameClientState state,
    required String playerId,
    required WorldMap mapData,
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
    final cached = _forecasts.remove(key);
    if (cached != null) {
      _forecasts[key] = cached;
      return cached;
    }

    _computeCount++;
    final computed = HudResourceEconomyForecast._computeForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
      economyForCity: (city, technologyEffects) => _economyForCity(
        state: state,
        playerId: playerId,
        city: city,
        mapData: mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        stabilityModifier: stabilityModifier,
        technologyEffects: technologyEffects,
      ),
    );
    _forecasts[key] = computed;
    _prune(_forecasts, maxForecastEntries);
    return computed;
  }

  CityEconomyBreakdown _economyForCity({
    required GameClientState state,
    required String playerId,
    required GameCity city,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
    required TechnologyEffectSummary technologyEffects,
  }) {
    final key = _HudCityEconomyForecastKey.from(
      state: state,
      playerId: playerId,
      city: city,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
    );
    final cached = _cityEconomies.remove(key);
    if (cached != null) {
      _cityEconomies[key] = cached;
      return cached;
    }

    _cityEconomyComputeCount++;
    final computed = HudCityEconomyCalculator.forCity(
      city: city,
      state: state,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyEffects: technologyEffects,
      stabilityModifier: stabilityModifier,
    );
    _cityEconomies[key] = computed;
    _prune(_cityEconomies, maxCityEconomyEntries);
    return computed;
  }

  void clear() {
    _forecasts.clear();
    _cityEconomies.clear();
    _computeCount = 0;
    _cityEconomyComputeCount = 0;
  }

  @visibleForTesting
  int get debugComputeCount => _computeCount;

  @visibleForTesting
  int get debugCityEconomyComputeCount => _cityEconomyComputeCount;

  @visibleForTesting
  int get debugForecastEntryCount => _forecasts.length;

  @visibleForTesting
  int get debugCityEconomyEntryCount => _cityEconomies.length;

  static void _prune<K, V>(LinkedHashMap<K, V> values, int maxEntries) {
    while (values.length > maxEntries) {
      values.remove(values.keys.first);
    }
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
    required GameClientState state,
    required String playerId,
    required WorldMap mapData,
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
  final WorldMap mapData;
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

final class _HudCityEconomyForecastKey {
  const _HudCityEconomyForecastKey({
    required this.playerId,
    required this.city,
    required this.mapData,
    required this.cityRuleset,
    required this.technologyRuleset,
    required this.stabilityModifier,
    required this.research,
    required this.units,
    required this.fieldImprovements,
    required this.artifacts,
  });

  factory _HudCityEconomyForecastKey.from({
    required GameClientState state,
    required String playerId,
    required GameCity city,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required StabilityModifier stabilityModifier,
  }) {
    return _HudCityEconomyForecastKey(
      playerId: playerId,
      city: city,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      stabilityModifier: stabilityModifier,
      research: state.research,
      units: _identitySignature(state.units),
      fieldImprovements: _identitySignature(state.fieldImprovements),
      artifacts: _identitySignature(state.artifacts),
    );
  }

  final String playerId;
  final GameCity city;
  final WorldMap mapData;
  final CityRuleset cityRuleset;
  final TechnologyRuleset technologyRuleset;
  final StabilityModifier stabilityModifier;
  final ResearchState research;
  final int units;
  final int fieldImprovements;
  final int artifacts;

  @override
  bool operator ==(Object other) {
    return other is _HudCityEconomyForecastKey &&
        other.playerId == playerId &&
        identical(other.city, city) &&
        identical(other.mapData, mapData) &&
        identical(other.cityRuleset, cityRuleset) &&
        identical(other.technologyRuleset, technologyRuleset) &&
        other.stabilityModifier == stabilityModifier &&
        identical(other.research, research) &&
        other.units == units &&
        other.fieldImprovements == fieldImprovements &&
        other.artifacts == artifacts;
  }

  @override
  int get hashCode => Object.hash(
    playerId,
    identityHashCode(city),
    identityHashCode(mapData),
    identityHashCode(cityRuleset),
    identityHashCode(technologyRuleset),
    stabilityModifier,
    identityHashCode(research),
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
