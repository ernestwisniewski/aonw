import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyIdleSweepPlanner', () {
    test('fortifies an idle military unit guarding a city', () {
      final mapData = _map(cols: 3, rows: 1);
      final view = _view(
        mapData: mapData,
        units: [_warrior('guard_1', 0, 0)],
        cities: const [_capital],
      );

      final commands = const BasicStrategyIdleSweepPlanner().plan(
        view,
        _context(view),
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands, const [FortifyUnitCommand('guard_1')]);
    });

    test('moves an idle military unit toward the nearest own city', () {
      final mapData = _map(cols: 5, rows: 1);
      final reservedHexes = <HexCoordinate>{};
      final view = _view(
        mapData: mapData,
        units: [_warrior('guard_1', 4, 0)],
        cities: const [_capital],
      );

      final commands = const BasicStrategyIdleSweepPlanner().plan(
        view,
        _context(view),
        <String>{},
        reservedHexes,
      );

      final move = commands.whereType<MoveUnitCommand>().single;
      expect(move.unitId, 'guard_1');
      expect(
        HexDistance.between(
          HexCoordinate(col: move.targetCol, row: move.targetRow),
          _capital.center.toCoordinate(),
        ),
        lessThan(
          HexDistance.between(
            const HexCoordinate(col: 4, row: 0),
            _capital.center.toCoordinate(),
          ),
        ),
      );
      expect(reservedHexes, isEmpty);
    });

    test('explicitly skips an otherwise unassigned civilian', () {
      final mapData = _map(cols: 2, rows: 1);
      final worker = GameUnit.produced(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        col: 0,
        row: 0,
      );
      final view = _view(mapData: mapData, units: [worker], cities: const []);

      final commands = const BasicStrategyIdleSweepPlanner().plan(
        view,
        _context(view),
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands, const [SkipUnitTurnCommand('worker_1')]);
    });
  });
}

const _capital = GameCity(
  id: 'capital',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 0, row: 0),
);

GameUnit _warrior(String id, int col, int row) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    col: col,
    row: row,
  );
}

GameView _view({
  required MapData mapData,
  required List<GameUnit> units,
  required List<GameCity> cities,
}) {
  return GameView.fromPersistentState(
    PersistentGameState(
      units: units,
      cities: cities,
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: _allHexesIn(mapData),
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 30,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

AiContext _context(GameView view) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 1001,
    ),
  );
}

MapData _map({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
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

Set<HexCoordinate> _allHexesIn(MapData mapData) {
  return {
    for (var col = 0; col < mapData.cols; col++)
      for (var row = 0; row < mapData.rows; row++)
        HexCoordinate(col: col, row: row),
  };
}
