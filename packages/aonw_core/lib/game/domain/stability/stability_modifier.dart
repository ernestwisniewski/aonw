class StabilityModifier {
  final double productionMultiplier;
  final double goldMultiplier;
  final int foodBonus;
  final bool haltsGrowth;

  const StabilityModifier({
    required this.productionMultiplier,
    required this.goldMultiplier,
    required this.foodBonus,
    required this.haltsGrowth,
  });

  static const StabilityModifier stable = StabilityModifier(
    productionMultiplier: 1.0,
    goldMultiplier: 1.0,
    foodBonus: 0,
    haltsGrowth: false,
  );

  @override
  bool operator ==(Object other) {
    return other is StabilityModifier &&
        other.productionMultiplier == productionMultiplier &&
        other.goldMultiplier == goldMultiplier &&
        other.foodBonus == foodBonus &&
        other.haltsGrowth == haltsGrowth;
  }

  @override
  int get hashCode =>
      Object.hash(productionMultiplier, goldMultiplier, foodBonus, haltsGrowth);
}
