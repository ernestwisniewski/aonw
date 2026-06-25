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

AiContext _context() {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: _mapData(),
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
  );
}

GameView _view({List<GameUnit> units = const []}) {
  return GameView.fromPersistentState(
    PersistentGameState(units: units),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: _mapData(),
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

MapData _mapData() {
  return MapData(
    cols: 4,
    rows: 4,
    tiles: [
      for (var col = 0; col < 4; col++)
        for (var row = 0; row < 4; row++)
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
