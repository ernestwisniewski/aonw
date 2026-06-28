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

    test('fortifies idle military on defensive terrain from combat rules', () {
      final mapData = _map(
        cols: 3,
        rows: 1,
        terrainOverrides: {
          (col: 1, row: 0): const [TerrainType.mountain],
          (col: 2, row: 0): const [TerrainType.grassland, TerrainType.river],
        },
      );
      final view = _view(
        mapData: mapData,
        units: [
          _warrior('mountain_guard', 1, 0),
          _warrior('river_guard', 2, 0),
        ],
        cities: const [],
      );

      final commands = const BasicStrategyIdleSweepPlanner().plan(
        view,
        _context(view),
        <String>{},
        <HexCoordinate>{},
      );

      expect(
        commands,
        containsAll(const [
          FortifyUnitCommand('mountain_guard'),
          FortifyUnitCommand('river_guard'),
        ]),
      );
    });

    test('prefers a threatened reachable city over a closer calm city', () {
      final mapData = _map(cols: 6, rows: 1);
      const calmCity = GameCity(
        id: 'calm',
        ownerPlayerId: 'player_1',
        name: 'Calm',
        center: CityHex(col: 0, row: 0),
      );
      const threatenedCity = GameCity(
        id: 'threatened',
        ownerPlayerId: 'player_1',
        name: 'Threatened',
        center: CityHex(col: 5, row: 0),
      );
      final view = _view(
        mapData: mapData,
        units: [_warrior('guard_1', 2, 0)],
        cities: const [calmCity, threatenedCity],
      );

      final commands = const BasicStrategyIdleSweepPlanner().plan(
        view,
        _context(
          view,
          defenses: {
            'threatened': StrategicDefenseAssignment(
              cityId: 'threatened',
              cityCenter: const CityHex(col: 5, row: 0),
              threatLevel: 10,
              primaryThreatPlayerId: 'player_2',
              assignedUnitIds: [],
            ),
          },
        ),
        <String>{},
        <HexCoordinate>{},
      );

      final move = commands.whereType<MoveUnitCommand>().single;
      expect(move.unitId, 'guard_1');
      expect(move.targetCol, greaterThan(2));
      expect(move.targetRow, 0);
    });

    test('fortifies stuck military instead of skipping', () {
      final mapData = _map(cols: 3, rows: 1);
      final view = _view(
        mapData: mapData,
        units: [_warrior('guard_1', 2, 0), _enemyWarrior('blocker_1', 1, 0)],
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

GameUnit _enemyWarrior(String id, int col, int row) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: 'player_2',
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

AiContext _context(
  GameView view, {
  Map<String, StrategicDefenseAssignment> defenses = const {},
}) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 1001,
    ),
    strategicPlan: defenses.isEmpty
        ? null
        : StrategicPlan(
            computedAtTurn: view.turn,
            mode: StrategicMode.consolidate,
            expectations: const EconomyExpectations(
              expectedCityCount: 2,
              expectedWorkerCount: 0,
              expectedMilitaryCount: 1,
              goldReserveTarget: 8,
              minimumSciencePerTurn: 2,
            ),
            defenses: defenses,
          ),
  );
}

MapData _map({
  required int cols,
  required int rows,
  Map<({int col, int row}), List<TerrainType>> terrainOverrides = const {},
}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
          TileData(
            col: col,
            row: row,
            terrains:
                terrainOverrides[(col: col, row: row)] ??
                const [TerrainType.plains],
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
