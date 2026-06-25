import 'dart:convert';
import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('world artifacts', () {
    test('artifact generation ignores unreachable passable tiles', () {
      final mapData = MapData(
        cols: 7,
        rows: 3,
        tiles: [
          for (var row = 0; row < 3; row++)
            for (var col = 0; col < 7; col++)
              _artifactTestTile(
                col,
                row,
                terrains: row == 1 && col <= 4
                    ? const [TerrainType.grassland]
                    : row == 1 && col == 6
                    ? const [TerrainType.grassland, TerrainType.hills]
                    : const [TerrainType.ocean],
                height: row == 1 && col == 6 ? 5 : 0,
              ),
        ],
      );
      final scout = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 0,
        row: 1,
      );

      final artifacts = WorldArtifactGenerator.generate(
        mapData: mapData,
        startingUnits: [scout],
        seed: 1,
      );
      final artifactLocations = {
        for (final artifact in artifacts)
          '${artifact.location.col}:${artifact.location.row}',
      };

      expect(artifacts, isNotEmpty);
      expect(artifactLocations, isNot(contains('6:1')));
      expect(
        artifactLocations.difference(const {'1:1', '2:1', '3:1', '4:1'}),
        isEmpty,
      );
    });

    test(
      'artifact generation ignores tiles beyond starting unit movement capacity',
      () {
        final mapData = MapData(
          cols: 3,
          rows: 2,
          tiles: [
            for (var row = 0; row < 2; row++)
              for (var col = 0; col < 3; col++)
                _artifactTestTile(
                  col,
                  row,
                  terrains: row == 0 && col == 1
                      ? const [
                          TerrainType.snow,
                          TerrainType.forest,
                          TerrainType.hills,
                        ]
                      : const [TerrainType.grassland],
                  resources: row == 0 && col == 1
                      ? const [ResourceType.coal]
                      : const [],
                  height: row == 0 && col == 1 ? 5 : 0,
                ),
          ],
        );
        final warrior = GameUnit.startingWarrior(
          ownerPlayerId: 'p1',
          col: 0,
          row: 0,
        );

        final artifacts = WorldArtifactGenerator.generate(
          mapData: mapData,
          startingUnits: [warrior],
          seed: 1,
        );
        final artifactLocations = {
          for (final artifact in artifacts)
            '${artifact.location.col}:${artifact.location.row}',
        };

        expect(artifacts, isNotEmpty);
        expect(artifactLocations, isNot(contains('1:0')));
      },
    );

    test('artifact generation avoids the Verdantia coal ridge', () {
      final mapData = _loadMapData('assets/maps/verdantia/map.json');
      final ridgeCoal = mapData.tiles.singleWhere(
        (tile) =>
            tile.col == 16 &&
            tile.row == 1 &&
            tile.resources.contains(ResourceType.coal),
      );
      expect(ridgeCoal.resources, contains(ResourceType.coal));

      const players = [
        Player(id: 'p1', name: 'P1', colorValue: 0xFF000001),
        Player(id: 'p2', name: 'P2', colorValue: 0xFF000002),
      ];
      for (var seed = 1; seed <= 20; seed++) {
        final units = StartingUnits.unitsForPlayers(
          players,
          mapData: mapData,
          startPositionSeed: seed,
        );
        final artifacts = WorldArtifactGenerator.generate(
          mapData: mapData,
          startingUnits: units,
          seed: seed,
        );
        final artifactLocations = {
          for (final artifact in artifacts)
            '${artifact.location.col}:${artifact.location.row}',
        };

        expect(artifactLocations, isNot(contains('16:1')));
      }
    });

    test('artifact generation avoids map objective hexes', () {
      final mapData = MapData(
        cols: 5,
        rows: 1,
        objectives: const [
          MapObjectiveDefinition(
            id: 'pass_1',
            type: MapObjectiveType.strategicPass,
            hex: CityHex(col: 2, row: 0),
            requiredHoldTurns: 2,
          ),
        ],
        tiles: [
          for (var col = 0; col < 5; col++)
            _artifactTestTile(
              col,
              0,
              terrains: col == 2
                  ? const [
                      TerrainType.grassland,
                      TerrainType.hills,
                      TerrainType.forest,
                    ]
                  : const [TerrainType.grassland],
              height: col == 2 ? 9 : 0,
            ),
        ],
      );
      final scout = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 0,
        row: 0,
      );

      final artifacts = WorldArtifactGenerator.generate(
        mapData: mapData,
        startingUnits: [scout],
        seed: 3,
      );
      final artifactLocations = {
        for (final artifact in artifacts)
          '${artifact.location.col}:${artifact.location.row}',
      };

      expect(artifacts, isNotEmpty);
      expect(artifactLocations, isNot(contains('2:0')));
    });

    test('artifact excavation starts a two-turn worker-style job', () {
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.astronomersTablets,
        col: 2,
        row: 3,
      );
      final scout = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 2,
        row: 3,
        movementPoints: 5,
      );
      final state = PersistentGameState(units: [scout], artifacts: [artifact]);

      final result = const PersistentArtifactCommandResolver().startExcavation(
        state: state,
        command: const StartArtifactExcavationCommand('scout_1'),
        actorPlayerId: 'p1',
      );

      expect(result.accepted, isTrue);
      expect(result.state.units.single.carriedArtifactId, isNull);
      expect(result.state.units.single.excavatingArtifactId, artifact.id);
      expect(result.state.units.single.movementPoints, 0);
      expect(result.state.artifacts.single.location.isBeingExcavated, isTrue);
      expect(result.state.artifacts.single.location.remainingTurns, 2);

      final pending = PersistentArtifactTurnProcessor.advanceForPlayers(
        state: result.state,
        playerIds: const ['p1'],
      );

      expect(pending.changed, isTrue);
      expect(pending.state.units.single.excavatingArtifactId, artifact.id);
      expect(pending.state.units.single.carriedArtifactId, isNull);
      expect(pending.state.artifacts.single.location.remainingTurns, 1);

      final completed = PersistentArtifactTurnProcessor.advanceForPlayers(
        state: pending.state,
        playerIds: const ['p1'],
      );

      expect(completed.changed, isTrue);
      expect(completed.state.units.single.excavatingArtifactId, isNull);
      expect(completed.state.units.single.carriedArtifactId, artifact.id);
      expect(completed.state.artifacts.single.location.isCarried, isTrue);
    });

    test('excavation requires standing exactly on the artifact hex', () {
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.astronomersTablets,
        col: 2,
        row: 3,
      );
      final adjacentScout = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'p1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 2,
        row: 2,
      );
      final state = PersistentGameState(
        units: [adjacentScout],
        artifacts: [artifact],
      );

      final result = const PersistentArtifactCommandResolver().startExcavation(
        state: state,
        command: const StartArtifactExcavationCommand('scout_1'),
        actorPlayerId: 'p1',
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'artifact_not_found');
      expect(result.state.artifacts.single.location.isOnMap, isTrue);
      expect(result.state.units.single.carriedArtifactId, isNull);
    });

    test('all unit types use the same two-turn excavation timing', () {
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.heroSword,
        col: 1,
        row: 1,
      );
      final warrior = GameUnit.startingWarrior(
        ownerPlayerId: 'p1',
        col: 1,
        row: 1,
      );
      final state = PersistentGameState(
        units: [warrior],
        artifacts: [artifact],
      );

      final excavation = const PersistentArtifactCommandResolver()
          .startExcavation(
            state: state,
            command: StartArtifactExcavationCommand(warrior.id),
            actorPlayerId: 'p1',
          );
      expect(excavation.accepted, isTrue);
      expect(excavation.state.units.single.excavatingArtifactId, artifact.id);
      expect(
        excavation.state.artifacts.single.location.isBeingExcavated,
        isTrue,
      );
      expect(excavation.state.artifacts.single.location.remainingTurns, 2);

      final pending = PersistentArtifactTurnProcessor.advanceForPlayers(
        state: excavation.state,
        playerIds: const ['p1'],
      );

      expect(pending.changed, isTrue);
      expect(pending.state.units.single.excavatingArtifactId, artifact.id);
      expect(pending.state.units.single.carriedArtifactId, isNull);
      expect(pending.state.artifacts.single.location.remainingTurns, 1);

      final completed = PersistentArtifactTurnProcessor.advanceForPlayers(
        state: pending.state,
        playerIds: const ['p1'],
      );

      expect(completed.changed, isTrue);
      expect(completed.state.units.single.excavatingArtifactId, isNull);
      expect(completed.state.units.single.carriedArtifactId, artifact.id);
      expect(completed.state.artifacts.single.location.isCarried, isTrue);
    });

    test('a city stores only one artifact', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'p1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      );
      final unit = GameUnit.startingWarrior(ownerPlayerId: 'p1');
      final carried = WorldArtifact(
        id: WorldArtifact.idForType(WorldArtifactType.heroSword),
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.carried(unitId: unit.id),
      );
      const stored = WorldArtifact(
        id: 'stored',
        type: WorldArtifactType.merchantsSeal,
        location: WorldArtifactLocation.stored(cityId: 'city_1'),
      );
      final state = PersistentGameState(
        units: [unit.copyWithCarriedArtifact(carried.id)],
        cities: [city],
        artifacts: [carried, stored],
      );

      final result = const PersistentArtifactCommandResolver().storeInCity(
        state: state,
        command: StoreArtifactInCityCommand(unit.id),
        actorPlayerId: 'p1',
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_artifact_slot_full');
    });

    test('one-sided artifact offers transfer only actor assets', () {
      const playerCity = GameCity(
        id: 'city_p1',
        ownerPlayerId: 'p1',
        name: 'Player City',
        center: CityHex(col: 0, row: 0),
      );
      const targetCity = GameCity(
        id: 'city_p2',
        ownerPlayerId: 'p2',
        name: 'Target City',
        center: CityHex(col: 3, row: 0),
      );
      const artifact = WorldArtifact(
        id: 'offered_artifact',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.stored(cityId: 'city_p1'),
      );
      const state = PersistentGameState(
        playerGold: {'p1': 10, 'p2': 1},
        cities: [playerCity, targetCity],
        artifacts: [artifact],
      );

      final result = const PersistentArtifactCommandResolver().tradeArtifact(
        state: state,
        command: const TradeArtifactCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          offeredArtifactId: 'offered_artifact',
          offeredGold: 3,
        ),
        actorPlayerId: 'p1',
      );

      expect(result.accepted, isTrue);
      expect(result.state.playerGold, {'p1': 7, 'p2': 4});
      expect(result.state.artifacts.single.location.cityId, 'city_p2');
    });

    test('artifact trades cannot request target assets without acceptance', () {
      const playerCity = GameCity(
        id: 'city_p1',
        ownerPlayerId: 'p1',
        name: 'Player City',
        center: CityHex(col: 0, row: 0),
      );
      const targetCity = GameCity(
        id: 'city_p2',
        ownerPlayerId: 'p2',
        name: 'Target City',
        center: CityHex(col: 3, row: 0),
      );
      const offered = WorldArtifact(
        id: 'offered_artifact',
        type: WorldArtifactType.heroSword,
        location: WorldArtifactLocation.stored(cityId: 'city_p1'),
      );
      const requested = WorldArtifact(
        id: 'requested_artifact',
        type: WorldArtifactType.queensMirror,
        location: WorldArtifactLocation.stored(cityId: 'city_p2'),
      );
      const state = PersistentGameState(
        playerGold: {'p1': 10, 'p2': 20},
        cities: [playerCity, targetCity],
        artifacts: [offered, requested],
      );

      final result = const PersistentArtifactCommandResolver().tradeArtifact(
        state: state,
        command: const TradeArtifactCommand(
          playerId: 'p1',
          targetPlayerId: 'p2',
          offeredArtifactId: 'offered_artifact',
          requestedArtifactId: 'requested_artifact',
          requestedGold: 5,
        ),
        actorPlayerId: 'p1',
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'artifact_trade_requires_acceptance');
      expect(result.state.playerGold, state.playerGold);
      expect(result.state.artifacts, state.artifacts);
    });

    test(
      'cultural hold turns reset when a player drops below six artifacts',
      () {
        final cities = [
          for (var i = 0; i < 6; i++)
            GameCity(
              id: 'city_$i',
              ownerPlayerId: 'p1',
              name: 'City $i',
              center: CityHex(col: i, row: 0),
            ),
        ];
        final artifacts = [
          for (var i = 0; i < 6; i++)
            WorldArtifact(
              id: 'artifact_$i',
              type: WorldArtifactType.values[i],
              location: WorldArtifactLocation.stored(cityId: cities[i].id),
            ),
        ];

        final full = PersistentGameState(cities: cities, artifacts: artifacts);
        final advanced = CulturalVictoryProgressCalculator.advanceHoldTurns(
          playerIds: const ['p1'],
          state: full,
          previousHoldTurnsByPlayerId: const {'p1': 4},
        );
        expect(advanced['p1'], 5);

        final incomplete = full.copyWith(artifacts: artifacts.take(5).toList());
        final reset = CulturalVictoryProgressCalculator.advanceHoldTurns(
          playerIds: const ['p1'],
          state: incomplete,
          previousHoldTurnsByPlayerId: advanced,
        );
        expect(reset.containsKey('p1'), isFalse);
      },
    );

    test('outcome detector awards cultural victory after the hold timer', () {
      final culturalCities = [
        for (var i = 0; i < 6; i++)
          GameCity(
            id: 'city_$i',
            ownerPlayerId: 'p1',
            name: 'City $i',
            center: CityHex(col: i, row: 0),
          ),
      ];
      const rivalCity = GameCity(
        id: 'rival_city',
        ownerPlayerId: 'p2',
        name: 'Rival',
        center: CityHex(col: 9, row: 0),
      );
      final artifacts = [
        for (var i = 0; i < 6; i++)
          WorldArtifact(
            id: 'artifact_$i',
            type: WorldArtifactType.values[i],
            location: WorldArtifactLocation.stored(
              cityId: culturalCities[i].id,
            ),
          ),
      ];
      final state = PersistentGameState(
        cities: [...culturalCities, rivalCity],
        artifacts: artifacts,
        runtimeState: const GameRuntimeState(
          culturalVictoryHoldTurnsByPlayerId: {'p1': 5},
        ),
      );

      final outcome = const GameOutcomeDetector().evaluate(
        playerIds: const ['p1', 'p2'],
        state: state,
      );

      expect(outcome.condition, GameOutcomeCondition.cultural);
      expect(outcome.winnerPlayerId, 'p1');
    });

    test('stored artifacts contribute city yield bonuses', () {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'p1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      );
      final artifacts = [
        const WorldArtifact(
          id: 'seal',
          type: WorldArtifactType.merchantsSeal,
          location: WorldArtifactLocation.stored(cityId: 'city_1'),
        ),
      ];

      final yield = WorldArtifactBonuses.cityYieldFor(
        cityId: city.id,
        artifacts: artifacts,
      );

      expect(yield.gold, 2);
      expect(yield.food, 0);
    });
  });
}

TileData _artifactTestTile(
  int col,
  int row, {
  required List<TerrainType> terrains,
  List<ResourceType> resources = const [],
  int height = 0,
}) {
  return TileData(
    col: col,
    row: row,
    terrains: terrains,
    resources: resources,
    height: height,
  );
}

MapData _loadMapData(String path) {
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  final tilesJson = json['tiles']! as List<Object?>;
  return MapData(
    cols: json['cols']! as int,
    rows: json['rows']! as int,
    mapName: json['mapName'] as String?,
    defaultZoom: (json['defaultZoom'] as num?)?.toDouble() ?? 1.0,
    tiles: [
      for (final rawTile in tilesJson)
        _tileFromJson(rawTile! as Map<String, Object?>),
    ],
  );
}

TileData _tileFromJson(Map<String, Object?> json) {
  return TileData(
    col: json['col']! as int,
    row: json['row']! as int,
    terrains: [
      for (final terrain in json['terrains']! as List<Object?>)
        TerrainType.fromString(terrain! as String),
    ],
    resources: [
      for (final resource in json['resources']! as List<Object?>)
        ResourceType.fromString(resource! as String),
    ],
    height: json['height']! as int,
  );
}
