import 'package:aonw_core/ai/mcts/mcts_command_reconciliation_rules.dart';
import 'package:aonw_core/ai/mcts/mcts_evaluation_queries.dart';
import 'package:aonw_core/ai/mcts/strategy_aware_ranking_queries.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('strategy-aware ranking queries', () {
    test('measures movement progress toward a target hex', () {
      const target = HexCoordinate(col: 3, row: 0);

      expect(
        distanceImprovement(
          fromCol: 0,
          fromRow: 0,
          toCol: 1,
          toRow: 0,
          target: target,
        ),
        greaterThan(0),
      );
    });

    test('classifies strategic building roles', () {
      expect(isMilitaryBuilding(CityBuildingType.barracks), isTrue);
      expect(isMilitaryBuilding(CityBuildingType.marketplace), isFalse);
      expect(isEconomicBuilding(CityBuildingType.marketplace), isTrue);
      expect(isScienceBuilding(CityBuildingType.university), isTrue);
      expect(isGrowthBuilding(CityBuildingType.granary), isTrue);
    });

    test('classifies recon unit types', () {
      expect(isReconType(GameUnitType.scout), isTrue);
      expect(isReconType(GameUnitType.reconPlane), isTrue);
      expect(isReconType(GameUnitType.warrior), isFalse);
    });

    test('treats a movement subpoint as available for recon planning', () {
      final stoppedScout = _unit(
        'scout_1',
        type: GameUnitType.scout,
      ).copyWithMovementUnits(0);
      final movingScout = stoppedScout.copyWithMovementUnits(1);
      final plan = _plan();

      expect(
        hasAvailableReconCitySiteScout(_view(units: [stoppedScout]), plan),
        isFalse,
      );
      expect(
        hasAvailableReconCitySiteScout(_view(units: [movingScout]), plan),
        isTrue,
      );
      expect(
        mctsCanDiscoverCitySites(
          stoppedScout,
          view: _view(units: [stoppedScout]),
          context: _context(),
          requireMovement: true,
        ),
        isFalse,
      );
    });

    test('detects a movement-unit-only simulated state change', () {
      final beforeUnit = _unit('warrior_1').copyWithMovementUnits(1);
      final afterUnit = beforeUnit.copyWithMovementUnits(0);
      final before = SimulatedState.fromView(
        _view(units: [beforeUnit]),
        maxPlanningDepth: 1,
      );
      final after = SimulatedState.fromView(
        _view(units: [afterUnit]),
        maxPlanningDepth: 1,
      );

      expect(
        const MctsCommandReconciliationRules().moveDidNotChangeUnit(
          const MoveUnitCommand('warrior_1', 2, 1),
          before: before,
          after: after,
        ),
        isFalse,
      );
    });

    test('extracts the acting unit id from unit-scoped commands', () {
      expect(
        unitIdForCommand(const MoveUnitCommand('warrior_1', 1, 0)),
        'warrior_1',
      );
      expect(
        unitIdForCommand(const AttackHexCommand('archer_1', 2, 0)),
        'archer_1',
      );
      expect(
        unitIdForCommand(
          const StartCityProjectCommand('city_1', CityProjectType.wealth),
        ),
        isNull,
      );
    });

    test('finds assigned defenses by unit id', () {
      final defense = StrategicDefenseAssignment(
        cityId: 'capital',
        cityCenter: const CityHex(col: 1, row: 1),
        threatLevel: 0,
        assignedUnitIds: const ['warrior_1'],
      );

      final plan = _plan(defenses: {'capital': defense});

      expect(assignedDefenseFor(plan, 'warrior_1'), defense);
      expect(assignedDefenseFor(plan, 'scout_1'), isNull);
    });

    test('evaluates core defense coverage against the military target', () {
      final city = _city();
      final context = _context();
      final plan = _plan();

      expect(
        coreDefenseMilitaryTarget(
          _view(cities: [city], units: [_unit('warrior_1')]),
          context,
          plan,
        ),
        2,
      );
      expect(
        coreDefenseCovered(
          _view(cities: [city], units: [_unit('warrior_1')]),
          context,
          plan,
        ),
        isFalse,
      );
      expect(
        coreDefenseCovered(
          _view(
            cities: [city],
            units: [
              _unit('warrior_1'),
              _unit('archer_1', type: GameUnitType.archer),
            ],
          ),
          context,
          plan,
        ),
        isTrue,
      );
    });
  });
}

const _expectations = EconomyExpectations(
  expectedCityCount: 1,
  expectedWorkerCount: 1,
  expectedMilitaryCount: 2,
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
  return GameView.fromDomainState(
    DomainState.snapshot(cities: cities, units: units),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: _mapData(),
    ruleset: GameRuleset.defaults,
    ignoreFogOfWar: true,
  );
}

GameCity _city() {
  return const GameCity(
    id: 'capital',
    ownerPlayerId: 'player_1',
    name: 'Capital',
    center: CityHex(col: 1, row: 1),
  );
}

GameUnit _unit(String id, {GameUnitType type = GameUnitType.warrior}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: type,
    name: type.defaultNameToken,
    col: 1,
    row: 1,
  );
}

WorldMap _mapData() {
  return WorldMap(
    cols: 3,
    rows: 3,
    tiles: [
      for (var col = 0; col < 3; col++)
        for (var row = 0; row < 3; row++)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
