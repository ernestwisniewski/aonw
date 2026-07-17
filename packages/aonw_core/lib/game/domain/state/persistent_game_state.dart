import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:aonw_core/util/collection_equality.dart';

part 'persistent_game_state_codec.dart';
part 'persistent_game_state_copying.dart';
part 'persistent_game_state_value.dart';

final class PersistentGameState with _PersistentGameStateCopying {
  /// Legacy const constructor retained for compile-time fixtures.
  /// Runtime code must use [PersistentGameState.snapshot].
  const PersistentGameState({
    this.playerColors = const {},
    this.playerCountries = const {},
    this.playerGold = const {},
    this.playerWarWeariness = const {},
    this.playerStabilityNet = const {},
    this.units = const [],
    this.cities = const [],
    this.artifacts = const [],
    this.fieldImprovements = const [],
    this.fogOfWar = FogOfWarState.empty,
    this.research = ResearchState.empty,
    this.runtimeState = GameRuntimeState.empty,
    this.wonderRegistry = WonderRegistry.empty,
  }) : _isImmutableSnapshot = false;

  PersistentGameState.snapshot({
    Map<String, int> playerColors = const {},
    Map<String, PlayerCountry> playerCountries = const {},
    Map<String, int> playerGold = const {},
    Map<String, int> playerWarWeariness = const {},
    Map<String, int> playerStabilityNet = const {},
    List<GameUnit> units = const [],
    List<GameCity> cities = const [],
    List<WorldArtifact> artifacts = const [],
    List<FieldImprovement> fieldImprovements = const [],
    this.fogOfWar = FogOfWarState.empty,
    this.research = ResearchState.empty,
    GameRuntimeState runtimeState = GameRuntimeState.empty,
    this.wonderRegistry = WonderRegistry.empty,
  }) : playerColors = _immutablePersistentMap(playerColors),
       playerCountries = _immutablePersistentMap(playerCountries),
       playerGold = _immutablePersistentMap(playerGold),
       playerWarWeariness = _immutablePersistentMap(playerWarWeariness),
       playerStabilityNet = _immutablePersistentMap(playerStabilityNet),
       units = _immutablePersistentList(units),
       cities = _immutablePersistentCities(cities),
       artifacts = _immutablePersistentList(artifacts),
       fieldImprovements = _immutablePersistentList(fieldImprovements),
       runtimeState = runtimeState.immutableSnapshot(),
       _isImmutableSnapshot = true;

  const PersistentGameState._owned({
    this.playerColors = const {},
    this.playerCountries = const {},
    this.playerGold = const {},
    this.playerWarWeariness = const {},
    this.playerStabilityNet = const {},
    this.units = const [],
    this.cities = const [],
    this.artifacts = const [],
    this.fieldImprovements = const [],
    this.fogOfWar = FogOfWarState.empty,
    this.research = ResearchState.empty,
    this.runtimeState = GameRuntimeState.empty,
    this.wonderRegistry = WonderRegistry.empty,
  }) : _isImmutableSnapshot = true;

  factory PersistentGameState.fromJson(Map<String, dynamic> json) {
    return PersistentGameState.snapshot(
      playerColors: _intMap(json['playerColors'], 'playerColors'),
      playerCountries: _countryMap(json['playerCountries'], 'playerCountries'),
      playerGold: _intMap(json['playerGold'], 'playerGold'),
      playerWarWeariness: _intMap(
        json['playerWarWeariness'],
        'playerWarWeariness',
      ),
      playerStabilityNet: _intMap(
        json['playerStabilityNet'],
        'playerStabilityNet',
      ),
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
      wonderRegistry: WonderRegistry.fromJson(json['wonderRegistry']),
    );
  }

  @override
  final Map<String, int> playerColors;
  @override
  final Map<String, PlayerCountry> playerCountries;
  @override
  final Map<String, int> playerGold;
  @override
  final Map<String, int> playerWarWeariness;
  @override
  final Map<String, int> playerStabilityNet;
  @override
  final List<GameUnit> units;
  @override
  final List<GameCity> cities;
  @override
  final List<WorldArtifact> artifacts;
  @override
  final List<FieldImprovement> fieldImprovements;
  @override
  final FogOfWarState fogOfWar;
  @override
  final ResearchState research;
  @override
  final GameRuntimeState runtimeState;
  @override
  final WonderRegistry wonderRegistry;
  @override
  final bool _isImmutableSnapshot;

  Set<String> get knownPlayerIds => <String>{
    ...playerColors.keys,
    ...playerCountries.keys,
    ...playerGold.keys,
    ...playerWarWeariness.keys,
    ...playerStabilityNet.keys,
    ...fogOfWar.playerIds,
    ...runtimeState.submittedPlayerIds,
    ...wonderRegistry.completedBy.values,
    ...runtimeState.dominationHoldTurnsByPlayerId.keys,
    ...runtimeState.culturalVictoryHoldTurnsByPlayerId.keys,
    for (final unit in units) unit.ownerPlayerId,
    for (final city in cities) city.ownerPlayerId,
    for (final city in cities) ?city.foundingOwnerPlayerId,
    for (final relation in runtimeState.diplomacy.relations.values)
      relation.playerAId,
    for (final relation in runtimeState.diplomacy.relations.values)
      relation.playerBId,
  }..removeWhere((playerId) => playerId.isEmpty);

  Map<String, dynamic> toJson() => {
    'playerColors': {...playerColors},
    'playerCountries': playerCountries.map(
      (playerId, country) => MapEntry(playerId, country.name),
    ),
    'playerGold': {...playerGold},
    'playerWarWeariness': {...playerWarWeariness},
    'playerStabilityNet': {...playerStabilityNet},
    'units': units.map((unit) => unit.toJson()).toList(),
    'cities': cities.map((city) => city.toJson()).toList(),
    'artifacts': artifacts.map((artifact) => artifact.toJson()).toList(),
    'fieldImprovements': fieldImprovements
        .map((improvement) => improvement.toJson())
        .toList(),
    'fogOfWar': fogOfWar.toJson(),
    'research': research.toJson(),
    'runtimeState': runtimeState.toJson(),
    if (wonderRegistry.completedBy.isNotEmpty)
      'wonderRegistry': wonderRegistry.toJson(),
  };

  PersistentGameState withoutClientInteractionState() {
    return copyWith(runtimeState: runtimeState.withoutClientInteractionState());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersistentGameState && _samePersistentState(this, other);

  @override
  int get hashCode => Object.hash(
    mapHash(playerColors),
    mapHash(playerCountries),
    mapHash(playerGold),
    mapHash(playerWarWeariness),
    mapHash(playerStabilityNet),
    Object.hashAll(units),
    Object.hashAll(cities),
    Object.hashAll(artifacts),
    Object.hashAll(fieldImprovements),
    fogOfWar,
    research,
    runtimeState,
    wonderRegistry,
  );

  PlayerCountry countryForPlayer(String playerId) {
    return playerCountries[playerId] ?? PlayerCountry.poland;
  }
}
