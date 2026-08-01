import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AiContext', () {
    test('copyWith can clear nullable planning metadata', () {
      final context = AiContext(
        ruleset: GameRuleset.defaults,
        mapData: WorldMap(cols: 0, rows: 0, tiles: []),
        turn: 3,
        rng: AiRng(42),
        strategicPlan: const StrategicPlan(
          computedAtTurn: 2,
          mode: StrategicMode.consolidate,
          expectations: EconomyExpectations(
            expectedCityCount: 2,
            expectedWorkerCount: 1,
            expectedMilitaryCount: 2,
            goldReserveTarget: 8,
            minimumSciencePerTurn: 4,
          ),
        ),
        scoreRace: const ScoreRaceAnalysis(
          playerId: 'player_1',
          player: EmpireScoreBreakdown(
            playerId: 'player_1',
            cityScore: 40,
            populationScore: 12,
            territoryScore: 6,
            buildingScore: 0,
            unitScore: 4,
            technologyScore: 18,
            improvementScore: 0,
            goldScore: 0,
          ),
          leader: null,
          runnerUp: null,
          turn: 3,
          turnLimit: 120,
          remainingTurns: 117,
          pressureWindowTurns: 20,
        ),
        deadline: DateTime.utc(2026, 7, 9, 12),
      );

      final cleared = context.copyWith(
        strategicPlan: null,
        scoreRace: null,
        deadline: null,
      );

      expect(cleared.strategicPlan, isNull);
      expect(cleared.scoreRace, isNull);
      expect(cleared.deadline, isNull);
    });
  });
}
