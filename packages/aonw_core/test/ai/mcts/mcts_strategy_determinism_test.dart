import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsStrategy determinism', () {
    test('produces the same plan for the same seed and view', () {
      const strategy = MctsStrategy(
        config: MctsConfig(
          iterationBudget: 48,
          maxPlanningDepth: 4,
          candidateLimit: 12,
        ),
      );
      final view = _view();
      final context = _context(baseSeed: 77);

      final plans = [for (var i = 0; i < 8; i++) strategy.plan(view, context)];
      final expected = plans.first.commands;

      expect(expected, isNotEmpty);
      expect(expected, isNot(contains(const EndTurnCommand(_playerId))));
      for (final plan in plans.skip(1)) {
        expect(plan.commands, expected);
      }
    });
  });
}

AiContext _context({required int baseSeed}) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: _mapData,
    turn: 5,
    rng: AiRng.fromTurn(turn: 5, playerId: _playerId, baseSeed: baseSeed),
  );
}

GameView _view() {
  return GameView.fromPersistentState(
    PersistentGameState(
      playerGold: const {_playerId: 12, _enemyId: 8},
      units: [
        GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.warrior,
          col: 0,
          row: 0,
        ),
        GameUnit(
          id: 'worker_1',
          ownerPlayerId: _playerId,
          type: GameUnitType.worker,
          name: 'Worker',
          col: 0,
          row: 1,
        ),
        GameUnit.produced(
          id: 'settler_2',
          ownerPlayerId: _enemyId,
          type: GameUnitType.settler,
          col: 1,
          row: 0,
        ),
        GameUnit.produced(
          id: 'warrior_2',
          ownerPlayerId: _enemyId,
          type: GameUnitType.warrior,
          col: 2,
          row: 1,
        ),
      ],
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: _playerId,
          name: 'Capital',
          center: CityHex(col: 0, row: 1),
          controlledHexes: [CityHex(col: 1, row: 1)],
          population: 3,
        ),
        GameCity(
          id: 'city_2',
          ownerPlayerId: _enemyId,
          name: 'Outpost',
          center: CityHex(col: 2, row: 1),
          population: 2,
        ),
      ],
      research: ResearchState(
        players: {
          _playerId: PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.agriculture},
            activeTechnologyId: TechnologyId.mining,
            progressByTechnologyId: const {TechnologyId.mining: 3},
          ),
          _enemyId: PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      ),
      fogOfWar: _visibleFog(),
    ),
    forPlayerId: _playerId,
    turn: 5,
    mapData: _mapData,
    ruleset: GameRuleset.defaults,
  );
}

FogOfWarState _visibleFog() {
  return FogOfWarState(
    players: {
      _playerId: PlayerFogOfWar(
        playerId: _playerId,
        visibleHexes: {
          for (final tile in _mapData.tiles) HexCoordinate.fromTile(tile),
        },
      ),
    },
  );
}

final _mapData = MapData(
  cols: 4,
  rows: 3,
  tiles: [
    for (var col = 0; col < 4; col++)
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

const _playerId = 'player_1';
const _enemyId = 'player_2';
