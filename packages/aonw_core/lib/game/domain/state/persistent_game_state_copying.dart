part of 'persistent_game_state.dart';

mixin _PersistentGameStateCopying {
  Map<String, int> get playerColors;
  Map<String, PlayerCountry> get playerCountries;
  Map<String, int> get playerGold;
  Map<String, int> get playerWarWeariness;
  Map<String, int> get playerStabilityNet;
  List<GameUnit> get units;
  List<GameCity> get cities;
  List<WorldArtifact> get artifacts;
  List<FieldImprovement> get fieldImprovements;
  FogOfWarState get fogOfWar;
  ResearchState get research;
  GameRuntimeState get runtimeState;
  WonderRegistry get wonderRegistry;
  bool get _isImmutableSnapshot;

  PersistentGameState immutableSnapshot() {
    if (_isImmutableSnapshot) return this as PersistentGameState;
    return PersistentGameState.snapshot(
      playerColors: playerColors,
      playerCountries: playerCountries,
      playerGold: playerGold,
      playerWarWeariness: playerWarWeariness,
      playerStabilityNet: playerStabilityNet,
      units: units,
      cities: cities,
      artifacts: artifacts,
      fieldImprovements: fieldImprovements,
      fogOfWar: fogOfWar,
      research: research,
      runtimeState: runtimeState,
      wonderRegistry: wonderRegistry,
    );
  }

  PersistentGameState copyWith({
    Map<String, int>? playerColors,
    Map<String, PlayerCountry>? playerCountries,
    Map<String, int>? playerGold,
    Map<String, int>? playerWarWeariness,
    Map<String, int>? playerStabilityNet,
    List<GameUnit>? units,
    List<GameCity>? cities,
    List<WorldArtifact>? artifacts,
    List<FieldImprovement>? fieldImprovements,
    FogOfWarState? fogOfWar,
    ResearchState? research,
    GameRuntimeState? runtimeState,
    WonderRegistry? wonderRegistry,
  }) {
    final source = immutableSnapshot();
    return PersistentGameState._owned(
      playerColors: _persistentMapCopy(playerColors, source.playerColors),
      playerCountries: _persistentMapCopy(
        playerCountries,
        source.playerCountries,
      ),
      playerGold: _persistentMapCopy(playerGold, source.playerGold),
      playerWarWeariness: _persistentMapCopy(
        playerWarWeariness,
        source.playerWarWeariness,
      ),
      playerStabilityNet: _persistentMapCopy(
        playerStabilityNet,
        source.playerStabilityNet,
      ),
      units: _persistentListCopy(units, source.units),
      cities: _persistentCityListCopy(cities, source.cities),
      artifacts: _persistentListCopy(artifacts, source.artifacts),
      fieldImprovements: _persistentListCopy(
        fieldImprovements,
        source.fieldImprovements,
      ),
      fogOfWar: fogOfWar ?? source.fogOfWar,
      research: research ?? source.research,
      runtimeState: runtimeState == null
          ? source.runtimeState
          : runtimeState.immutableSnapshot(),
      wonderRegistry: wonderRegistry ?? source.wonderRegistry,
    );
  }
}

Map<K, V> _persistentMapCopy<K, V>(Map<K, V>? replacement, Map<K, V> current) {
  return replacement == null ? current : _immutablePersistentMap(replacement);
}

List<T> _persistentListCopy<T>(List<T>? replacement, List<T> current) {
  return replacement == null ? current : _immutablePersistentList(replacement);
}

List<GameCity> _persistentCityListCopy(
  List<GameCity>? replacement,
  List<GameCity> current,
) {
  return replacement == null
      ? current
      : _immutablePersistentCities(replacement);
}

Map<K, V> _immutablePersistentMap<K, V>(Map<K, V> source) =>
    source.isEmpty ? const {} : Map.unmodifiable(source);

List<T> _immutablePersistentList<T>(List<T> source) =>
    source.isEmpty ? const [] : List.unmodifiable(source);

List<GameCity> _immutablePersistentCities(List<GameCity> source) =>
    source.isEmpty
    ? const []
    : List<GameCity>.unmodifiable(
        source.map((city) => city.immutableSnapshot()),
      );
