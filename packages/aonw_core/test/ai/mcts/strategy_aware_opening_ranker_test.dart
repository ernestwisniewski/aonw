import 'package:aonw_core/ai/mcts/strategy_aware_candidate_ranking.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_opening_ranker.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('strategy-aware opening ranker', () {
    test('prioritizes founding the first city during opening survival', () {
      final ranking = rankOpeningSurvivalCommand(
        const FoundCityCommand(
          'settler_1',
          controlledHexes: [CityHex(col: 1, row: 0), CityHex(col: 0, row: 1)],
        ),
        _view(units: [_unit('settler_1', GameUnitType.settler)]),
        _context(),
        null,
      );

      expect(ranking?.priority, CandidatePriority.opening);
      expect(ranking?.score, 1280);
    });
  });
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
