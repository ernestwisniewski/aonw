import 'package:aonw_core/ai/simulation/score_comeback_telemetry_fixture.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ScoreComebackTelemetryFixture', () {
    test('generates score-pressure samples for a chasing player', () {
      final result = const ScoreComebackTelemetryFixture().run();
      final turnLimit = ScoreComebackTelemetryFixture.turnLimit;
      final player = result.telemetry.player(
        ScoreComebackTelemetryFixture.activePlayerId,
      );

      expect(result.rows, hasLength(6));
      expect(result.rows.map((row) => row.turn), [
        turnLimit - 5,
        turnLimit - 4,
        turnLimit - 3,
        turnLimit - 2,
        turnLimit - 1,
        turnLimit,
      ]);
      expect(result.rows.every((row) => row.scoreGap > 0), isTrue);
      expect(result.telemetry.victoryTurn, turnLimit);
      expect(result.telemetry.victoryCondition, GameOutcomeCondition.score);
      expect(
        result.telemetry.winnerPlayerId,
        ScoreComebackTelemetryFixture.leaderPlayerId,
      );
      expect(player.objectiveActionSampleCount, 6);
      expect(player.objectiveActionAdviceCounts, {
        GameObjectiveAdvice.constructBuilding: 2,
        GameObjectiveAdvice.unlockTechnology: 2,
        GameObjectiveAdvice.collectGold: 2,
      });
      expect(player.objectiveActionTargetCounts, {
        BalanceTelemetryObjectiveActionTarget.cityProduction: 4,
        BalanceTelemetryObjectiveActionTarget.research: 2,
      });
      expect(result.telemetry.findings, isEmpty);
    });

    test('exports a stable CSV contract', () {
      final csv = const ScoreComebackTelemetryFixture().run().toCsv();
      final turnLimit = ScoreComebackTelemetryFixture.turnLimit;

      expect(
        csv,
        contains('turn,scenario,active_score,leader_score,score_gap,advice'),
      );
      expect(csv, contains('${turnLimit - 5},production_gap,'));
      expect(csv, contains(',constructBuilding,cityProduction,'));
      expect(csv, contains('${turnLimit - 3},research_gap,'));
      expect(csv, contains(',unlockTechnology,research,'));
      expect(csv, contains('${turnLimit - 1},economy_gap,'));
      expect(csv, contains(',collectGold,cityProduction,'));
      expect(csv, contains('$turnLimit,economy_gap,'));
      expect(csv, contains(',score'));
    });
  });
}
