import 'package:aonw_core/game/domain/match_rules/game_length_config.dart';

class PaceBalance {
  final PaceProfile profile;
  final double researchCostMultiplier;
  final double unitProductionCostMultiplier;
  final double buildingProductionCostMultiplier;
  final double growthCostMultiplier;
  final double objectiveTargetMultiplier;
  final int improvementTurnsDelta;

  const PaceBalance({
    required this.profile,
    required this.researchCostMultiplier,
    required this.unitProductionCostMultiplier,
    required this.buildingProductionCostMultiplier,
    required this.growthCostMultiplier,
    this.objectiveTargetMultiplier = 1,
    this.improvementTurnsDelta = 0,
  });

  static const unlimited = PaceBalance(
    profile: PaceProfile.unlimited,
    researchCostMultiplier: 1,
    unitProductionCostMultiplier: 1.30,
    buildingProductionCostMultiplier: 1.45,
    growthCostMultiplier: 1.15,
    objectiveTargetMultiplier: 1,
    improvementTurnsDelta: 1,
  );

  static const standard60 = PaceBalance(
    profile: PaceProfile.standard60,
    researchCostMultiplier: 0.80,
    unitProductionCostMultiplier: 0.80,
    buildingProductionCostMultiplier: 0.85,
    growthCostMultiplier: 0.85,
    objectiveTargetMultiplier: 0.85,
  );

  static const normal90 = PaceBalance(
    profile: PaceProfile.normal90,
    researchCostMultiplier: 0.95,
    unitProductionCostMultiplier: 0.90,
    buildingProductionCostMultiplier: 0.92,
    growthCostMultiplier: 0.92,
    objectiveTargetMultiplier: 0.92,
  );

  static const long120 = PaceBalance(
    profile: PaceProfile.long120,
    researchCostMultiplier: 1.10,
    unitProductionCostMultiplier: 1,
    buildingProductionCostMultiplier: 1,
    growthCostMultiplier: 1,
    objectiveTargetMultiplier: 1,
  );

  static PaceBalance forGameLength(GameLengthConfig gameLength) {
    return forProfile(gameLength.paceProfile);
  }

  static PaceBalance forProfile(PaceProfile profile) {
    return switch (profile) {
      PaceProfile.unlimited => unlimited,
      PaceProfile.standard60 => standard60,
      PaceProfile.normal90 => normal90,
      PaceProfile.long120 => long120,
    };
  }

  int researchCost(int baseCost) {
    return scaleCost(baseCost, researchCostMultiplier);
  }

  int unitProductionCost(int baseCost) {
    return scaleCost(baseCost, unitProductionCostMultiplier);
  }

  int buildingProductionCost(int baseCost) {
    return scaleCost(baseCost, buildingProductionCostMultiplier);
  }

  int growthCost(int baseCost) {
    return scaleCost(baseCost, growthCostMultiplier);
  }

  int objectiveTarget(int baseTarget) {
    return scaleCost(baseTarget, objectiveTargetMultiplier);
  }

  int improvementTurns(int baseTurns) {
    if (baseTurns <= 0) return 0;
    final scaled = baseTurns + improvementTurnsDelta;
    return scaled < 1 ? 1 : scaled;
  }

  int scaleCost(int baseCost, double multiplier) {
    if (baseCost <= 0) return 0;
    final scaled = (baseCost * multiplier).ceil();
    return scaled < 1 ? 1 : scaled;
  }
}
