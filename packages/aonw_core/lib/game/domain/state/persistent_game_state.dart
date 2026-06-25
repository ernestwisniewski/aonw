import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/util/collection_equality.dart';

class PersistentGameState {
  const PersistentGameState({
    this.playerColors = const {},
    this.playerCountries = const {},
    this.playerGold = const {},
    this.units = const [],
    this.cities = const [],
    this.artifacts = const [],
    this.fieldImprovements = const [],
    this.fogOfWar = FogOfWarState.empty,
    this.research = ResearchState.empty,
    this.runtimeState = GameRuntimeState.empty,
  });

  factory PersistentGameState.fromJson(Map<String, dynamic> json) {
    return PersistentGameState(
      playerColors: _intMap(json['playerColors'], 'playerColors'),
      playerCountries: _countryMap(json['playerCountries'], 'playerCountries'),
      playerGold: _intMap(json['playerGold'], 'playerGold'),
      units: _jsonList(json['units'], 'units').map(GameUnit.fromJson).toList(),
      cities: _jsonList(
        json['cities'],
        'cities',
      ).map(GameCity.fromJson).toList(),
      artifacts: _jsonList(
        json['artifacts'],
        'artifacts',
      ).map(WorldArtifact.fromJson).toList(),
      fieldImprovements: _jsonList(
        json['fieldImprovements'],
        'fieldImprovements',
      ).map(FieldImprovement.fromJson).toList(),
      fogOfWar: switch (json['fogOfWar']) {
        null => FogOfWarState.empty,
        final List<dynamic> value => FogOfWarState.fromJson(value),
        final value => throw ArgumentError.value(
          value,
          'PersistentGameState.fogOfWar',
          'Expected a JSON list',
        ),
      },
      research: switch (json['research']) {
        null => ResearchState.empty,
        final Map<String, dynamic> value => ResearchState.fromJson(value),
        final Map<Object?, Object?> value => ResearchState.fromJson(
          Map<String, dynamic>.from(value),
        ),
        final value => throw ArgumentError.value(
          value,
          'PersistentGameState.research',
          'Expected a JSON object',
        ),
      },
      runtimeState: switch (json['runtimeState']) {
        null => GameRuntimeState.empty,
        final Map<String, dynamic> value => GameRuntimeState.fromJson(value),
        final Map<Object?, Object?> value => GameRuntimeState.fromJson(
          Map<String, dynamic>.from(value),
        ),
        final value => throw ArgumentError.value(
          value,
          'PersistentGameState.runtimeState',
          'Expected a JSON object',
        ),
      },
    );
  }

  final Map<String, int> playerColors;
  final Map<String, PlayerCountry> playerCountries;
  final Map<String, int> playerGold;
  final List<GameUnit> units;
  final List<GameCity> cities;
  final List<WorldArtifact> artifacts;
  final List<FieldImprovement> fieldImprovements;
  final FogOfWarState fogOfWar;
  final ResearchState research;
  final GameRuntimeState runtimeState;

  Map<String, dynamic> toJson() => {
    'playerColors': playerColors,
    'playerCountries': playerCountries.map(
      (playerId, country) => MapEntry(playerId, country.name),
    ),
    'playerGold': playerGold,
    'units': units.map((unit) => unit.toJson()).toList(),
    'cities': cities.map((city) => city.toJson()).toList(),
    'artifacts': artifacts.map((artifact) => artifact.toJson()).toList(),
    'fieldImprovements': fieldImprovements
        .map((improvement) => improvement.toJson())
        .toList(),
    'fogOfWar': fogOfWar.toJson(),
    'research': research.toJson(),
    'runtimeState': runtimeState.toJson(),
  };

  PersistentGameState withoutClientInteractionState() {
    return copyWith(runtimeState: runtimeState.withoutClientInteractionState());
  }

