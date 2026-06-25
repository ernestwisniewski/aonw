import 'package:aonw_core/ai/civilization/persona_weights.dart';

enum AiDifficulty { easy, normal, hard, veryHard }

class AiDifficultyProfile {
  final AiDifficulty difficulty;
  final PersonaWeights weightMultiplier;
  final double combatRiskMultiplier;
  final double militaryModeThresholdMultiplier;
  final double warOpportunityThresholdMultiplier;
  final int openingWarSurplus;
  final AiMctsDifficultyProfile standardMcts;
  final AiMctsDifficultyProfile interactiveMcts;
  final AiMctsDifficultyProfile batterySaverMcts;
  final AiMctsDifficultyProfile simulationMcts;

  const AiDifficultyProfile({
    required this.difficulty,
    required this.weightMultiplier,
    required this.combatRiskMultiplier,
    required this.militaryModeThresholdMultiplier,
    required this.warOpportunityThresholdMultiplier,
    required this.openingWarSurplus,
    required this.standardMcts,
    required this.interactiveMcts,
    required this.batterySaverMcts,
    required this.simulationMcts,
  });

  static const easy = AiDifficultyProfile(
    difficulty: AiDifficulty.easy,
    weightMultiplier: PersonaWeights(
      aggression: 0.65,
      expansion: 0.95,
      economy: 1.05,
      science: 0.95,
    ),
    combatRiskMultiplier: 0.80,
    militaryModeThresholdMultiplier: 1.35,
    warOpportunityThresholdMultiplier: 1.55,
    openingWarSurplus: 4,
    standardMcts: AiMctsDifficultyProfile(
      wallClockBudgetMs: 500,
      maxPlanningDepth: 4,
      candidateLimit: 6,
      explorationConstant: 1.15,
    ),
    interactiveMcts: AiMctsDifficultyProfile(
      wallClockBudgetMs: 350,
      iterationBudget: 16,
      maxPlanningDepth: 4,
      candidateLimit: 6,
      sourcePlanDepthLimit: 0,
      simulateOpponentResponses: false,
      simulateTurnEconomy: false,
      explorationConstant: 1.15,
    ),
    batterySaverMcts: AiMctsDifficultyProfile(
      wallClockBudgetMs: 220,
      iterationBudget: 8,
      maxPlanningDepth: 3,
      candidateLimit: 4,
      sourcePlanDepthLimit: 0,
      simulateOpponentResponses: false,
      simulateTurnEconomy: false,
      explorationConstant: 1.10,
    ),
    simulationMcts: AiMctsDifficultyProfile(
      iterationBudget: 16,
      minIterations: 16,
      maxPlanningDepth: 3,
      candidateLimit: 6,
    ),
  );

  static const normal = AiDifficultyProfile(
    difficulty: AiDifficulty.normal,
    weightMultiplier: PersonaWeights(
      aggression: 0.78,
      expansion: 1.00,
      economy: 1.05,
      science: 1.00,
    ),
    combatRiskMultiplier: 0.90,
    militaryModeThresholdMultiplier: 1.20,
    warOpportunityThresholdMultiplier: 1.30,
    openingWarSurplus: 3,
    standardMcts: AiMctsDifficultyProfile(
      wallClockBudgetMs: 800,
      maxPlanningDepth: 5,
      candidateLimit: 10,
      explorationConstant: 1.25,
    ),
    interactiveMcts: AiMctsDifficultyProfile(
      wallClockBudgetMs: 500,
      iterationBudget: 24,
      maxPlanningDepth: 5,
      candidateLimit: 9,
      sourcePlanDepthLimit: 0,
      simulateOpponentResponses: false,
      simulateTurnEconomy: false,
      explorationConstant: 1.25,
    ),
    batterySaverMcts: AiMctsDifficultyProfile(
      wallClockBudgetMs: 320,
      iterationBudget: 12,
      maxPlanningDepth: 4,
      candidateLimit: 6,
      sourcePlanDepthLimit: 0,
      simulateOpponentResponses: false,
      simulateTurnEconomy: false,
      explorationConstant: 1.20,
    ),
    simulationMcts: AiMctsDifficultyProfile(
      iterationBudget: 24,
      minIterations: 24,
      maxPlanningDepth: 3,
      candidateLimit: 8,
    ),
  );

