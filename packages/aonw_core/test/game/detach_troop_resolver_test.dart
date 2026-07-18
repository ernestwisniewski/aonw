import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('DetachTroopResolver validation order', () {
    test('rejects a missing unit before reading the map', () {
      final units = <GameUnit>[];
      final mapTiles = _CountingMapTileLookup(
        WorldMapReadView(_worldMap(cols: 3, rows: 3)),
      );

      final result = _detach(
        units: units,
        command: const DetachTroopCommand('missing', TroopType.warrior),
        mapTiles: mapTiles,
      );

      _expectRejectedIdentity(result, units: units, reason: 'unit_not_found');
      expect(mapTiles.readCount, 0);
    });

    test('rejects a wrong actor before reading the map', () {
      final units = <GameUnit>[_commander()];
      final mapTiles = _CountingMapTileLookup(
        WorldMapReadView(_worldMap(cols: 3, rows: 3)),
      );

      final result = _detach(
        units: units,
        command: const DetachTroopCommand('commander_1', TroopType.warrior),
        actorPlayerId: 'player_2',
        mapTiles: mapTiles,
      );

      _expectRejectedIdentity(
        result,
        units: units,
        reason: 'unit_not_controlled',
      );
      expect(mapTiles.readCount, 0);
    });

    test('rejects an unavailable troop before reading the map', () {
      final units = <GameUnit>[_commander()];
      final mapTiles = _CountingMapTileLookup(
        WorldMapReadView(_worldMap(cols: 3, rows: 3)),
      );

      final result = _detach(
        units: units,
        command: const DetachTroopCommand('commander_1', TroopType.archer),
        mapTiles: mapTiles,
      );

      _expectRejectedIdentity(
        result,
        units: units,
        reason: 'troop_not_available',
      );
      expect(mapTiles.readCount, 0);
    });

    test('rejects an out-of-bounds source before searching neighbors', () {
      final units = <GameUnit>[_commander(col: 9, row: 9)];
      final mapTiles = _CountingMapTileLookup(
        WorldMapReadView(_worldMap(cols: 3, rows: 3)),
      );

      final result = _detach(
        units: units,
        command: const DetachTroopCommand('commander_1', TroopType.warrior),
        mapTiles: mapTiles,
      );

      _expectRejectedIdentity(
        result,
        units: units,
        reason: 'detachment_source_out_of_bounds',
      );
      expect(mapTiles.readCount, 1);
    });

    test('preserves every branch by identity when no destination exists', () {
      final units = <GameUnit>[_commander(col: 0, row: 0)];
      final mapTiles = WorldMapReadView(
        _worldMap(cols: 2, rows: 2, included: {const HexCoord(col: 0, row: 0)}),
      );

      final result = _detach(
        units: units,
        command: const DetachTroopCommand('commander_1', TroopType.warrior),
        mapTiles: mapTiles,
        visibility: const FogVisibilityQuery(
          playerId: '',
          state: FogOfWarState.empty,
        ),
      );

      _expectRejectedIdentity(
        result,
        units: units,
        reason: 'detachment_destination_unavailable',
      );
    });
  });

  group('DetachTroopResolver deterministic application', () {
    test('allows a discovered destination that is not currently visible', () {
      final units = <GameUnit>[_commander(col: 1, row: 1)];
      const destination = HexCoordinate(col: 2, row: 1);
      final fogOfWar = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            discoveredHexes: {destination},
          ),
        },
      );

      final result = DetachTroopResolver.detachTroop(
        units: units,
        cities: const [],
        fogOfWar: fogOfWar,
        diplomacy: DiplomacyState.empty,
        playerIds: const ['player_1'],
        command: const DetachTroopCommand('commander_1', TroopType.warrior),
        actorPlayerId: 'player_1',
        mapTiles: WorldMapReadView(_worldMap(cols: 4, rows: 4)),
      );

      expect(result.accepted, isTrue);
      final detached = result.units.singleWhere(
        (unit) => unit.id == 'commander_1_warrior_1',
      );
      expect(detached.coordinate, destination);
    });

    test('skips occupied and blocked neighbors in topology order', () {
      final units = <GameUnit>[
        _commander(col: 1, row: 1),
        _unit(id: 'occupied', col: 2, row: 1),
      ];
      final mapTiles = WorldMapReadView(
        _worldMap(
          cols: 4,
          rows: 4,
          mountains: {const HexCoord(col: 2, row: 2)},
        ),
      );

      final result = _detach(
        units: units,
        command: const DetachTroopCommand('commander_1', TroopType.warrior),
        mapTiles: mapTiles,
        visibility: const FogVisibilityQuery(
          playerId: '',
          state: FogOfWarState.empty,
        ),
      );

      expect(result.accepted, isTrue);
      expect(result.reason, isNull);
      final detached = result.units.singleWhere(
        (unit) => unit.id == 'commander_1_warrior_1',
      );
      expect((detached.col, detached.row), (1, 2));
      expect(result.units.first.troopCount(TroopType.warrior), 0);
    });

    test('uses the first free suffix after existing detached ids', () {
      final units = <GameUnit>[
        _commander(col: 1, row: 1),
        _unit(id: 'commander_1_warrior_1', col: 3, row: 3),
        _unit(id: 'commander_1_warrior_2', col: 3, row: 2),
      ];

      final result = _detach(
        units: units,
        command: const DetachTroopCommand('commander_1', TroopType.warrior),
        mapTiles: WorldMapReadView(_worldMap(cols: 4, rows: 4)),
        visibility: const FogVisibilityQuery(
          playerId: '',
          state: FogOfWarState.empty,
        ),
      );

      expect(result.accepted, isTrue);
      expect(
        result.units.map((unit) => unit.id),
        contains('commander_1_warrior_3'),
      );
    });
  });
}