  PersistentGameState copyWith({
    Map<String, int>? playerColors,
    Map<String, PlayerCountry>? playerCountries,
    Map<String, int>? playerGold,
    List<GameUnit>? units,
    List<GameCity>? cities,
    List<WorldArtifact>? artifacts,
    List<FieldImprovement>? fieldImprovements,
    FogOfWarState? fogOfWar,
    ResearchState? research,
    GameRuntimeState? runtimeState,
  }) {
    return PersistentGameState(
      playerColors: playerColors ?? this.playerColors,
      playerCountries: playerCountries ?? this.playerCountries,
      playerGold: playerGold ?? this.playerGold,
      units: units ?? this.units,
      cities: cities ?? this.cities,
      artifacts: artifacts ?? this.artifacts,
      fieldImprovements: fieldImprovements ?? this.fieldImprovements,
      fogOfWar: fogOfWar ?? this.fogOfWar,
      research: research ?? this.research,
      runtimeState: runtimeState ?? this.runtimeState,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PersistentGameState &&
      mapEquals(other.playerColors, playerColors) &&
      mapEquals(other.playerCountries, playerCountries) &&
      mapEquals(other.playerGold, playerGold) &&
      listEquals(other.units, units) &&
      listEquals(other.cities, cities) &&
      listEquals(other.artifacts, artifacts) &&
      listEquals(other.fieldImprovements, fieldImprovements) &&
      other.fogOfWar == fogOfWar &&
      other.research == research &&
      other.runtimeState == runtimeState;

  @override
  int get hashCode => Object.hash(
    mapHash(playerColors),
    mapHash(playerCountries),
    mapHash(playerGold),
    Object.hashAll(units),
    Object.hashAll(cities),
    Object.hashAll(artifacts),
    Object.hashAll(fieldImprovements),
    fogOfWar,
    research,
    runtimeState,
  );

  PlayerCountry countryForPlayer(String playerId) {
    return playerCountries[playerId] ?? PlayerCountry.poland;
  }

  static Map<String, int> _intMap(Object? value, String field) {
    if (value == null) return const {};
    if (value is! Map<Object?, Object?>) {
      throw ArgumentError.value(
        value,
        'PersistentGameState.$field',
        'Expected a JSON object',
      );
    }
    return {
      for (final entry in value.entries)
        if (entry.key case final String key when key.isNotEmpty)
          key: switch (entry.value) {
            final int number => number,
            final num number => number.toInt(),
            final invalid => throw ArgumentError.value(
              invalid,
              'PersistentGameState.$field.$key',
              'Expected a number',
            ),
          },
    };
  }

  static Map<String, PlayerCountry> _countryMap(Object? value, String field) {
    if (value == null) return const {};
    if (value is! Map<Object?, Object?>) {
      throw ArgumentError.value(
        value,
        'PersistentGameState.$field',
        'Expected a JSON object',
      );
    }
    return {
      for (final entry in value.entries)
        if (entry.key case final String key when key.isNotEmpty)
          key: _countryFromJson(entry.value, '$field.$key'),
    };
  }

  static PlayerCountry _countryFromJson(Object? value, String field) {
    if (value is! String || value.isEmpty) {
      throw ArgumentError.value(
        value,
        'PersistentGameState.$field',
        'Expected a non-empty String',
      );
    }
    for (final country in PlayerCountry.values) {
      if (country.name == value) return country;
    }
    throw ArgumentError.value(
      value,
      'PersistentGameState.$field',
      'Unknown country',
    );
  }

  static List<Map<String, dynamic>> _jsonList(Object? value, String field) {
    if (value == null) return const [];
    if (value is! List) {
      throw ArgumentError.value(
        value,
        'PersistentGameState.$field',
        'Expected a JSON list',
      );
    }
    return [
      for (final entry in value)
        if (entry is Map<String, dynamic>)
          entry
        else if (entry is Map<Object?, Object?>)
          Map<String, dynamic>.from(entry)
        else
          throw ArgumentError.value(
            entry,
            'PersistentGameState.$field[]',
            'Expected a JSON object',
          ),
    ];
  }
}
