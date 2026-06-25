import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_defense_ranker.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('strategy-aware defense ranker', () {
    test('prioritizes early defender production for ungarrisoned cities', () {
      final ranking = rankEarlyCityDefenseCommand(
        const StartUnitProductionCommand('capital', GameUnitType.warrior),
        _view(cities: [_city()]),
        _context(),
        _plan(
          defenses: {
            'capital': StrategicDefenseAssignment(
              cityId: 'capital',
              cityCenter: const CityHex(col: 0, row: 0),
              threatLevel: 3,
              assignedUnitIds: const [],
            ),
          },
        ),
      );

      expect(ranking?.priority, CandidatePriority.opening);
      expect(ranking?.score, 1408);
    });

    test('keeps threatened pinned garrisons from moving away', () {
      final ranking = rankPinnedGarrisonMove(
        const MoveUnitCommand('garrison_1', 1, 0),
        _view(
          cities: [_city()],
          units: [_unit('garrison_1', GameUnitType.warrior)],
        ),
        _plan(
          defenses: {
            'capital': StrategicDefenseAssignment(
              cityId: 'capital',
              cityCenter: const CityHex(col: 0, row: 0),
              threatLevel: 4,
              assignedUnitIds: const ['garrison_1'],
            ),
          },
        ),
      );

      expect(ranking?.priority, CandidatePriority.fallback);
      expect(ranking?.score, -950);
    });
  });
}

const _expectations = EconomyExpectations(
  expectedCityCount: 1,
  expectedWorkerCount: 1,
  expectedMilitaryCount: 1,
  goldReserveTarget: 8,
  minimumSciencePerTurn: 2,
);

StrategicPlan _plan({
  Map<String, StrategicDefenseAssignment> defenses = const {},
}) {
  return StrategicPlan(
    computedAtTurn: 1,
    mode: StrategicMode.consolidate,
    expectations: _expectations,
    defenses: defenses,
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

GameView _view({
  List<GameCity> cities = const [],
  List<GameUnit> units = const [],
}) {
  return GameView.fromPersistentState(
    PersistentGameState(cities: cities, units: units),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: _mapData(),
    ruleset: GameRuleset.defaults,
    ignoreFogOfWar: true,
    ignoreDynamicFogOfWar: true,
  );
}

GameCity _city() {
  return const GameCity(
    id: 'capital',
    ownerPlayerId: 'player_1',
    name: 'Capital',
    center: CityHex(col: 0, row: 0),
  );
}

GameUnit _unit(String id, GameUnitType type) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: type,
    name: type.defaultNameToken,
    col: 0,
    row: 0,
  );
}

MapData _mapData() {
  return MapData(
    cols: 3,
    rows: 3,
    tiles: [
      for (var col = 0; col < 3; col++)
        for (var row = 0; row < 3; row++)
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
