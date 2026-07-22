import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentTurnMovementProcessor queued city movement', () {
    test('queued movement never enters a known foreign city center', () {
      final commander = _queuedCommander(targetCol: 2);
      const city = GameCity(
        id: 'foreign_city',
        ownerPlayerId: 'player_2',
        name: 'Foreign city',
        center: CityHex(col: 1, row: 0),
      );

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(units: [commander], cities: const [city]),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 3, rows: 1),
      );
      final stopped = result.state.units.single;

      expect((stopped.col, stopped.row), (0, 0));
      expect(stopped.queuedPath, isNull);
    });

    test('queued movement stops before a hidden foreign city', () {
      final commander = _queuedCommander(targetCol: 2);
      const city = GameCity(
        id: 'hidden_foreign_city',
        ownerPlayerId: 'player_2',
        name: 'Hidden foreign city',
        center: CityHex(col: 1, row: 0),
      );
      final fog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {const HexCoordinate(col: 0, row: 0)},
          ),
        },
      );

      final result = PersistentTurnMovementProcessor.resetForPlayers(
        state: PersistentGameState(
          units: [commander],
          cities: const [city],
          fogOfWar: fog,
        ),
        playerIds: const ['player_1'],
        mapData: _mapData(cols: 3, rows: 1),
      );
      final stopped = result.state.units.single;

      expect((stopped.col, stopped.row), (0, 0));
      expect(stopped.queuedPath?.targetCol, 2);
    });
  });
}

GameUnit _queuedCommander({required int targetCol}) {
  return GameUnit.startingCommander(ownerPlayerId: 'player_1')
      .copyWith(movementPoints: 0)
      .copyWithQueuedPath(
        QueuedMovePath(
          targetCol: targetCol,
          targetRow: 0,
          steps: [
            for (var col = 0; col <= targetCol; col++)
              UnitMovementStep(
                col: col,
                row: 0,
                enterCost: col == 0 ? 0 : 1,
                cumulativeCost: col,
              ),
          ],
        ),
      );
}

MapData _mapData({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
