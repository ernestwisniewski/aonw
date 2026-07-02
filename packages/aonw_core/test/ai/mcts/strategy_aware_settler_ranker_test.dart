import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_settler_ranker.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('strategy-aware settler ranker', () {
    test('prioritizes founding on an assigned city site', () {
      final ranking = rankStrategicSettlerCommand(
        const FoundCityCommand('settler_1'),
        _view(units: [_unit('settler_1', GameUnitType.settler)]),
        _context(),
        _plan(settlerAssignments: const {'settler_1': CityHex(col: 0, row: 0)}),
      );

      expect(ranking?.priority, CandidatePriority.settler);
      expect(ranking?.score, 860);
    });

    test('rewards military moves that escort a pressured settler', () {
      final ranking = rankSettlerEscortCommand(
        const MoveUnitCommand('warrior_1', 1, 0),
        _view(
          units: [
            _unit('warrior_1', GameUnitType.warrior),
            _unit('settler_1', GameUnitType.settler, col: 2),
            _unit(
              'enemy_1',
              GameUnitType.warrior,
              ownerPlayerId: 'enemy',
              col: 2,
              row: 2,
            ),
          ],
        ),
        _context(),
        _plan(),
      );

      expect(ranking?.priority, CandidatePriority.opening);
      expect(ranking?.score, greaterThan(1212));
    });

    test('penalizes a city site that would push cohesion into unrest', () {
      final mapData = _mapData(cols: 12, rows: 1);
      const capital = GameCity(
        id: 'capital',
        ownerPlayerId: 'player_1',
        foundingOwnerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      );
      final near = rankStrategicSettlerCommand(
        const FoundCityCommand(
          'near_settler',
          controlledHexes: [CityHex(col: 2, row: 0)],
        ),
        _view(
          units: [_unit('near_settler', GameUnitType.settler, col: 3)],
          cities: const [capital],
          mapData: mapData,
        ),
        _context(mapData: mapData),
        _plan(),
      );
      final far = rankStrategicSettlerCommand(
        const FoundCityCommand(
          'far_settler',
          controlledHexes: [CityHex(col: 10, row: 0)],
        ),
        _view(
          units: [_unit('far_settler', GameUnitType.settler, col: 11)],
          cities: const [capital],
          mapData: mapData,
        ),
        _context(mapData: mapData),
        _plan(),
      );

      expect(near, isNotNull);
      expect(far, isNotNull);
      expect(far!.score, lessThan(near!.score));
    });
  });
}

const _expectations = EconomyExpectations(
  expectedCityCount: 2,
  expectedWorkerCount: 1,
  expectedMilitaryCount: 2,
  goldReserveTarget: 8,
  minimumSciencePerTurn: 2,
);

StrategicPlan _plan({Map<String, CityHex> settlerAssignments = const {}}) {
  return StrategicPlan(
    computedAtTurn: 1,
    mode: StrategicMode.expand,
    expectations: _expectations,
    settlerAssignments: settlerAssignments,
  );
}

AiContext _context({MapData? mapData}) {
  final actualMapData = mapData ?? _mapData();
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: actualMapData,
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
  );
}

GameView _view({
  List<GameUnit> units = const [],
  List<GameCity> cities = const [],
  MapData? mapData,
}) {
  final actualMapData = mapData ?? _mapData();
  return GameView.fromPersistentState(
    PersistentGameState(units: units, cities: cities),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: actualMapData,
    ruleset: GameRuleset.defaults,
    ignoreFogOfWar: true,
    ignoreDynamicFogOfWar: true,
  );
}

GameUnit _unit(
  String id,
  GameUnitType type, {
  String ownerPlayerId = 'player_1',
  int col = 0,
  int row = 0,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: row,
  );
}

MapData _mapData({int cols = 4, int rows = 4}) {
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