  static const hard = AiDifficultyProfile(
    difficulty: AiDifficulty.hard,
    weightMultiplier: PersonaWeights(
      aggression: 0.90,
      expansion: 1.00,
      economy: 1.00,
      science: 1.00,
    ),
    combatRiskMultiplier: 0.96,
    militaryModeThresholdMultiplier: 1.10,
    warOpportunityThresholdMultiplier: 1.12,
    openingWarSurplus: 2,
    standardMcts: AiMctsDifficultyProfile(
      wallClockBudgetMs: 1100,
      maxPlanningDepth: 6,
      candidateLimit: 13,
      explorationConstant: 1.35,
    ),
    interactiveMcts: AiMctsDifficultyProfile(
      wallClockBudgetMs: 580,
      iterationBudget: 28,
      maxPlanningDepth: 6,
      candidateLimit: 11,
      sourcePlanDepthLimit: 0,
      simulateOpponentResponses: false,
      simulateTurnEconomy: false,
      explorationConstant: 1.32,
    ),
    batterySaverMcts: AiMctsDifficultyProfile(
      wallClockBudgetMs: 390,
      iterationBudget: 14,
      maxPlanningDepth: 4,
      candidateLimit: 7,
      sourcePlanDepthLimit: 0,
      simulateOpponentResponses: false,
      simulateTurnEconomy: false,
      explorationConstant: 1.28,
    ),
    simulationMcts: AiMctsDifficultyProfile(
      iterationBudget: 28,
      minIterations: 28,
      maxPlanningDepth: 4,
      candidateLimit: 10,
    ),
  );

  static const veryHard = AiDifficultyProfile(
    difficulty: AiDifficulty.veryHard,
    weightMultiplier: PersonaWeights.identity,
    combatRiskMultiplier: 1.00,
    militaryModeThresholdMultiplier: 1.00,
    warOpportunityThresholdMultiplier: 1.00,
    openingWarSurplus: 2,
    standardMcts: AiMctsDifficultyProfile(
      wallClockBudgetMs: 1500,
      minimumBudgetMs: 100,
      deadlineSafetyMarginMs: 50,
      minIterations: 1,
      maxPlanningDepth: 8,
      candidateLimit: 16,
      simulateOpponentResponses: true,
      simulateTurnEconomy: true,
      explorationConstant: 1.40,
    ),
    interactiveMcts: AiMctsDifficultyProfile(
      wallClockBudgetMs: 650,
      iterationBudget: 32,
      maxPlanningDepth: 6,
      candidateLimit: 12,
      sourcePlanDepthLimit: 0,
      simulateOpponentResponses: false,
      simulateTurnEconomy: false,
      explorationConstant: 1.40,
    ),
    batterySaverMcts: AiMctsDifficultyProfile(
      wallClockBudgetMs: 450,
      iterationBudget: 16,
      maxPlanningDepth: 5,
      candidateLimit: 8,
      sourcePlanDepthLimit: 0,
      simulateOpponentResponses: false,
      simulateTurnEconomy: false,
      explorationConstant: 1.40,
    ),
    simulationMcts: AiMctsDifficultyProfile(
      iterationBudget: 32,
      minIterations: 32,
      maxPlanningDepth: 4,
      candidateLimit: 12,
    ),
  );

  static AiDifficultyProfile forDifficulty(AiDifficulty difficulty) {
    return switch (difficulty) {
      AiDifficulty.easy => easy,
      AiDifficulty.normal => normal,
      AiDifficulty.hard => hard,
      AiDifficulty.veryHard => veryHard,
    };
  }
}

class AiMctsDifficultyProfile {
  final int wallClockBudgetMs;
  final int minimumBudgetMs;
  final int deadlineSafetyMarginMs;
  final int? iterationBudget;
  final int minIterations;
  final int maxPlanningDepth;
  final int candidateLimit;
  final int? sourcePlanDepthLimit;
  final bool simulateOpponentResponses;
  final bool simulateTurnEconomy;
  final double explorationConstant;

  const AiMctsDifficultyProfile({
    this.wallClockBudgetMs = 1500,
    this.minimumBudgetMs = 100,
    this.deadlineSafetyMarginMs = 50,
    this.iterationBudget,
    this.minIterations = 1,
    this.maxPlanningDepth = 8,
    this.candidateLimit = 16,
    this.sourcePlanDepthLimit,
    this.simulateOpponentResponses = true,
    this.simulateTurnEconomy = true,
    this.explorationConstant = 1.40,
  });
}

extension AiDifficultyProfileAccess on AiDifficulty {
  AiDifficultyProfile get profile => AiDifficultyProfile.forDifficulty(this);
}
