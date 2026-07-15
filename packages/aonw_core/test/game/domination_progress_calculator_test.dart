import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('DominationProgressCalculator', () {
    const calculator = DominationProgressCalculator();
    const players = ['player_1', 'player_2'];

    test('calculates control percent over valid domination tiles', () {
      final progress = calculator.snapshot(
        playerIds: players,
        state: const PersistentGameState(
          cities: [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Roma',
              center: CityHex(col: 0, row: 0),
              controlledHexes: [CityHex(col: 1, row: 0)],
            ),
            GameCity(
              id: 'city_2',
              ownerPlayerId: 'player_2',
              name: 'Antium',
              center: CityHex(col: 2, row: 0),
            ),
          ],
        ),
        mapData: _mapData([
          _tile(0, 0),
          _tile(1, 0),
          _tile(2, 0),
          _tile(3, 0, TerrainType.ocean),
        ]),
        victoryRules: VictoryRules.standard,
      );

      expect(progress.validTileCount, 3);
      expect(progress.entryFor('player_1')!.controlledTileCount, 2);
      expect(progress.entryFor('player_1')!.controlPercent, closeTo(66.6, 0.1));
      expect(progress.entryFor('player_2')!.controlledTileCount, 1);
      expect(progress.entryFor('player_2')!.controlPercent, closeTo(33.3, 0.1));
    });

    test(
      'advances hold turns for players above threshold and resets others',
      () {
        final next = calculator.advanceHoldTurns(
          playerIds: players,
          state: const PersistentGameState(
            cities: [
              GameCity(
                id: 'city_1',
                ownerPlayerId: 'player_1',
                name: 'Roma',
                center: CityHex(col: 0, row: 0),
                controlledHexes: [CityHex(col: 1, row: 0)],
              ),
              GameCity(
                id: 'city_2',
                ownerPlayerId: 'player_2',
                name: 'Antium',
                center: CityHex(col: 2, row: 0),
              ),
            ],
          ),
          mapData: _mapData([_tile(0, 0), _tile(1, 0), _tile(2, 0)]),
          victoryRules: VictoryRules.standard.copyWith(
            dominationControlPercent: 60,
            dominationHoldTurns: 3,
          ),
          previousHoldTurnsByPlayerId: const {'player_1': 1, 'player_2': 2},
        );

        expect(next, {'player_1': 2});
      },
    );

    test(
      'does not advance holds when the map has no valid domination tiles',
      () {
        final progress = calculator.snapshot(
          playerIds: players,
          state: const PersistentGameState(
            cities: [
              GameCity(
                id: 'city_1',
                ownerPlayerId: 'player_1',
                name: 'Roma',
                center: CityHex(col: 0, row: 0),
              ),
            ],
          ),
          mapData: _mapData([_tile(0, 0, TerrainType.ocean)]),
          victoryRules: VictoryRules.standard,
        );
        final next = calculator.advanceHoldTurns(
          playerIds: players,
          state: const PersistentGameState(
            cities: [
              GameCity(
                id: 'city_1',
                ownerPlayerId: 'player_1',
                name: 'Roma',
                center: CityHex(col: 0, row: 0),
              ),
            ],
          ),
          mapData: _mapData([_tile(0, 0, TerrainType.ocean)]),
          victoryRules: VictoryRules.standard,
          previousHoldTurnsByPlayerId: const {'player_1': 4},
        );

        expect(progress.validTileCount, 0);
        expect(progress.entryFor('player_1')!.controlPercent, 0);
        expect(next, isEmpty);
      },
    );

    test('emits threshold event only when a domination hold starts', () {
      const state = PersistentGameState(
        cities: [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Roma',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 1, row: 0)],
          ),
          GameCity(
            id: 'city_2',
            ownerPlayerId: 'player_2',
            name: 'Antium',
            center: CityHex(col: 2, row: 0),
          ),
        ],
      );
      final mapData = _mapData([_tile(0, 0), _tile(1, 0), _tile(2, 0)]);
      final rules = VictoryRules.standard.copyWith(
        dominationControlPercent: 60,
        dominationHoldTurns: 3,
      );
      final nextHoldTurns = calculator.advanceHoldTurns(
        playerIds: players,
        state: state,
        mapData: mapData,
        victoryRules: rules,
      );

      final events = calculator.thresholdReachedEvents(
        playerIds: players,
        state: state,
        mapData: mapData,
        victoryRules: rules,
        previousHoldTurnsByPlayerId: const {},
        nextHoldTurnsByPlayerId: nextHoldTurns,
      );
      final repeated = calculator.thresholdReachedEvents(
        playerIds: players,
        state: state,
        mapData: mapData,
        victoryRules: rules,
        previousHoldTurnsByPlayerId: nextHoldTurns,
        nextHoldTurnsByPlayerId: {'player_1': 2},
      );

      expect(events, hasLength(1));
      expect(events.single.playerId, 'player_1');
      expect(events.single.controlPercent, closeTo(66.6, 0.1));
      expect(events.single.requiredControlPercent, 60);
      expect(events.single.holdTurns, 1);
      expect(events.single.requiredHoldTurns, 3);
      expect(repeated, isEmpty);
    });

    test(
      'matches a WorldMap read view for sparse tiles regardless of order',
      () {
        const state = PersistentGameState(
          cities: [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Roma',
              center: CityHex(col: 6, row: 4),
              controlledHexes: [CityHex(col: 1, row: 2)],
            ),
            GameCity(
              id: 'city_2',
              ownerPlayerId: 'player_2',
              name: 'Antium',
              center: CityHex(col: 2, row: 3),
              controlledHexes: [CityHex(col: 7, row: 5)],
            ),
          ],
        );
        final mapData = MapData(
          cols: 8,
          rows: 6,
          tiles: const [
            TileData(
              col: 6,
              row: 4,
              terrains: [TerrainType.grassland],
              resources: [],
              height: 0,
            ),
            TileData(
              col: 1,
              row: 2,
              terrains: [TerrainType.mountain],
              resources: [],
              height: 5,
            ),
            TileData(
              col: 2,
              row: 3,
              terrains: [TerrainType.plains],
              resources: [],
              height: 0,
            ),
            TileData(
              col: 7,
              row: 5,
              terrains: [TerrainType.ocean],
              resources: [],
              height: 0,
            ),
          ],
        );
        final worldMap = _worldMapFromDataInReverse(mapData);
        final legacy = calculator.snapshot(
          playerIds: const ['player_2', 'player_1', 'player_2', ''],
          state: state,
          mapData: mapData,
          victoryRules: VictoryRules.standard,
        );
        final canonical = calculator.snapshot(
          playerIds: const ['player_2', 'player_1', 'player_2', ''],
          state: state,
          mapData: LegacyWorldMapAdapter.asReadView(worldMap),
          victoryRules: VictoryRules.standard,
        );

        expect(_snapshotShape(canonical), _snapshotShape(legacy));
        expect(canonical.validTileCount, 2);
        expect(canonical.entries.map((entry) => entry.playerId), [
          'player_1',
          'player_2',
        ]);
        expect(canonical.entries.map((entry) => entry.controlledTileCount), [
          1,
          1,
        ]);
      },
    );

    test('classifies pace-aware domination warning levels', () {
      expect(
        DominationWarningPolicy.levelFor(
          _entry(controlPercent: 41, requiredPercent: 45, requiredHold: 2),
        ),
        DominationThreatLevel.approachingThreshold,
      );
      expect(
        DominationWarningPolicy.levelFor(
          _entry(controlPercent: 45, requiredPercent: 45, requiredHold: 2),
        ),
        DominationThreatLevel.holdingThreshold,
      );
      expect(
        DominationWarningPolicy.levelFor(
          _entry(
            controlPercent: 45,
            requiredPercent: 45,
            holdTurns: 1,
            requiredHold: 2,
          ),
        ),
        DominationThreatLevel.imminent,
      );
      expect(
        DominationWarningPolicy.levelFor(
          _entry(controlPercent: 59, requiredPercent: 60, requiredHold: 5),
        ),
        isNull,
      );
      expect(
        DominationWarningPolicy.levelFor(
          _entry(
            validTileCount: 0,
            controlPercent: 0,
            requiredPercent: 45,
            requiredHold: 2,
          ),
        ),
        isNull,
      );
    });
  });
}

