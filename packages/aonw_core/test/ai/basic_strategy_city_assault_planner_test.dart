import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyCityAssaultPlanner', () {
    test('attacks a war-goal city already in range', () {
      final mapData = _map(cols: 3, rows: 1);
      final view = _view(
        mapData: mapData,
        units: [_tank('tank_1', 0, 0)],
        cities: const [_goalCity],
      );
      final context = _context(
        view,
        warGoals: [
          WarGoal(
            targetPlayerId: 'player_2',
            kind: WarGoalKind.captureCity,
            targetCity: _goalCity.center,
            targetHex: _goalCity.center.toCoordinate(),
            turnsBudget: 4,
            assignedUnitIds: const ['tank_1'],
            priority: 10,
          ),
        ],
      );

      final commands = const BasicStrategyCityAssaultPlanner().plan(
        view,
        context,
        <String>{},
      );

      expect(
        commands.whereType<AttackHexCommand>(),
        contains(const AttackHexCommand('tank_1', 1, 0)),
      );
    });

    test('attacks a city owned by a pressure target player', () {
      final mapData = _map(cols: 4, rows: 1);
      final view = _view(
        mapData: mapData,
        units: [_tank('tank_1', 1, 0)],
        cities: const [
          GameCity(
            id: 'pressure_city',
            ownerPlayerId: 'player_2',
            name: 'Pressure',
            center: CityHex(col: 2, row: 0),
          ),
        ],
        pressureTargetPlayerIds: const ['player_2'],
      );
      final context = _context(view);

      final commands = const BasicStrategyCityAssaultPlanner().plan(
        view,
        context,
        <String>{},
      );

      expect(
        commands.whereType<AttackHexCommand>(),
        contains(const AttackHexCommand('tank_1', 2, 0)),
      );
    });

    test('does not attack a city center occupied by another unit', () {
      final mapData = _map(cols: 3, rows: 1);
      final view = _view(
        mapData: mapData,
        units: [
          _tank('tank_1', 0, 0),
          GameUnit.produced(
            id: 'city_guard',
            ownerPlayerId: 'player_2',
            type: GameUnitType.warrior,
            col: 1,
            row: 0,
          ),
        ],
        cities: const [_goalCity],
      );
      final context = _context(
        view,
        warGoals: [
          WarGoal(
            targetPlayerId: 'player_2',
            kind: WarGoalKind.captureCity,
            targetCity: _goalCity.center,
            targetHex: _goalCity.center.toCoordinate(),
            turnsBudget: 4,
            assignedUnitIds: const ['tank_1'],
            priority: 10,
          ),
        ],
      );

      final commands = const BasicStrategyCityAssaultPlanner().plan(
        view,
        context,
        <String>{},
      );

      expect(commands.whereType<AttackHexCommand>(), isEmpty);
    });
  });
}

const _goalCity = GameCity(
  id: 'goal_city',
  ownerPlayerId: 'player_2',
  name: 'Goal',
  center: CityHex(col: 1, row: 0),
);

GameUnit _tank(String id, int col, int row) {
  return GameUnit.produced(
    id: id,
    ownerPlayerId: 'player_1',
    type: GameUnitType.tank,
    col: col,
    row: row,
  );
}

GameView _view({
  required MapData mapData,
  required List<GameUnit> units,
  required List<GameCity> cities,
  List<String> pressureTargetPlayerIds = const [],
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
    turn: 80,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
    pressureTargetPlayerIds: pressureTargetPlayerIds,
  );
}

AiContext _context(GameView view, {List<WarGoal> warGoals = const []}) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 1001,
    ),
    strategicPlan: StrategicPlan(
      computedAtTurn: view.turn,
      mode: StrategicMode.military,
      expectations: const EconomyExpectations(
        expectedCityCount: 2,
        expectedWorkerCount: 1,
        expectedMilitaryCount: 1,
        goldReserveTarget: 8,
        minimumSciencePerTurn: 2,
      ),
      warGoals: warGoals,
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
