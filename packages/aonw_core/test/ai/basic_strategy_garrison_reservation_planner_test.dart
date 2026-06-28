import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyGarrisonReservationPlanner', () {
    test('reserves the defender already holding the city area first', () {
      final mapData = _map(cols: 4, rows: 1);
      final view = _view(
        mapData: mapData,
        units: [_warrior('guard_1', 0, 0), _warrior('field_1', 3, 0)],
        cities: const [_capital],
      );

      final reserved = const BasicStrategyGarrisonReservationPlanner().plan(
        view,
        _context(view),
        <String>{},
      );

      expect(reserved, {'guard_1'});
    });

    test('scales the reservation to two defenders for high threat cities', () {
      final mapData = _map(cols: 4, rows: 1);
      final view = _view(
        mapData: mapData,
        units: [_warrior('guard_1', 0, 0), _warrior('guard_2', 2, 0)],
        cities: const [_capital],
      );

      final reserved = const BasicStrategyGarrisonReservationPlanner().plan(
        view,
        _context(
          view,
          defenses: {
            'capital': StrategicDefenseAssignment(
              cityId: 'capital',
              cityCenter: _capital.center,
              threatLevel: 30,
              assignedUnitIds: const ['guard_1', 'guard_2'],
              primaryThreatPlayerId: 'player_2',
            ),
          },
        ),
        <String>{},
      );

      expect(reserved, {'guard_1', 'guard_2'});
    });

    test('does not reserve defenders that cannot reach the city area', () {
      final mapData = _map(cols: 3, rows: 1);
      final view = _view(
        mapData: mapData,
        units: [
          _warrior('blocked_guard', 2, 0),
          _enemyWarrior('enemy_blocker', 1, 0),
        ],
        cities: const [_capital],
      );

      final reserved = const BasicStrategyGarrisonReservationPlanner().plan(
        view,
        _context(view),
        <String>{},
      );

      expect(reserved, isEmpty);
    });

    test('does not reserve every calm city in a multi-city empire', () {
      final mapData = _map(cols: 6, rows: 1);
      final view = _view(
        mapData: mapData,
        units: [_warrior('guard_1', 0, 0), _warrior('guard_2', 5, 0)],
        cities: const [_capital, _satellite],
      );

      final reserved = const BasicStrategyGarrisonReservationPlanner().plan(
        view,
        _context(view),
        <String>{},
      );

      expect(reserved, isEmpty);
    });
  });

  group('BasicStrategy garrison integration', () {
    test('does not spend the reserved city guard on city assault', () {
      final mapData = _map(cols: 2, rows: 1);
      final guard = GameUnit.produced(
        id: 'guard_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.tank,
        col: 0,
        row: 0,
      );
      const enemyCity = GameCity(
        id: 'enemy_city',
        ownerPlayerId: 'player_2',
        name: 'Enemy',
        center: CityHex(col: 1, row: 0),
      );
      final view = GameView(
        forPlayerId: 'player_1',
        turn: 80,
        ownUnits: [guard],
        ownCities: const [_capital],
        ownResearch: PlayerResearchState.empty,
        ownImprovements: const [],
        visibleEnemyUnits: const [],
        rememberedEnemyCities: const [enemyCity],
        pressureTargetPlayerIds: const ['player_2'],
        visibility: const FogVisibilityQuery(
          playerId: '',
          state: FogOfWarState.empty,
        ),
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      );

      final plan = const BasicStrategy().plan(
        view,
        _context(view, mode: StrategicMode.military, defenses: const {}),
      );

      expect(
        plan.commands.whereType<AttackHexCommand>().where(
          (command) =>
              command.attackerUnitId == 'guard_1' &&
              command.defenderCol == 1 &&
              command.defenderRow == 0,
        ),
        isEmpty,
      );
      expect(plan.commands, contains(const FortifyUnitCommand('guard_1')));
    });
  });
}

const _capital = GameCity(
  id: 'capital',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 0, row: 0),
);

const _satellite = GameCity(
  id: 'satellite',
  ownerPlayerId: 'player_1',
  name: 'Satellite',
  center: CityHex(col: 5, row: 0),
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
  StrategicMode mode = StrategicMode.consolidate,
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
    strategicPlan: StrategicPlan(
      computedAtTurn: view.turn,
      mode: mode,
      expectations: const EconomyExpectations(
        expectedCityCount: 1,
        expectedWorkerCount: 0,
        expectedMilitaryCount: 1,
        goldReserveTarget: 8,
        minimumSciencePerTurn: 2,
      ),
      defenses: defenses,
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