DetachTroopResult _detach({
  required List<GameUnit> units,
  required DetachTroopCommand command,
  required MapTileLookup mapTiles,
  String actorPlayerId = 'player_1',
  FogVisibilityQuery? visibility,
}) {
  return DetachTroopResolver.detachTroop(
    units: units,
    cities: const [],
    fogOfWar: FogOfWarState.empty,
    diplomacy: DiplomacyState.empty,
    playerIds: const ['player_1', 'player_2'],
    command: command,
    actorPlayerId: actorPlayerId,
    mapTiles: mapTiles,
    visibility: visibility,
  );
}

void _expectRejectedIdentity(
  DetachTroopResult result, {
  required List<GameUnit> units,
  required String reason,
}) {
  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(identical(result.units, units), isTrue);
  expect(identical(result.fogOfWar, FogOfWarState.empty), isTrue);
  expect(identical(result.diplomacy, DiplomacyState.empty), isTrue);
}

GameUnit _commander({int col = 1, int row = 1}) {
  return GameUnit(
    id: 'commander_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.commander,
    name: GameUnitType.commander.defaultNameToken,
    col: col,
    row: row,
    army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
  );
}

GameUnit _unit({required String id, required int col, required int row}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: col,
    row: row,
  );
}

WorldMap _worldMap({
  required int cols,
  required int rows,
  Set<HexCoord> mountains = const {},
  Set<HexCoord>? included,
}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          if (included == null ||
              included.contains(HexCoord(col: col, row: row)))
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: [
                if (mountains.contains(HexCoord(col: col, row: row)))
                  TerrainType.mountain
                else
                  TerrainType.grassland,
              ],
              resources: const [],
              height: 0,
            ),
    ],
  );
}

final class _CountingMapTileLookup implements MapTileLookup {
  _CountingMapTileLookup(this.delegate);

  final MapTileLookup delegate;
  int readCount = 0;

  @override
  MapTileView? tileAt(int col, int row) {
    readCount += 1;
    return delegate.tileAt(col, row);
  }
}
