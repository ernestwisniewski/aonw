part of '../basic_strategy_test.dart';

DomainState _pressuredThirdCityEscortState(WorldMap mapData) {
  return DomainState.snapshot(
    units: [
      GameUnit.produced(
        id: 'settler_player_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        col: 4,
        row: 5,
      ),
      GameUnit.produced(
        id: 'escort_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 7,
        row: 3,
      ),
      GameUnit.produced(
        id: 'capital_guard',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 1,
      ),
      GameUnit.produced(
        id: 'second_guard',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 7,
        row: 1,
      ),
      GameUnit.produced(
        id: 'enemy_warrior',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 5,
        row: 7,
      ),
    ],
    cities: const [
      GameCity(
        id: 'capital',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      ),
      GameCity(
        id: 'second',
        ownerPlayerId: 'player_1',
        name: 'Second',
        center: CityHex(col: 7, row: 0),
      ),
    ],
    fogOfWar: FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(
          playerId: 'player_1',
          visibleHexes: _allHexesIn(mapData),
        ),
      },
    ),
  );
}

DomainState _thirdCityScoutDiscoveryState(WorldMap mapData) {
  final visible = {
    for (final tile in mapData.tiles)
      if (const [
        HexCoordinate(col: 0, row: 0),
        HexCoordinate(col: 7, row: 0),
        HexCoordinate(col: 3, row: 2),
      ].any(
        (origin) =>
            HexDistance.between(HexCoordinate.fromTile(tile), origin) <= 2,
      ))
        HexCoordinate.fromTile(tile),
  };
  return DomainState.snapshot(
    units: [
      GameUnit.produced(
        id: 'settler_player_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.settler,
        col: 1,
        row: 0,
      ),
      GameUnit.produced(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        col: 3,
        row: 2,
      ),
      GameUnit.produced(
        id: 'warrior_capital',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ),
      GameUnit.produced(
        id: 'warrior_second',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 7,
        row: 0,
      ),
    ],
    cities: const [
      GameCity(
        id: 'capital',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      ),
      GameCity(
        id: 'second',
        ownerPlayerId: 'player_1',
        name: 'Second',
        center: CityHex(col: 7, row: 0),
      ),
    ],
    fogOfWar: FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(playerId: 'player_1', visibleHexes: visible),
      },
    ),
  );
}

DomainState _blockedThirdCityScoutProductionState() {
  return DomainState.snapshot(
    units: [
      for (final unit in const [
        ('settler_1', GameUnitType.settler, 6, 0),
        ('capital_guard', GameUnitType.warrior, 6, 1),
        ('second_guard', GameUnitType.warrior, 8, 3),
        ('worker_1', GameUnitType.worker, 6, 1),
        ('worker_2', GameUnitType.worker, 8, 3),
      ])
        GameUnit.produced(
          id: unit.$1,
          ownerPlayerId: 'player_1',
          type: unit.$2,
          col: unit.$3,
          row: unit.$4,
        ),
    ],
    cities: const [
      GameCity(
        id: 'capital',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 6, row: 1),
      ),
      GameCity(
        id: 'second',
        ownerPlayerId: 'player_1',
        name: 'Second',
        center: CityHex(col: 8, row: 3),
      ),
      GameCity(
        id: 'enemy_north',
        ownerPlayerId: 'player_2',
        name: 'Enemy North',
        center: CityHex(col: 3, row: 0),
      ),
      GameCity(
        id: 'enemy_west',
        ownerPlayerId: 'player_2',
        name: 'Enemy West',
        center: CityHex(col: 2, row: 3),
      ),
      GameCity(
        id: 'enemy_south',
        ownerPlayerId: 'player_3',
        name: 'Enemy South',
        center: CityHex(col: 6, row: 5),
      ),
    ],
    fogOfWar: FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(
          playerId: 'player_1',
          visibleHexes: {
            const HexCoordinate(col: 6, row: 0),
            const HexCoordinate(col: 6, row: 1),
            const HexCoordinate(col: 8, row: 3),
          },
          discoveredHexes: {
            const HexCoordinate(col: 3, row: 0),
            const HexCoordinate(col: 2, row: 3),
            const HexCoordinate(col: 6, row: 5),
          },
        ),
      },
    ),
  );
}
