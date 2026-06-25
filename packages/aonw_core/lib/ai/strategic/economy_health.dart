import 'package:aonw_core/ai/empire_assessment.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/economy_expectations.dart';
import 'package:aonw_core/game/domain/technology.dart';

class EconomyHealth {
  final int underperformanceStreak;
  final double cityRatio;
  final double workerRatio;
  final double militaryRatio;
  final double goldReserveRatio;
  final double scienceRatio;
  final int sciencePerTurn;
  final bool cityBehind;
  final bool workerBehind;
  final bool militaryBehind;
  final bool goldBehind;
  final bool scienceBehind;

  const EconomyHealth({
    required this.underperformanceStreak,
    required this.cityRatio,
    required this.workerRatio,
    required this.militaryRatio,
    required this.goldReserveRatio,
    required this.scienceRatio,
    required this.sciencePerTurn,
    required this.cityBehind,
    required this.workerBehind,
    required this.militaryBehind,
    required this.goldBehind,
    required this.scienceBehind,
  });

  static const stable = EconomyHealth(
    underperformanceStreak: 0,
    cityRatio: 1,
    workerRatio: 1,
    militaryRatio: 1,
    goldReserveRatio: 1,
    scienceRatio: 1,
    sciencePerTurn: 0,
    cityBehind: false,
    workerBehind: false,
    militaryBehind: false,
    goldBehind: false,
    scienceBehind: false,
  );

  factory EconomyHealth.fromView({
    required GameView view,
    required AiEmpireAssessment assessment,
    required EconomyExpectations expectations,
    EconomyHealth? previous,
  }) {
    final sciencePerTurn = ScienceYieldCalculator.totalForPlayer(
      playerId: view.forPlayerId,
      cities: view.ownCities,
      research: ResearchState(players: {view.forPlayerId: view.ownResearch}),
      ruleset: view.ruleset.technology,
      cityRuleset: view.ruleset.city,
    ).total;
    final cityRatio = _ratio(
      assessment.cityCount,
      expectations.expectedCityCount,
    );
    final workerRatio = _ratio(
      assessment.workerCount,
      expectations.expectedWorkerCount,
    );
    final militaryRatio = _ratio(
      assessment.militaryCount,
      expectations.expectedMilitaryCount,
    );
    final goldReserveRatio = _ratio(
      assessment.goldReserve,
      expectations.goldReserveTarget,
    );
    final scienceRatio = _ratio(
      sciencePerTurn,
      expectations.minimumSciencePerTurn,
    );
    final hasCities = assessment.cityCount > 0;
    final cityBehind = hasCities && cityRatio < 0.80;
    final workerBehind = hasCities && workerRatio < 0.80;
    final militaryBehind =
        hasCities &&
        militaryRatio < 0.80 &&
        assessment.visibleEnemyMilitaryCount > 0;
    final goldBehind =
        hasCities &&
        (assessment.netGoldPerTurn < 0 ||
            (goldReserveRatio < 0.80 && assessment.netGoldPerTurn <= 0));
    final scienceBehind = hasCities && scienceRatio < 0.80;
    final currentlyBehind =
        cityBehind ||
        workerBehind ||
        militaryBehind ||
        goldBehind ||
        scienceBehind;
    final previousStreak = previous?.underperformanceStreak ?? 0;
    final streak = currentlyBehind ? _capStreak(previousStreak + 1) : 0;

    return EconomyHealth(
      underperformanceStreak: streak,
      cityRatio: cityRatio,
      workerRatio: workerRatio,
      militaryRatio: militaryRatio,
      goldReserveRatio: goldReserveRatio,
      scienceRatio: scienceRatio,
      sciencePerTurn: sciencePerTurn,
      cityBehind: cityBehind,
      workerBehind: workerBehind,
      militaryBehind: militaryBehind,
      goldBehind: goldBehind,
      scienceBehind: scienceBehind,
    );
  }

  bool get isBehind =>
      cityBehind ||
      workerBehind ||
      militaryBehind ||
      goldBehind ||
      scienceBehind;

  bool get needsRecovery {
    if (underperformanceStreak < 2) return false;
    return goldBehind ||
        cityRatio < 0.60 ||
        workerRatio < 0.60 ||
        scienceRatio < 0.60;
  }

  bool get needsConsolidation {
    if (underperformanceStreak == 0) return false;
    return workerBehind || militaryBehind || goldBehind || scienceBehind;
  }

  bool get canSustainTechRush {
    return !needsConsolidation &&
        goldReserveRatio >= 1.0 &&
        scienceRatio >= 1.0 &&
        workerRatio >= 0.90;
  }

  @override
  bool operator ==(Object other) {
    return other is EconomyHealth &&
        other.underperformanceStreak == underperformanceStreak &&
        other.cityRatio == cityRatio &&
        other.workerRatio == workerRatio &&
        other.militaryRatio == militaryRatio &&
        other.goldReserveRatio == goldReserveRatio &&
        other.scienceRatio == scienceRatio &&
        other.sciencePerTurn == sciencePerTurn &&
        other.cityBehind == cityBehind &&
        other.workerBehind == workerBehind &&
        other.militaryBehind == militaryBehind &&
        other.goldBehind == goldBehind &&
        other.scienceBehind == scienceBehind;
  }

  @override
  int get hashCode {
    return Object.hash(
      underperformanceStreak,
      cityRatio,
      workerRatio,
      militaryRatio,
      goldReserveRatio,
      scienceRatio,
      sciencePerTurn,
      cityBehind,
      workerBehind,
      militaryBehind,
      goldBehind,
      scienceBehind,
    );
  }
}

double _ratio(int actual, int expected) {
  if (expected <= 0) return 1;
  return actual / expected;
}

int _capStreak(int value) {
  if (value < 0) return 0;
  if (value > 3) return 3;
  return value;
}
