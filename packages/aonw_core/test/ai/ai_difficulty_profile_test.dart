import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('AiDifficultyProfile', () {
    test('keeps veryHard as the unmodified current behavior profile', () {
      final profile = AiDifficulty.veryHard.profile;

      expect(profile.weightMultiplier, PersonaWeights.identity);
      expect(profile.combatRiskMultiplier, 1);
      expect(profile.militaryModeThresholdMultiplier, 1);
      expect(profile.warOpportunityThresholdMultiplier, 1);
      expect(profile.openingWarSurplus, 2);
      expect(profile.standardMcts.wallClockBudgetMs, 1500);
      expect(profile.standardMcts.maxPlanningDepth, 8);
      expect(profile.standardMcts.candidateLimit, 16);
    });

    test('reduces aggression and MCTS budgets below veryHard', () {
      final easy = AiDifficulty.easy.profile;
      final normal = AiDifficulty.normal.profile;
      final hard = AiDifficulty.hard.profile;
      final veryHard = AiDifficulty.veryHard.profile;

      expect(
        easy.weightMultiplier.aggression,
        lessThan(normal.weightMultiplier.aggression),
      );
      expect(
        normal.weightMultiplier.aggression,
        lessThan(hard.weightMultiplier.aggression),
      );
      expect(
        hard.weightMultiplier.aggression,
        lessThan(veryHard.weightMultiplier.aggression),
      );
      expect(easy.combatRiskMultiplier, lessThan(normal.combatRiskMultiplier));
      expect(normal.combatRiskMultiplier, lessThan(hard.combatRiskMultiplier));
      expect(
        hard.combatRiskMultiplier,
        lessThan(veryHard.combatRiskMultiplier),
      );
      expect(
        easy.interactiveMcts.iterationBudget,
        lessThan(normal.interactiveMcts.iterationBudget!),
      );
      expect(
        normal.interactiveMcts.iterationBudget,
        lessThan(hard.interactiveMcts.iterationBudget!),
      );
      expect(
        hard.interactiveMcts.iterationBudget,
        lessThan(veryHard.interactiveMcts.iterationBudget!),
      );
    });
  });
}
