import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentCityFoundingResolver', () {
    test('schedules a city from a controlled settler command intent', () {
      final state = PersistentGameState(
        playerColors: const {'player_1': 0xff0000},
        playerCountries: const {'player_1': PlayerCountry.japan},
        fogOfWar: FogOfWarState(
          players: {'player_1': PlayerFogOfWar(playerId: 'player_1')},
        ),
        units: [_settler()],
      );

      final result = const PersistentCityFoundingResolver().foundCity(
        state: state,
        command: const FoundCityCommand(
          'settler_1',
          controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
        ),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isTrue);
      expect(result.state.units.single.cityFoundingJob, isNotNull);
      expect(result.state.cities, isEmpty);
      expect(result.events, isEmpty);

      final advanced = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: result.state,
        playerIds: const ['player_1'],
        mapData: _mapData(),
      );

      expect(advanced.state.units, isEmpty);
      expect(advanced.state.cities, hasLength(1));
      final city = advanced.state.cities.single;
      expect(city.id, 'city_player_1_0_0');
      expect(city.name, 'Tokyo');
      expect(city.ownerPlayerId, 'player_1');
      expect(city.controlledHexes, [
        const CityHex(col: 1, row: 0),
        const CityHex(col: 0, row: 1),
      ]);
      expect(
        advanced.state.fogOfWar.isVisible(
          'player_1',
          const HexCoordinate(col: 0, row: 0),
        ),
        isTrue,
      );
      expect(advanced.events.single, isA<CityFoundedEvent>());
    });

    test('consumes a settler troop from a commander founder next turn', () {
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        army: const [ArmyTroop(type: TroopType.settler, count: 1)],
      );
      final state = PersistentGameState(units: [commander]);

      final result = const PersistentCityFoundingResolver().foundCity(
        state: state,
        command: const FoundCityCommand(
          'commander_player_1',
          controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
        ),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isTrue);
      expect(result.state.units.single.cityFoundingJob, isNotNull);
      expect(result.state.units.single.troopCount(TroopType.settler), 1);
      expect(result.state.cities, isEmpty);

      final advanced = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: result.state,
        playerIds: const ['player_1'],
        mapData: _mapData(),
      );

      expect(advanced.state.units.single.troopCount(TroopType.settler), 0);
      expect(advanced.state.units.single.cityFoundingJob, isNull);
      expect(advanced.state.cities, hasLength(1));
    });

    test('rejects founding for another player founder', () {
      final state = PersistentGameState(units: [_settler(owner: 'player_2')]);

      final result = const PersistentCityFoundingResolver().foundCity(
        state: state,
        command: const FoundCityCommand(
          'settler_1',
          controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
        ),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_founder_not_controlled');
      expect(result.state, state);
    });

    test('rejects invalid controlled hex payload', () {
      final state = PersistentGameState(units: [_settler()]);

      final result = const PersistentCityFoundingResolver().foundCity(
        state: state,
        command: const FoundCityCommand(
          'settler_1',
          controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 1, row: 0)],
        ),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_controlled_hexes_invalid');
      expect(result.state, state);
    });

    test('rejects founding next to an existing city center', () {
      final state = PersistentGameState(
        units: [_settler(col: 2, row: 2)],
        cities: const [
          GameCity(
            id: 'city_player_1_3_2',
            ownerPlayerId: 'player_1',
            name: 'Tokyo',
            center: CityHex(col: 3, row: 2),
          ),
        ],
      );

      final result = const PersistentCityFoundingResolver().foundCity(
        state: state,
        command: const FoundCityCommand(
          'settler_1',
          controlledHexes: [CityHex(col: 2, row: 1), CityHex(col: 1, row: 2)],
        ),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_center_too_close');
      expect(result.state, state);
    });

    test('rejects founding at distance two from an existing city center', () {
      final state = PersistentGameState(
        units: [_settler(col: 1, row: 2)],
        cities: const [
          GameCity(
            id: 'city_player_1_3_2',
            ownerPlayerId: 'player_1',
            name: 'Tokyo',
            center: CityHex(col: 3, row: 2),
          ),
        ],
      );

      final result = const PersistentCityFoundingResolver().foundCity(
        state: state,
        command: const FoundCityCommand(
          'settler_1',
          controlledHexes: [CityHex(col: 1, row: 1), CityHex(col: 0, row: 2)],
        ),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isFalse);
      expect(result.reason, 'city_center_too_close');
      expect(result.state, state);
    });

    test('allows founding at distance three from an existing city center', () {
      final state = PersistentGameState(
        units: [_settler(col: 0, row: 2)],
        cities: const [
          GameCity(
            id: 'city_player_1_3_2',
            ownerPlayerId: 'player_1',
            name: 'Tokyo',
            center: CityHex(col: 3, row: 2),
          ),
        ],
      );

      final result = const PersistentCityFoundingResolver().foundCity(
        state: state,
        command: const FoundCityCommand(
          'settler_1',
          controlledHexes: [CityHex(col: 0, row: 1), CityHex(col: 1, row: 2)],
        ),
        actorPlayerId: 'player_1',
        mapDefinition: _mapDefinition(),
      );

      expect(result.accepted, isTrue);
    });
  });
}

MapData _mapData() {
  final definition = _mapDefinition();
  return MapData(
    cols: definition.cols,
    rows: definition.rows,
    mapName: definition.mapName,
    tiles: [
      for (final tile in definition.tiles)
        TileData(
          col: tile.col,
          row: tile.row,
          terrains: tile.terrains,
          resources: tile.resources,
          height: tile.height,
        ),
    ],
  );
}

GameUnit _settler({String owner = 'player_1', int col = 0, int row = 0}) {
  return GameUnit(
    id: 'settler_1',
    ownerPlayerId: owner,
    type: GameUnitType.settler,
    name: 'Settler',
    col: col,
    row: row,
  );
}

MapDefinition _mapDefinition() {
  return MapDefinition(
    cols: 4,
    rows: 4,
    mapName: 'duel',
    tiles: [
      for (var row = 0; row < 4; row++)
        for (var col = 0; col < 4; col++)
          MapTileDefinition(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
