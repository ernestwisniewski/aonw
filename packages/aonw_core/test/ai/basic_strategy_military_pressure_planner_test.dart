import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyMilitaryPressurePlanner', () {
    test('holds generic pressure while a two-city core needs a third', () {
      final mapData = _map(cols: 8, rows: 8);
      final view = _view(
        mapData: mapData,
        units: [
          _warrior('warrior_1', 1, 1),
          _warrior('warrior_2', 5, 4),
          _enemyWarrior('enemy_1', 7, 5),
        ],
        cities: const [_capital, _secondCity],
      );
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};

      final commands = const BasicStrategyMilitaryPressurePlanner().plan(
        view,
        _context(view, mode: StrategicMode.consolidate),
        const AiEmpireAssessment(
          playerId: 'player_1',
          cityCount: 2,
          workerCount: 0,
          settlerCount: 0,
          militaryCount: 2,
          visibleEnemyMilitaryCount: 1,
          goldReserve: 0,
          netGoldPerTurn: 0,
          desiredCityCount: 3,
          desiredWorkerCount: 2,
          desiredMilitaryCount: 2,
        ),
        usedUnitIds,
        reservedHexes,
      );

      expect(commands, isEmpty);
      expect(usedUnitIds, isEmpty);
      expect(reservedHexes, isEmpty);
    });

    test('uses clear force advantage to pressure during expansion', () {
      final mapData = _map(cols: 8, rows: 8);
      final view = _view(
        mapData: mapData,
        units: [
          _warrior('warrior_1', 1, 1),
          _warrior('warrior_2', 5, 4),
          _warrior('warrior_3', 4, 5),
          _enemyWarrior('enemy_1', 7, 5),
        ],
        cities: const [_capital, _secondCity],
      );
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};

      final commands = const BasicStrategyMilitaryPressurePlanner().plan(
        view,
        _context(view, mode: StrategicMode.consolidate),
        const AiEmpireAssessment(
          playerId: 'player_1',
          cityCount: 2,
          workerCount: 0,
          settlerCount: 0,
          militaryCount: 3,
          visibleEnemyMilitaryCount: 1,
          goldReserve: 0,
          netGoldPerTurn: 0,
          desiredCityCount: 3,
          desiredWorkerCount: 2,
          desiredMilitaryCount: 2,
        ),
        usedUnitIds,
        reservedHexes,
      );

      final moves = commands.whereType<MoveUnitCommand>().toList();
      expect(moves, isNotEmpty);
      expect(usedUnitIds, contains(moves.first.unitId));
      expect(reservedHexes, isNotEmpty);
    });

    test('assignedOnly moves only war-goal units', () {
      final mapData = _map(cols: 6, rows: 2);
      const goalHex = HexCoordinate(col: 5, row: 0);
      final view = _view(
        mapData: mapData,
        units: [_warrior('assigned_1', 0, 0), _warrior('unassigned_1', 0, 1)],
        cities: const [
          _capital,
          GameCity(
            id: 'enemy_city',
            ownerPlayerId: 'player_2',
            name: 'Enemy',
            center: CityHex(col: 5, row: 0),
          ),
        ],
      );
      final context = _context(
        view,
        mode: StrategicMode.military,
        warGoals: [
          WarGoal(
            targetPlayerId: 'player_2',
            kind: WarGoalKind.captureCity,
            targetCity: const CityHex(col: 5, row: 0),
            targetHex: const HexCoordinate(col: 5, row: 0),
            turnsBudget: 6,
            assignedUnitIds: ['assigned_1'],
            priority: 5,
          ),
        ],
      );
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};

      final commands = const BasicStrategyMilitaryPressurePlanner().plan(
        view,
        context,
        AiEmpireAssessment.fromView(view, context),
        usedUnitIds,
        reservedHexes,
        assignedOnly: true,
      );

      final moves = commands.whereType<MoveUnitCommand>().toList();
      expect(moves, hasLength(1));
      expect(moves.single.unitId, 'assigned_1');
      expect(
        HexDistance.between(
          HexCoordinate(
            col: moves.single.targetCol,
            row: moves.single.targetRow,
          ),
          goalHex,
        ),
        lessThan(
          HexDistance.between(const HexCoordinate(col: 0, row: 0), goalHex),
        ),
      );
      expect(usedUnitIds, {'assigned_1'});
    });
  });
}

const _capital = GameCity(
  id: 'capital',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 1, row: 1),
);

const _secondCity = GameCity(
  id: 'city_2',
  ownerPlayerId: 'player_1',
  name: 'Second',
  center: CityHex(col: 5, row: 5),
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
  List<GameCity> cities = const [],
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
    turn: 34,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

AiContext _context(
  GameView view, {
  required StrategicMode mode,
  List<WarGoal> warGoals = const [],
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
    strategicPlan: StrategicPlan(
      computedAtTurn: view.turn,
      mode: mode,
      expectations: const EconomyExpectations(
        expectedCityCount: 3,
        expectedWorkerCount: 2,
        expectedMilitaryCount: 2,
        goldReserveTarget: 10,
        minimumSciencePerTurn: 3,
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
