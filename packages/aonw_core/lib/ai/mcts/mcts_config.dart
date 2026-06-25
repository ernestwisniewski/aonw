import 'package:aonw_core/ai/ai_difficulty.dart';

enum MctsExecutionMode { sync, background }

class MctsConfig {
  final MctsExecutionMode executionMode;
  final Duration wallClockBudget;
  final Duration minimumBudget;
  final Duration deadlineSafetyMargin;
  final int? iterationBudget;
  final int minIterations;
  final int maxPlanningDepth;
  final int candidateLimit;
  final int? sourcePlanDepthLimit;
  final bool simulateOpponentResponses;
  final bool simulateTurnEconomy;
  final double explorationConstant;

  const MctsConfig({
    this.executionMode = MctsExecutionMode.sync,
    this.wallClockBudget = const Duration(milliseconds: 1500),
    this.minimumBudget = const Duration(milliseconds: 100),
    this.deadlineSafetyMargin = const Duration(milliseconds: 50),
    this.iterationBudget,
    this.minIterations = 1,
    this.maxPlanningDepth = 8,
    this.candidateLimit = 16,
    this.sourcePlanDepthLimit,
    this.simulateOpponentResponses = true,
    this.simulateTurnEconomy = true,
    this.explorationConstant = 1.4,
  });

  factory MctsConfig.fromDifficulty(AiDifficulty difficulty) {
    return MctsConfig.fromDifficultyProfile(difficulty.profile.standardMcts);
  }

  factory MctsConfig.forBackground(AiDifficulty difficulty) {
    final base = MctsConfig.fromDifficulty(difficulty);
    return MctsConfig(
      executionMode: MctsExecutionMode.background,
      wallClockBudget: base.wallClockBudget,
      minimumBudget: base.minimumBudget,
      deadlineSafetyMargin: base.deadlineSafetyMargin,
      iterationBudget: base.iterationBudget,
      minIterations: base.minIterations,
      maxPlanningDepth: base.maxPlanningDepth,
      candidateLimit: base.candidateLimit,
      sourcePlanDepthLimit: base.sourcePlanDepthLimit,
      simulateOpponentResponses: base.simulateOpponentResponses,
      simulateTurnEconomy: base.simulateTurnEconomy,
      explorationConstant: base.explorationConstant,
    );
  }

  factory MctsConfig.forInteractive(AiDifficulty difficulty) {
    return MctsConfig.fromDifficultyProfile(difficulty.profile.interactiveMcts);
  }

  factory MctsConfig.forBatterySaver(AiDifficulty difficulty) {
    return MctsConfig.fromDifficultyProfile(
      difficulty.profile.batterySaverMcts,
    );
  }

  factory MctsConfig.fromDifficultyProfile(AiMctsDifficultyProfile profile) {
    return MctsConfig(
      wallClockBudget: Duration(milliseconds: profile.wallClockBudgetMs),
      minimumBudget: Duration(milliseconds: profile.minimumBudgetMs),
      deadlineSafetyMargin: Duration(
        milliseconds: profile.deadlineSafetyMarginMs,
      ),
      iterationBudget: profile.iterationBudget,
      minIterations: profile.minIterations,
      maxPlanningDepth: profile.maxPlanningDepth,
      candidateLimit: profile.candidateLimit,
      sourcePlanDepthLimit: profile.sourcePlanDepthLimit,
      simulateOpponentResponses: profile.simulateOpponentResponses,
      simulateTurnEconomy: profile.simulateTurnEconomy,
      explorationConstant: profile.explorationConstant,
    );
  }
}
