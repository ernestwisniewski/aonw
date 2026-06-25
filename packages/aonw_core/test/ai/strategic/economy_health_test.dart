import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('EconomyHealth', () {
    test('tracks consecutive underperformance and resets after recovery', () {
      final mapData = _map();
      final view = _view(
        mapData,
        _state(
          mapData: mapData,
          gold: 3,
          units: [
            GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 0, row: 0),
          ],
        ),
      );
      final context = _context(mapData);
      final assessment = AiEmpireAssessment.fromView(view, context);
      const demandingExpectations = EconomyExpectations(
        expectedCityCount: 2,
        expectedWorkerCount: 2,
        expectedMilitaryCount: 1,
        goldReserveTarget: 10,
        minimumSciencePerTurn: 4,
      );

      final first = EconomyHealth.fromView(
        view: view,
        assessment: assessment,
        expectations: demandingExpectations,
      );
      final second = EconomyHealth.fromView(
        view: view,
        assessment: assessment,
        expectations: demandingExpectations,
        previous: first,
      );
      const recoveredExpectations = EconomyExpectations(
        expectedCityCount: 1,
        expectedWorkerCount: 0,
        expectedMilitaryCount: 1,
        goldReserveTarget: 2,
        minimumSciencePerTurn: 2,
      );
      final recovered = EconomyHealth.fromView(
        view: view,
        assessment: assessment,
        expectations: recoveredExpectations,
        previous: second,
      );

      expect(first.underperformanceStreak, 1);
      expect(first.needsRecovery, isFalse);
      expect(second.underperformanceStreak, 2);
      expect(second.needsRecovery, isTrue);
      expect(recovered.underperformanceStreak, 0);
      expect(recovered.isBehind, isFalse);
    });

    test('ModeSelector recovers after repeated economic misses', () {
      final mapData = _map();
      const assessment = AiEmpireAssessment(
        playerId: 'player_1',
        cityCount: 1,
        workerCount: 1,
        settlerCount: 0,
        militaryCount: 1,
        visibleEnemyMilitaryCount: 0,
        goldReserve: 20,
        netGoldPerTurn: 3,
        desiredCityCount: 3,
        desiredWorkerCount: 1,
        desiredMilitaryCount: 1,
      );

      final mode = const ModeSelector().select(
        assessment: assessment,
        expectations: EconomyExpectations.fromAssessment(assessment),
        threats: const [],
        context: _context(mapData),
        economyHealth: const EconomyHealth(
          underperformanceStreak: 2,
          cityRatio: 1,
          workerRatio: 1,
          militaryRatio: 1,
          goldReserveRatio: 2,
          scienceRatio: 0.5,
          sciencePerTurn: 2,
          cityBehind: false,
          workerBehind: false,
          militaryBehind: false,
          goldBehind: false,
          scienceBehind: true,
        ),
      );

      expect(mode, StrategicMode.recover);
    });

    test(
      'StrategicPlanner carries previous economy misses into mode selection',
      () {
        final mapData = _map();
        final view = _view(
          mapData,
          _state(
            mapData: mapData,
            gold: 20,
            units: [
              GameUnit.startingWarrior(
                ownerPlayerId: 'player_1',
                col: 0,
                row: 0,
              ),
            ],
          ),
        );
        final context = _context(mapData);
        const previousPlan = StrategicPlan(
          computedAtTurn: 4,
          mode: StrategicMode.expand,
          expectations: EconomyExpectations(
            expectedCityCount: 2,
            expectedWorkerCount: 2,
            expectedMilitaryCount: 1,
            goldReserveTarget: 6,
            minimumSciencePerTurn: 4,
          ),
          economyHealth: EconomyHealth(
            underperformanceStreak: 1,
            cityRatio: 0.5,
            workerRatio: 0,
            militaryRatio: 1,
            goldReserveRatio: 3,
            scienceRatio: 0.5,
            sciencePerTurn: 2,
            cityBehind: true,
            workerBehind: true,
            militaryBehind: false,
            goldBehind: false,
            scienceBehind: true,
          ),
        );

        final plan = const StrategicPlanner().build(
          view: view,
          context: context,
          previousPlan: previousPlan,
        );

        expect(plan.economyHealth.underperformanceStreak, 2);
        expect(plan.mode, StrategicMode.recover);
      },
    );
  });
}

AiContext _context(MapData mapData) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: mapData,
    turn: 9,
    rng: AiRng.fromTurn(turn: 9, playerId: 'player_1', baseSeed: 1),
  );
}

GameView _view(MapData mapData, PersistentGameState state) {
  return GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 9,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

PersistentGameState _state({
  required MapData mapData,
  required int gold,
  required List<GameUnit> units,
}) {
  return PersistentGameState(
    units: units,
    cities: const [
      GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
      ),
    ],
    playerGold: {'player_1': gold},
    fogOfWar: FogOfWarState(
      players: {
        'player_1': PlayerFogOfWar(
          playerId: 'player_1',
          visibleHexes: {
            for (final tile in mapData.tiles)
              HexCoordinate(col: tile.col, row: tile.row),
          },
        ),
      },
    ),
  );
}

MapData _map() {
  return MapData(
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
        terrains: [TerrainType.plains],
        resources: [],
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
}
