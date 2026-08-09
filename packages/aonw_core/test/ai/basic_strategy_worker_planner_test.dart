import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/economy_expectations.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/ai/strategic/worker_assignment_plan.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_worker_planner.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
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

    test('assigns an idle worker to its completed improvement', () {
      final mapData = WorldMap(
        cols: 1,
        rows: 2,
        tiles: [_tile(0, 0), _tile(0, 1)],
      );
      final worker = GameUnit.produced(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        col: 0,
        row: 1,
      ).copyWithWorkerBuildCharges(0);
      final view = _view(
        mapData: mapData,
        units: [worker],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 0, row: 1)],
          ),
        ],
        improvements: const [
          FieldImprovement(
            hex: CityHex(col: 0, row: 1),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
        ],
      );

      final commands = const BasicStrategyWorkerPlanner().plan(
        view,
        _context(view),
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands, [const AssignWorkerToHexCommand('worker_1')]);
    });

    test('chooses the higher-scoring legal improvement deterministically', () {
      final mapData = WorldMap(
        cols: 1,
        rows: 2,
        tiles: [
          _tile(0, 0),
          _tile(0, 1, terrains: const [TerrainType.plains, TerrainType.river]),
        ],
      );
      final view = _view(
        mapData: mapData,
        units: [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 1,
          ),
        ],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Capital',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 0, row: 1)],
          ),
        ],
      );

      final commands = const BasicStrategyWorkerPlanner().plan(
        view,
        _context(view),
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands, [
        const SelectWorkerImprovementCommand(
          'worker_1',
          FieldImprovementType.riverFarm,
        ),
      ]);
    });
  });
}

GameView _view({
  WorldMap? mapData,
  List<GameUnit>? units,
  List<GameCity>? cities,
  List<FieldImprovement> improvements = const [],
}) {
  final effectiveMapData = mapData ?? _mapData;
  return GameView(
    forPlayerId: 'player_1',
    turn: 3,
    ownUnits:
        units ??
        [
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 0,
            row: 1,
          ),
        ],
    ownCities:
        cities ??
        const [
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
    ownImprovements: improvements,
    visibleEnemyUnits: const [],
    rememberedEnemyCities: const [],
    visibility: const FogVisibilityQuery(
      playerId: '',
      state: FogOfWarState.empty,
    ),
    mapData: effectiveMapData,
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

final _mapData = WorldMap(
  cols: 2,
  rows: 2,
  tiles: [
    WorldTile(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    WorldTile(
      col: 1,
      row: 0,
      terrains: [TerrainType.grassland],
      resources: [ResourceType.sheep],
      height: 0,
    ),
    WorldTile(
      col: 0,
      row: 1,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    WorldTile(
      col: 1,
      row: 1,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
const _ruleset = GameRuleset.defaults;

WorldTile _tile(
  int col,
  int row, {
  List<TerrainType> terrains = const [TerrainType.plains],
}) {
  return WorldTile(
    col: col,
    row: row,
    terrains: terrains,
    resources: const [],
    height: 0,
  );
}
