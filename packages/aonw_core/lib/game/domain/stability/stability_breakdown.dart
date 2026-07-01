class StabilityBreakdown {
  final String playerId;
  final int baseOrder;
  final int buildingSources;
  final int luxurySources;
  final int techSources;
  final int artifactSources;
  final int cityCost;
  final int populationCost;
  final int cohesionCost;
  final int conqueredCityCost;
  final int warWearinessCost;
  final int hegemonyTax;

  const StabilityBreakdown({
    required this.playerId,
    required this.baseOrder,
    required this.buildingSources,
    required this.luxurySources,
    required this.techSources,
    required this.artifactSources,
    required this.cityCost,
    required this.populationCost,
    required this.cohesionCost,
    required this.conqueredCityCost,
    required this.warWearinessCost,
    required this.hegemonyTax,
  });

  int get sources =>
      baseOrder +
      buildingSources +
      luxurySources +
      techSources +
      artifactSources;

  int get costs =>
      cityCost +
      populationCost +
      cohesionCost +
      conqueredCityCost +
      warWearinessCost +
      hegemonyTax;

  int get net => sources - costs;

  @override
  bool operator ==(Object other) {
    return other is StabilityBreakdown &&
        other.playerId == playerId &&
        other.baseOrder == baseOrder &&
        other.buildingSources == buildingSources &&
        other.luxurySources == luxurySources &&
        other.techSources == techSources &&
        other.artifactSources == artifactSources &&
        other.cityCost == cityCost &&
        other.populationCost == populationCost &&
        other.cohesionCost == cohesionCost &&
        other.conqueredCityCost == conqueredCityCost &&
        other.warWearinessCost == warWearinessCost &&
        other.hegemonyTax == hegemonyTax;
  }

  @override
  int get hashCode => Object.hash(
    playerId,
    baseOrder,
    buildingSources,
    luxurySources,
    techSources,
    artifactSources,
    cityCost,
    populationCost,
    cohesionCost,
    conqueredCityCost,
    warWearinessCost,
    hegemonyTax,
  );
}
