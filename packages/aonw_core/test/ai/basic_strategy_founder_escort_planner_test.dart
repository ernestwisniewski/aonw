import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/ai_rng.dart';
import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/defensive_stance.dart';
import 'package:aonw_core/ai/strategic/economy_expectations.dart';
import 'package:aonw_core/ai/strategic/strategic_mode.dart';
import 'package:aonw_core/ai/strategic/strategic_plan.dart';
import 'package:aonw_core/ai/strategies/basic_strategy_founder_escort_planner.dart';
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
  group('BasicStrategyFounderEscortPlanner', () {
    test('returns no commands when assigned founder is not pressured', () {
      final view = _view(
        units: [_settler(), _escort(), _capitalGuard(), _secondGuard()],
        visibleEnemyUnits: const [],
      );

      final commands = const BasicStrategyFounderEscortPlanner().plan(
        view,
        _context(view),
        _assessment,
        <String>{},
        <HexCoordinate>{},
      );

      expect(commands, isEmpty);
    });

    test('moves spare military toward a pressured assigned founder', () {
      final usedUnitIds = <String>{};
      final reservedHexes = <HexCoordinate>{};
      final view = _view(
        units: [_settler(), _escort(), _capitalGuard(), _secondGuard()],
        visibleEnemyUnits: [_enemyNearAssignment()],
      );

      final commands = const BasicStrategyFounderEscortPlanner().plan(
        view,
        _context(view),
        _assessment,
        usedUnitIds,
        reservedHexes,
      );

      expect(commands, hasLength(1));
      final move = commands.single as MoveUnitCommand;
      expect(move.unitId, 'escort_1');
      expect(
        HexDistance.between(
          HexCoordinate(col: move.targetCol, row: move.targetRow),
          _assignment.toCoordinate(),
        ),
        lessThan(
          HexDistance.between(
            const HexCoordinate(col: 7, row: 3),
            _assignment.toCoordinate(),
          ),
        ),
      );
      expect(usedUnitIds, {'escort_1'});
      expect(
        reservedHexes,
        contains(HexCoordinate(col: move.targetCol, row: move.targetRow)),
      );
    });

    test('does not reuse units reserved by earlier planning phases', () {
      final usedUnitIds = {'escort_1'};
      final view = _view(
        units: [_settler(), _escort(), _capitalGuard(), _secondGuard()],
        visibleEnemyUnits: [_enemyNearAssignment()],
      );

      final commands = const BasicStrategyFounderEscortPlanner().plan(
        view,
        _context(
          view,
          defenses: {
            'capital': StrategicDefenseAssignment(
              cityId: 'capital',
              cityCenter: const CityHex(col: 0, row: 0),
              threatLevel: 5,
              assignedUnitIds: const ['capital_guard'],
            ),
            'second': StrategicDefenseAssignment(
              cityId: 'second',
              cityCenter: const CityHex(col: 7, row: 0),
              threatLevel: 5,
              assignedUnitIds: const ['second_guard'],
            ),
          },
        ),
        _assessment,
        usedUnitIds,
        <HexCoordinate>{},
      );

      expect(commands.whereType<MoveUnitCommand>(), isEmpty);
      expect(usedUnitIds, {'escort_1'});
    });
  });
}

GameView _view({
  required List<GameUnit> units,
  required List<GameUnit> visibleEnemyUnits,
}) {
  return GameView(
    forPlayerId: 'player_1',
    turn: 24,
    ownUnits: units,
    ownCities: const [_capital, _second],
    ownResearch: PlayerResearchState.empty,
    ownImprovements: const [],
    visibleEnemyUnits: visibleEnemyUnits,
    rememberedEnemyCities: const [],
    visibility: const FogVisibilityQuery(
      playerId: '',
      state: FogOfWarState.empty,
    ),
    mapData: _mapData,
    ruleset: _ruleset,
  );
}

AiContext _context(
  GameView view, {
  Map<String, StrategicDefenseAssignment>? defenses,
}) {
  return AiContext(
    ruleset: view.ruleset,
    mapData: view.mapData,
    turn: view.turn,
    rng: AiRng.fromTurn(
      turn: view.turn,
      playerId: view.forPlayerId,
      baseSeed: 19,
    ),
    strategicPlan: StrategicPlan(
      computedAtTurn: view.turn,
      mode: StrategicMode.expand,
      expectations: const EconomyExpectations(
        expectedCityCount: 3,
        expectedWorkerCount: 2,
        expectedMilitaryCount: 3,
        goldReserveTarget: 10,
        minimumSciencePerTurn: 3,
      ),
      settlerAssignments: const {'settler_1': _assignment},
      defenses: defenses ?? _defaultDefenses(),
    ),
  );
}

Map<String, StrategicDefenseAssignment> _defaultDefenses() {
  return {
    'capital': StrategicDefenseAssignment(
      cityId: 'capital',
      cityCenter: const CityHex(col: 0, row: 0),
      threatLevel: 0,
      assignedUnitIds: const ['capital_guard'],
    ),
    'second': StrategicDefenseAssignment(
      cityId: 'second',
      cityCenter: const CityHex(col: 7, row: 0),
      threatLevel: 0,
      assignedUnitIds: const ['second_guard', 'escort_1'],
    ),
  };
}

GameUnit _settler() {
  return GameUnit.produced(
    id: 'settler_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.settler,
    col: 4,
    row: 5,
  );
}

GameUnit _escort() {
  return GameUnit.produced(
    id: 'escort_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    col: 7,
    row: 3,
  );
}

GameUnit _capitalGuard() {
  return GameUnit.produced(
    id: 'capital_guard',
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    col: 0,
    row: 1,
  );
}

GameUnit _secondGuard() {
  return GameUnit.produced(
    id: 'second_guard',
    ownerPlayerId: 'player_1',
    type: GameUnitType.warrior,
    col: 7,
    row: 1,
  );
}

GameUnit _enemyNearAssignment() {
  return GameUnit.produced(
    id: 'enemy_warrior',
    ownerPlayerId: 'player_2',
    type: GameUnitType.warrior,
    col: 5,
    row: 7,
  );
}

const _assessment = AiEmpireAssessment(
  playerId: 'player_1',
  cityCount: 2,
  workerCount: 0,
  settlerCount: 1,
  militaryCount: 3,
  visibleEnemyMilitaryCount: 1,
  goldReserve: 0,
  netGoldPerTurn: 0,
  desiredCityCount: 3,
  desiredWorkerCount: 2,
  desiredMilitaryCount: 3,
);

const _assignment = CityHex(col: 5, row: 6);

const _capital = GameCity(
  id: 'capital',
  ownerPlayerId: 'player_1',
  name: 'Capital',
  center: CityHex(col: 0, row: 0),
);

const _second = GameCity(
  id: 'second',
  ownerPlayerId: 'player_1',
  name: 'Second',
  center: CityHex(col: 7, row: 0),
);

final _mapData = MapData(
  cols: 8,
  rows: 8,
  tiles: [
    for (var row = 0; row < 8; row++)
      for (var col = 0; col < 8; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

const _ruleset = GameRuleset.defaults;
