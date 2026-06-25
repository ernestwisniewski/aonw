import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('MctsBudget', () {
    test('keeps running until minimum iterations are reached', () {
      const budget = MctsBudget(wallClock: Duration.zero, minIterations: 3);

      expect(budget.exhausted(0, Duration.zero), isFalse);
      expect(budget.exhausted(2, const Duration(seconds: 1)), isFalse);
      expect(budget.exhausted(3, Duration.zero), isTrue);
    });

    test('trims wall clock budget to deadline minus safety margin', () {
      final now = DateTime.utc(2026, 4, 30, 12);
      final budget = MctsBudget.fromConfig(
        config: const MctsConfig(
          wallClockBudget: Duration(seconds: 3),
          deadlineSafetyMargin: Duration(milliseconds: 250),
        ),
        deadline: now.add(const Duration(seconds: 1)),
        now: () => now,
      );

      expect(budget.wallClock, const Duration(milliseconds: 750));
    });

    test('stops at the first exhausted budget after minimum iterations', () {
      const budget = MctsBudget(
        wallClock: Duration(milliseconds: 500),
        iterationBudget: 4,
        minIterations: 2,
      );

      expect(budget.exhausted(0, Duration.zero), isFalse);
      expect(budget.exhausted(3, Duration.zero), isFalse);
      expect(budget.exhausted(3, const Duration(milliseconds: 500)), isTrue);
      expect(budget.exhausted(4, Duration.zero), isTrue);
    });

    test('reads iteration budget from config', () {
      final budget = MctsBudget.fromConfig(
        config: const MctsConfig(iterationBudget: 7),
      );

      expect(budget.iterationBudget, 7);
    });

    test('interactive config caps local planning by difficulty', () {
      final easy = MctsConfig.forInteractive(AiDifficulty.easy);
      final normal = MctsConfig.forInteractive(AiDifficulty.normal);
      final hard = MctsConfig.forInteractive(AiDifficulty.hard);
      final veryHard = MctsConfig.forInteractive(AiDifficulty.veryHard);

      expect(easy.iterationBudget, 16);
      expect(normal.iterationBudget, 24);
      expect(hard.iterationBudget, 28);
      expect(veryHard.iterationBudget, 32);
      expect(easy.wallClockBudget, lessThan(normal.wallClockBudget));
      expect(normal.wallClockBudget, lessThan(hard.wallClockBudget));
      expect(hard.wallClockBudget, lessThan(veryHard.wallClockBudget));
      expect(hard.candidateLimit, lessThan(24));
      expect(easy.sourcePlanDepthLimit, 0);
      expect(normal.sourcePlanDepthLimit, 0);
      expect(hard.sourcePlanDepthLimit, 0);
      expect(veryHard.sourcePlanDepthLimit, 0);
      expect(easy.simulateOpponentResponses, isFalse);
      expect(normal.simulateOpponentResponses, isFalse);
      expect(hard.simulateOpponentResponses, isFalse);
      expect(veryHard.simulateOpponentResponses, isFalse);
      expect(easy.simulateTurnEconomy, isFalse);
      expect(normal.simulateTurnEconomy, isFalse);
      expect(hard.simulateTurnEconomy, isFalse);
      expect(veryHard.simulateTurnEconomy, isFalse);
    });

    test('standard config budgets rise with difficulty', () {
      final easy = MctsConfig.fromDifficulty(AiDifficulty.easy);
      final normal = MctsConfig.fromDifficulty(AiDifficulty.normal);
      final hard = MctsConfig.fromDifficulty(AiDifficulty.hard);
      final veryHard = MctsConfig.fromDifficulty(AiDifficulty.veryHard);

      expect(easy.wallClockBudget, lessThan(normal.wallClockBudget));
      expect(normal.wallClockBudget, lessThan(hard.wallClockBudget));
      expect(hard.wallClockBudget, lessThan(veryHard.wallClockBudget));
      expect(easy.candidateLimit, lessThan(normal.candidateLimit));
      expect(normal.candidateLimit, lessThan(hard.candidateLimit));
      expect(hard.candidateLimit, lessThan(veryHard.candidateLimit));
      expect(veryHard.maxPlanningDepth, 8);
      expect(veryHard.simulateOpponentResponses, isTrue);
      expect(veryHard.simulateTurnEconomy, isTrue);
    });

    test('battery saver config is tighter than interactive planning', () {
      final interactive = MctsConfig.forInteractive(AiDifficulty.normal);
      final saver = MctsConfig.forBatterySaver(AiDifficulty.normal);

      expect(saver.iterationBudget, lessThan(interactive.iterationBudget!));
      expect(saver.wallClockBudget, lessThan(interactive.wallClockBudget));
      expect(saver.maxPlanningDepth, lessThan(interactive.maxPlanningDepth));
      expect(saver.candidateLimit, lessThan(interactive.candidateLimit));
      expect(saver.sourcePlanDepthLimit, 0);
      expect(interactive.sourcePlanDepthLimit, 0);
      expect(saver.simulateOpponentResponses, isFalse);
      expect(interactive.simulateOpponentResponses, isFalse);
      expect(saver.simulateTurnEconomy, isFalse);
      expect(interactive.simulateTurnEconomy, isFalse);
      expect(
        MctsConfig.fromDifficulty(
          AiDifficulty.normal,
        ).simulateOpponentResponses,
        isTrue,
      );
      expect(
        MctsConfig.fromDifficulty(AiDifficulty.normal).simulateTurnEconomy,
        isTrue,
      );
    });
  });
}
