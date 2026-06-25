import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/economy_expectations.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/ai/strategic/worker_assignment_plan.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_worker_planner.dart';
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
  group('BasicStrategyWorkerPlanner', () {
    test('uses strategic worker target before local improvement fallback', () {
      final view = _view();
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};

      final commands = const BasicStrategyWorkerPlanner().plan(
        view,
        _context(view, strategicPlan: _strategicPlan),
        usedUnitIds,
        reservedHexes,
      );

      expect(commands, const [MoveUnitCommand('worker_1', 1, 0)]);
      expect(usedUnitIds, {'worker_1'});
    });

    test('skips workers already used by earlier planning phases', () {
      final view = _view();
      final usedUnitIds = {'worker_1'};

      final commands = const BasicStrategyWorkerPlanner().plan(
        view,
        _context(view),
        usedUnitIds,
        <HexCoordinate>{},
      );

      expect(commands, isEmpty);
      expect(usedUnitIds, {'worker_1'});
    });
  });
}

GameView _view() {
  return GameView(
    forPlayerId: 'player_1',
    turn: 3,
    ownUnits: [
      GameUnit.produced(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        col: 0,
        row: 1,
      ),
    ],
    ownCities: const [
      GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 0, row: 1), CityHex(col: 1, row: 0)],
      ),
    ],
    ownResearch: PlayerResearchState(
      unlockedTechnologyIds: {
        TechnologyId.agriculture,
        TechnologyId.animalHusbandry,
      },
    ),
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

AiContext _context(GameView view, {StrategicPlan? strategicPlan}) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 7,
    ),
    strategicPlan: strategicPlan,
  );
}

final _strategicPlan = StrategicPlan(
  computedAtTurn: 3,
  mode: StrategicMode.expand,
  expectations: const EconomyExpectations(
    expectedCityCount: 2,
    expectedWorkerCount: 1,
    expectedMilitaryCount: 1,
    goldReserveTarget: 8,
    minimumSciencePerTurn: 2,
  ),
  workerAssignments: {
    'worker_1': StrategicWorkerAssignment(
      workerId: 'worker_1',
      cityId: 'city_1',
      targets: const [
        StrategicWorkerTarget(
          cityId: 'city_1',
          targetHex: CityHex(col: 1, row: 0),
          improvementType: FieldImprovementType.pasture,
          score: 4000,
          buildTurns: 3,
          existingImprovement: false,
        ),
      ],
    ),
  },
);

final _mapData = MapData(
  cols: 2,
  rows: 2,
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
      terrains: [TerrainType.grassland],
      resources: [ResourceType.sheep],
      height: 0,
    ),
    TileData(
      col: 0,
      row: 1,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 1,
      row: 1,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
const _ruleset = GameRuleset.defaults;
