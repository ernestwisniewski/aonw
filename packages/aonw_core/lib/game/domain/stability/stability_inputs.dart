class StabilityInputs {
  final String playerId;
  final int cityCount;
  final int conqueredCityCount;
  final int sumCohesionCost;
  final int sumPopulationOverThreshold;
  final int buildingSources;
  final int luxurySources;
  final int techSources;
  final int artifactSources;
  final int wonderSources;
  final int warWeariness;
  final double controlPercent;
  final int playerCount;

  const StabilityInputs({
    required this.playerId,
    required this.cityCount,
    required this.conqueredCityCount,
    required this.sumCohesionCost,
    required this.sumPopulationOverThreshold,
    required this.buildingSources,
    required this.luxurySources,
    required this.techSources,
    required this.artifactSources,
    this.wonderSources = 0,
    required this.warWeariness,
    required this.controlPercent,
    required this.playerCount,
  });

  @override
  bool operator ==(Object other) {
    return other is StabilityInputs &&
        other.playerId == playerId &&
        other.cityCount == cityCount &&
        other.conqueredCityCount == conqueredCityCount &&
        other.sumCohesionCost == sumCohesionCost &&
        other.sumPopulationOverThreshold == sumPopulationOverThreshold &&
        other.buildingSources == buildingSources &&
        other.luxurySources == luxurySources &&
        other.techSources == techSources &&
        other.artifactSources == artifactSources &&
        other.wonderSources == wonderSources &&
        other.warWeariness == warWeariness &&
        other.controlPercent == controlPercent &&
        other.playerCount == playerCount;
  }

  @override
  int get hashCode => Object.hash(
    playerId,
    cityCount,
    conqueredCityCount,
    sumCohesionCost,
    sumPopulationOverThreshold,
    buildingSources,
    luxurySources,
    techSources,
    artifactSources,
    wonderSources,
    warWeariness,
    controlPercent,
    playerCount,
  );
}
