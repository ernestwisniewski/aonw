import 'package:aonw_core/ai/empire_assessment.dart';

class EconomyExpectations {
  final int expectedCityCount;
  final int expectedWorkerCount;
  final int expectedMilitaryCount;
  final int goldReserveTarget;
  final int minimumSciencePerTurn;

  const EconomyExpectations({
    required this.expectedCityCount,
    required this.expectedWorkerCount,
    required this.expectedMilitaryCount,
    required this.goldReserveTarget,
    required this.minimumSciencePerTurn,
  });

  factory EconomyExpectations.fromAssessment(AiEmpireAssessment assessment) {
    return EconomyExpectations(
      expectedCityCount: assessment.desiredCityCount,
      expectedWorkerCount: assessment.desiredWorkerCount,
      expectedMilitaryCount: assessment.desiredMilitaryCount,
      goldReserveTarget: 6 + assessment.cityCount * 2,
      minimumSciencePerTurn: (assessment.cityCount * 2).clamp(2, 12).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EconomyExpectations &&
        other.expectedCityCount == expectedCityCount &&
        other.expectedWorkerCount == expectedWorkerCount &&
        other.expectedMilitaryCount == expectedMilitaryCount &&
        other.goldReserveTarget == goldReserveTarget &&
        other.minimumSciencePerTurn == minimumSciencePerTurn;
  }

  @override
  int get hashCode {
    return Object.hash(
      expectedCityCount,
      expectedWorkerCount,
      expectedMilitaryCount,
      goldReserveTarget,
      minimumSciencePerTurn,
    );
  }
}