List<Map<String, Object>> _snapshotShape(DominationProgressSnapshot snapshot) {
  return [
    for (final entry in snapshot.entries)
      {
        'validTileCount': snapshot.validTileCount,
        'playerId': entry.playerId,
        'controlledTileCount': entry.controlledTileCount,
        'controlPercent': entry.controlPercent,
        'holdTurns': entry.holdTurns,
      },
  ];
}

WorldMap _worldMapFromDataInReverse(MapData mapData) {
  return WorldMap(
    cols: mapData.cols,
    rows: mapData.rows,
    tiles: [
      for (final tile in mapData.tiles.reversed)
        WorldTile(
          coordinate: HexCoord(col: tile.col, row: tile.row),
          terrains: tile.terrains,
          resources: tile.resources,
          height: tile.height,
        ),
    ],
  );
}

DominationProgressEntry _entry({
  int validTileCount = 100,
  required double controlPercent,
  required double requiredPercent,
  int holdTurns = 0,
  required int requiredHold,
}) {
  return DominationProgressEntry(
    playerId: 'player_2',
    controlledTileCount: controlPercent.round(),
    validTileCount: validTileCount,
    controlPercent: controlPercent,
    requiredControlPercent: requiredPercent,
    holdTurns: holdTurns,
    requiredHoldTurns: requiredHold,
  );
}

MapData _mapData(List<TileData> tiles) {
  return MapData(cols: tiles.length, rows: 1, tiles: tiles);
}

TileData _tile(
  int col,
  int row, [
  TerrainType terrain = TerrainType.grassland,
]) {
  return TileData(
    col: col,
    row: row,
    terrains: [terrain],
    resources: const [],
    height: 0,
  );
}
