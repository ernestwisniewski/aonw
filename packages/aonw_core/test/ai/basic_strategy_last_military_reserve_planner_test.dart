import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyLastMilitaryReservePlanner', () {
    test('moves the last military unit toward the nearest own city', () {
      final mapData = _map(cols: 5, rows: 1);
      final view = _view(mapData: mapData, units: [_warrior(col: 3, row: 0)]);
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};

      final commands = const BasicStrategyLastMilitaryReservePlanner().plan(
        view,
        _context(view),
        usedUnitIds,
        reservedHexes,
      );

      final move = commands.whereType<MoveUnitCommand>().single;
      expect(move.unitId, 'warrior_1');
      expect(
        HexDistance.between(
          HexCoordinate(col: move.targetCol, row: move.targetRow),
          _capital.center.toCoordinate(),
        ),
        lessThan(
          HexDistance.between(
            const HexCoordinate(col: 3, row: 0),
            _capital.center.toCoordinate(),
          ),
        ),
      );
    });

    test('fortifies the last military unit already guarding a city', () {
      final mapData = _map(cols: 3, rows: 1);
      final view = _view(mapData: mapData, units: [_warrior(col: 0, row: 0)]);

      final commands = const BasicStrategyLastMilitaryReservePlanner().plan(
        view,
        _context(view),
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands, [const FortifyUnitCommand('warrior_1')]);
    });
  });
}

const _capital = GameCity(
  id: 'capital',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 0, row: 0),
);

GameUnit _warrior({required int col, required int row}) {
  return GameUnit.produced(
    id: 'warrior_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    col: col,
    row: row,
  );
}

GameView _view({required MapData mapData, required List<GameUnit> units}) {
  return GameView.fromPersistentState(
    PersistentGameState(
      units: units,
      cities: const [_capital],
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
    turn: 2,
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
