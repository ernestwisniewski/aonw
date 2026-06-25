import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/ai_strategy.dart';
import 'package:aonw_core/ai/ai_turn_plan.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_exploration_planner.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:test/test.dart';

void main() {
  group('BasicStrategyExplorationPlanner', () {
    test('plans frontier movement before generic fallback exploration', () {
      final view = _view(
        units: [
          GameUnit.produced(
            id: 'scout_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.scout,
            col: 0,
            row: 0,
          ),
        ],
        cities: const [_capital],
      );
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};

      final plan = const BasicStrategyExplorationPlanner().plan(
        view,
        _context(view),
        usedUnitIds,
        reservedHexes,
      );

      expect(plan.commands, const [MoveUnitCommand('scout_1', 1, 0)]);
      expect(plan.debug?.strategyId, 'frontier-exploration');
      expect(usedUnitIds, {'scout_1'});
      expect(reservedHexes, {const HexCoordinate(col: 1, row: 0)});
    });

    test('uses injected fallback when no frontier movement is available', () {
      final fallback = _FixedFallbackStrategy();
      final view = _view(
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 0,
          ),
        ],
        cities: const [_capital],
      );

      final plan = BasicStrategyExplorationPlanner(
        fallbackStrategy: fallback,
      ).plan(view, _context(view), <String>{}, <HexCoordinate>{});

      expect(fallback.calls, 1);
      expect(plan.commands, const [EndTurnCommand('player_1')]);
      expect(plan.debug?.strategyId, 'fixed-fallback');
    });
  });
}

GameView _view({
  required List<GameUnit> units,
  required List<GameCity> cities,
}) {
  return GameView(
    forPlayerId: 'player_1',
    turn: 1,
    ownUnits: units,
    ownCities: cities,
    ownResearch: PlayerResearchState.empty,
    ownImprovements: const [],
    visibleEnemyUnits: const [],
    rememberedEnemyCities: const [],
    visibility: const FogVisibilityQuery(
      playerId: '',
      state: FogOfWarState.empty,
    ),
    mapData: _mapData,
    ruleset: _ruleset,
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
      baseSeed: 7,
    ),
  );
}

final class _FixedFallbackStrategy implements AiStrategy {
  var calls = 0;

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    calls++;
    return AiTurnPlan(
      commands: const [EndTurnCommand('player_1')],
      debug: AiDebugInfo(strategyId: 'fixed-fallback'),
    );
  }
}

const _capital = GameCity(
  id: 'city_1',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 0, row: 0),
);

final _mapData = MapData(
  cols: 2,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 1,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
const _ruleset = GameRuleset.defaults;
