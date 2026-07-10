import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules/game_length_config.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/util/collection_equality.dart';

part 'balance_telemetry_objective_actions.dart';
part 'balance_telemetry_player_activity.dart';
part 'balance_telemetry_samples.dart';

enum BalanceTelemetryFindingSeverity { info, warning, critical }

class BalanceTelemetryTuningTargets {
  const BalanceTelemetryTuningTargets({
    this.firstTechnologyMaxTurn = 10,
    this.firstBuildingMaxTurn = 18,
    this.secondCityMaxTurn = 24,
    this.firstContactMaxTurn = 28,
    this.firstCombatMaxTurn = 40,
    this.dominationThresholdMaxTurn = 0,
    this.maxDeadTurnStreak = 2,
    this.finalTechnologyMinCount = 0,
    this.finalTechnologyMaxCount = 0,
    this.finalScienceMinPerTurn = 0,
    this.finalScienceMaxPerTurn = 0,
    this.finalCityMinCount = 0,
    this.finalCityMaxCount = 0,
  });

  static const standard = BalanceTelemetryTuningTargets();
  static const standard60 = BalanceTelemetryTuningTargets(
    firstTechnologyMaxTurn: 5,
    firstBuildingMaxTurn: 20,
    secondCityMaxTurn: 16,
    firstContactMaxTurn: 24,
    firstCombatMaxTurn: 36,
    dominationThresholdMaxTurn: 0,
    finalTechnologyMinCount: 15,
    finalTechnologyMaxCount: 42,
    finalScienceMinPerTurn: 6,
    finalScienceMaxPerTurn: 70,
    finalCityMinCount: 3,
    finalCityMaxCount: 6,
  );
  static const normal90 = BalanceTelemetryTuningTargets(
    firstTechnologyMaxTurn: 6,
    firstBuildingMaxTurn: 21,
    secondCityMaxTurn: 20,
    firstContactMaxTurn: 28,
    firstCombatMaxTurn: 48,
    dominationThresholdMaxTurn: 0,
    finalTechnologyMinCount: 18,
    finalTechnologyMaxCount: 48,
    finalScienceMinPerTurn: 8,
    finalScienceMaxPerTurn: 70,
    finalCityMinCount: 3,
    finalCityMaxCount: 6,
  );
  static const long120 = BalanceTelemetryTuningTargets(
    firstTechnologyMaxTurn: 6,
    firstBuildingMaxTurn: 23,
    secondCityMaxTurn: 24,
    firstContactMaxTurn: 32,
    firstCombatMaxTurn: 60,
    dominationThresholdMaxTurn: 0,
    finalTechnologyMinCount: 22,
    finalTechnologyMaxCount: 52,
    finalScienceMinPerTurn: 10,
    finalScienceMaxPerTurn: 70,
    finalCityMinCount: 3,
    finalCityMaxCount: 5,
  );

  final int firstTechnologyMaxTurn;
  final int firstBuildingMaxTurn;
  final int secondCityMaxTurn;
  final int firstContactMaxTurn;
  final int firstCombatMaxTurn;
  final int dominationThresholdMaxTurn;
  final int maxDeadTurnStreak;
  final int finalTechnologyMinCount;
  final int finalTechnologyMaxCount;
  final int finalScienceMinPerTurn;
  final int finalScienceMaxPerTurn;
  final int finalCityMinCount;
  final int finalCityMaxCount;

  static BalanceTelemetryTuningTargets forPaceProfile(PaceProfile profile) {
    return switch (profile) {
      PaceProfile.standard60 => standard60,
      PaceProfile.normal90 => normal90,
      PaceProfile.long120 => long120,
      PaceProfile.unlimited => standard,
    };
  }
}

class BalanceTelemetryFinding {
  const BalanceTelemetryFinding({
    required this.code,
    required this.severity,
    required this.message,
    this.playerId,
    this.turn,
  });

  final String code;
  final BalanceTelemetryFindingSeverity severity;
  final String message;
  final String? playerId;
  final int? turn;

  @override
  bool operator ==(Object other) {
    return other is BalanceTelemetryFinding &&
        other.code == code &&
        other.severity == severity &&
        other.message == message &&
        other.playerId == playerId &&
        other.turn == turn;
  }

  @override
  int get hashCode => Object.hash(code, severity, message, playerId, turn);
}

class BalanceTelemetryDeadTurnRun {
  const BalanceTelemetryDeadTurnRun({
    required this.playerId,
    required this.startTurn,
    required this.endTurn,
  });

  final String playerId;
  final int startTurn;
  final int endTurn;

  int get length => endTurn - startTurn + 1;

  @override
  bool operator ==(Object other) {
    return other is BalanceTelemetryDeadTurnRun &&
        other.playerId == playerId &&
        other.startTurn == startTurn &&
        other.endTurn == endTurn;
  }

  @override
  int get hashCode => Object.hash(playerId, startTurn, endTurn);
}

class BalanceTelemetryPlayerReport {
  const BalanceTelemetryPlayerReport({
    required this.playerId,
    this.firstTechnologyTurn,
    this.firstBuildingTurn,
    this.secondCityTurn,
    this.firstContactTurn,
    this.firstCombatTurn,
    this.firstDominationThresholdTurn,
    this.maxDominationControlPercent = 0,
    this.maxDominationHoldTurns = 0,
    this.deadTurnCount = 0,
    this.longestDeadTurnStreak = 0,
    this.deadTurnRuns = const [],
    this.objectiveActionAdviceCounts = const {},
    this.objectiveActionTargetCounts = const {},
    this.finalTechnologyCount = 0,
    this.finalSciencePerTurn,
    this.finalCityCount = 0,
    this.finalUnitCount = 0,
    this.finalGold,
    this.finalNetGoldPerTurn,
  });

  final String playerId;
  final int? firstTechnologyTurn;
  final int? firstBuildingTurn;
  final int? secondCityTurn;
  final int? firstContactTurn;
  final int? firstCombatTurn;
  final int? firstDominationThresholdTurn;
  final double maxDominationControlPercent;
  final int maxDominationHoldTurns;
  final int deadTurnCount;
  final int longestDeadTurnStreak;
  final List<BalanceTelemetryDeadTurnRun> deadTurnRuns;
  final Map<GameObjectiveAdvice, int> objectiveActionAdviceCounts;
  final Map<BalanceTelemetryObjectiveActionTarget, int>
  objectiveActionTargetCounts;
  final int finalTechnologyCount;
  final int? finalSciencePerTurn;
  final int finalCityCount;
  final int finalUnitCount;
  final int? finalGold;
  final int? finalNetGoldPerTurn;

  int get objectiveActionSampleCount => objectiveActionTargetCounts.values.fold(
    0,
    (total, count) => total + count,
  );

  @override
  bool operator ==(Object other) {
    return other is BalanceTelemetryPlayerReport &&
        other.playerId == playerId &&
        other.firstTechnologyTurn == firstTechnologyTurn &&
        other.firstBuildingTurn == firstBuildingTurn &&
        other.secondCityTurn == secondCityTurn &&
        other.firstContactTurn == firstContactTurn &&
        other.firstCombatTurn == firstCombatTurn &&
        other.firstDominationThresholdTurn == firstDominationThresholdTurn &&
        other.maxDominationControlPercent == maxDominationControlPercent &&
        other.maxDominationHoldTurns == maxDominationHoldTurns &&
        other.deadTurnCount == deadTurnCount &&
        other.longestDeadTurnStreak == longestDeadTurnStreak &&
        listEquals(other.deadTurnRuns, deadTurnRuns) &&
        mapEquals(
          other.objectiveActionAdviceCounts,
          objectiveActionAdviceCounts,
        ) &&
        mapEquals(
          other.objectiveActionTargetCounts,
          objectiveActionTargetCounts,
        ) &&
        other.finalTechnologyCount == finalTechnologyCount &&
        other.finalSciencePerTurn == finalSciencePerTurn &&
        other.finalCityCount == finalCityCount &&
        other.finalUnitCount == finalUnitCount &&
        other.finalGold == finalGold &&
        other.finalNetGoldPerTurn == finalNetGoldPerTurn;
  }

  @override
  int get hashCode => Object.hash(
    playerId,
    firstTechnologyTurn,
    firstBuildingTurn,
    secondCityTurn,
    firstContactTurn,
    firstCombatTurn,
    firstDominationThresholdTurn,
    maxDominationControlPercent,
    maxDominationHoldTurns,
    deadTurnCount,
    longestDeadTurnStreak,
    Object.hashAll(deadTurnRuns),
    mapHash(objectiveActionAdviceCounts),
    mapHash(objectiveActionTargetCounts),
    finalTechnologyCount,
    finalSciencePerTurn,
    finalCityCount,
    finalUnitCount,
    finalGold,
    finalNetGoldPerTurn,
  );
}

class BalanceTelemetryReport {
  const BalanceTelemetryReport({
    required this.firstTurn,
    required this.lastTurn,
    required this.players,
    this.victoryTurn,
    this.victoryCondition,
    this.winnerPlayerId,
    this.findings = const [],
  });

  final int? firstTurn;
  final int? lastTurn;
  final Map<String, BalanceTelemetryPlayerReport> players;
  final int? victoryTurn;
  final GameOutcomeCondition? victoryCondition;
  final String? winnerPlayerId;
  final List<BalanceTelemetryFinding> findings;

  int get sampleSpan =>
      firstTurn == null || lastTurn == null ? 0 : (lastTurn! - firstTurn! + 1);

  int get longestDeadTurnStreak {
    var longest = 0;
    for (final player in players.values) {
      if (player.longestDeadTurnStreak > longest) {
        longest = player.longestDeadTurnStreak;
      }
    }
    return longest;
  }

  BalanceTelemetryPlayerReport player(String playerId) {
    final report = players[playerId];
    if (report != null) return report;
    return BalanceTelemetryPlayerReport(playerId: playerId);
  }
}

class BalanceTelemetryAnalyzer {
  const BalanceTelemetryAnalyzer({
    this.targets = BalanceTelemetryTuningTargets.standard,
  });

  final BalanceTelemetryTuningTargets targets;

  BalanceTelemetryReport analyze({
    required Iterable<String> playerIds,
    required Iterable<BalanceTelemetryTurnSample> samples,
  }) {
    final orderedPlayers = _orderedDistinctPlayerIds(playerIds);
    final orderedSamples = samples.toList()
      ..sort((left, right) => left.turn.compareTo(right.turn));
    if (orderedSamples.isEmpty || orderedPlayers.isEmpty) {
      return const BalanceTelemetryReport(
        firstTurn: null,
        lastTurn: null,
        players: {},
      );
    }

    final builders = {
      for (final playerId in orderedPlayers) playerId: _PlayerReportBuilder(),
    };
    final activeDeadRuns = <String, int>{};
    BalanceTelemetryTurnSample? previousSample;
    int? victoryTurn;
    GameOutcomeCondition? victoryCondition;
    String? winnerPlayerId;

    for (final sample in orderedSamples) {
      if (victoryTurn != null) {
        for (final playerId in orderedPlayers) {
          builders[playerId]!.captureEndPace(
            playerId: playerId,
            sample: sample,
          );
        }
        previousSample = sample;
        continue;
      }
      for (final playerId in orderedPlayers) {
        final builder = builders[playerId]!
          ..captureMilestones(
            playerId: playerId,
            sample: sample,
            previous: previousSample,
          );
        final objectiveAction = sample.objectiveActionByPlayerId[playerId];
        if (objectiveAction != null) {
          builder.captureObjectiveAction(objectiveAction);
        }

        if (previousSample == null) continue;

        final deadTurn = _isDeadTurn(
          playerId: playerId,
          previous: previousSample.state,
          current: sample.state,
          events: sample.events,
          commandCount: sample.meaningfulCommandsByPlayerId[playerId] ?? 0,
        );
        if (deadTurn) {
          builder.deadTurnCount += 1;
          activeDeadRuns.putIfAbsent(playerId, () => sample.turn);
        } else {
          _closeDeadRun(
            builder: builder,
            playerId: playerId,
            activeDeadRuns: activeDeadRuns,
            endTurn: sample.turn - 1,
          );
        }
      }

      if (victoryTurn == null && sample.outcome.finished) {
        victoryTurn = sample.turn;
        victoryCondition = sample.outcome.condition;
        winnerPlayerId = sample.outcome.winnerPlayerId;
      }
      previousSample = sample;
    }

    final lastTurn = orderedSamples.last.turn;
    final findingLastTurn = victoryTurn ?? lastTurn;
    for (final playerId in orderedPlayers) {
      _closeDeadRun(
        builder: builders[playerId]!,
        playerId: playerId,
        activeDeadRuns: activeDeadRuns,
        endTurn: findingLastTurn,
      );
    }

    final playerReports = {
      for (final playerId in orderedPlayers)
        playerId: builders[playerId]!.build(playerId),
    };
    final findings = _findingsFor(
      players: playerReports.values,
      lastTurn: findingLastTurn,
      victoryCondition: victoryCondition,
      winnerPlayerId: winnerPlayerId,
    );

    return BalanceTelemetryReport(
      firstTurn: orderedSamples.first.turn,
      lastTurn: lastTurn,
      players: Map.unmodifiable(playerReports),
      victoryTurn: victoryTurn,
      victoryCondition: victoryCondition,
      winnerPlayerId: winnerPlayerId,
      findings: List.unmodifiable(findings),
    );
  }

  void _closeDeadRun({
    required _PlayerReportBuilder builder,
    required String playerId,
    required Map<String, int> activeDeadRuns,
    required int endTurn,
  }) {
    final startTurn = activeDeadRuns.remove(playerId);
    if (startTurn == null || endTurn < startTurn) return;
    final run = BalanceTelemetryDeadTurnRun(
      playerId: playerId,
      startTurn: startTurn,
      endTurn: endTurn,
    );
    builder.deadTurnRuns.add(run);
    if (run.length > builder.longestDeadTurnStreak) {
      builder.longestDeadTurnStreak = run.length;
    }
  }

  List<BalanceTelemetryFinding> _findingsFor({
    required Iterable<BalanceTelemetryPlayerReport> players,
    required int lastTurn,
    required GameOutcomeCondition? victoryCondition,
    required String? winnerPlayerId,
  }) {
    final findings = <BalanceTelemetryFinding>[];
    final militaryVictory = _isMilitaryVictory(victoryCondition);
    for (final player in players) {
      final suppressMilitaryWinnerLowPace = _isMilitaryVictoryWinner(
        player,
        victoryCondition,
        winnerPlayerId,
      );
      final suppressEndPaceFloors =
          militaryVictory || suppressMilitaryWinnerLowPace;
      _lateMilestoneFinding(
        findings: findings,
        playerId: player.playerId,
        code: 'late_first_technology',
        maxTurn: targets.firstTechnologyMaxTurn,
        observedTurn: player.firstTechnologyTurn,
        lastTurn: lastTurn,
        message: 'First technology is later than the tuning target.',
      );
      _lateMilestoneFinding(
        findings: findings,
        playerId: player.playerId,
        code: 'late_first_building',
        maxTurn: targets.firstBuildingMaxTurn,
        observedTurn: player.firstBuildingTurn,
        lastTurn: lastTurn,
        message: 'First building is later than the tuning target.',
      );
      if (!suppressMilitaryWinnerLowPace) {
        _lateMilestoneFinding(
          findings: findings,
          playerId: player.playerId,
          code: 'late_second_city',
          maxTurn: targets.secondCityMaxTurn,
          observedTurn: player.secondCityTurn,
          lastTurn: lastTurn,
          message: 'Second city is later than the tuning target.',
        );
      }
      _lateMilestoneFinding(
        findings: findings,
        playerId: player.playerId,
        code: 'late_first_contact',
        maxTurn: targets.firstContactMaxTurn,
        observedTurn: player.firstContactTurn,
        lastTurn: lastTurn,
        message: 'First contact is later than the tuning target.',
      );
      _lateMilestoneFinding(
        findings: findings,
        playerId: player.playerId,
        code: 'late_first_combat',
        maxTurn: targets.firstCombatMaxTurn,
        observedTurn: player.firstCombatTurn,
        lastTurn: lastTurn,
        message: 'First combat is later than the tuning target.',
      );
      if (targets.dominationThresholdMaxTurn > 0) {
        _lateMilestoneFinding(
          findings: findings,
          playerId: player.playerId,
          code: 'late_domination_threshold',
          maxTurn: targets.dominationThresholdMaxTurn,
          observedTurn: player.firstDominationThresholdTurn,
          lastTurn: lastTurn,
          message: 'Domination threshold is later than the tuning target.',
        );
      }
      if (player.longestDeadTurnStreak > targets.maxDeadTurnStreak) {
        findings.add(
          BalanceTelemetryFinding(
            code: 'dead_turn_streak',
            severity: BalanceTelemetryFindingSeverity.warning,
            playerId: player.playerId,
            turn: player.deadTurnRuns
                .where((run) => run.length == player.longestDeadTurnStreak)
                .first
                .startTurn,
            message: 'Dead-turn streak is longer than the tuning target.',
          ),
        );
      }
      _rangeFinding(
        findings: findings,
        playerId: player.playerId,
        value: player.finalTechnologyCount,
        min: suppressEndPaceFloors ? 0 : targets.finalTechnologyMinCount,
        max: targets.finalTechnologyMaxCount,
        lowCode: 'low_final_technology_count',
        highCode: 'high_final_technology_count',
        message: 'Final technology count is outside the tuning range.',
      );
      if (player.finalSciencePerTurn != null) {
        _rangeFinding(
          findings: findings,
          playerId: player.playerId,
          value: player.finalSciencePerTurn!,
          min: suppressEndPaceFloors ? 0 : targets.finalScienceMinPerTurn,
          max: targets.finalScienceMaxPerTurn,
          lowCode: 'low_final_science_per_turn',
          highCode: 'high_final_science_per_turn',
          message: 'Final science per turn is outside the tuning range.',
        );
      }
      _rangeFinding(
        findings: findings,
        playerId: player.playerId,
        value: player.finalCityCount,
        min: militaryVictory ? 0 : targets.finalCityMinCount,
        max: militaryVictory ? 0 : targets.finalCityMaxCount,
        lowCode: 'low_final_city_count',
        highCode: 'high_final_city_count',
        message: 'Final city count is outside the tuning range.',
      );
    }
    return findings;
  }

  bool _isMilitaryVictoryWinner(
    BalanceTelemetryPlayerReport player,
    GameOutcomeCondition? victoryCondition,
    String? winnerPlayerId,
  ) {
    return player.playerId == winnerPlayerId &&
        _isMilitaryVictory(victoryCondition);
  }

  bool _isMilitaryVictory(GameOutcomeCondition? victoryCondition) {
    return victoryCondition == GameOutcomeCondition.conquest ||
        victoryCondition == GameOutcomeCondition.domination;
  }

  void _lateMilestoneFinding({
    required List<BalanceTelemetryFinding> findings,
    required String playerId,
    required String code,
    required int maxTurn,
    required int? observedTurn,
    required int lastTurn,
    required String message,
  }) {
    if (observedTurn != null && observedTurn <= maxTurn) return;
    if (observedTurn == null && lastTurn < maxTurn) return;
    findings.add(
      BalanceTelemetryFinding(
        code: code,
        severity: BalanceTelemetryFindingSeverity.warning,
        playerId: playerId,
        turn: observedTurn,
        message: message,
      ),
    );
  }

  void _rangeFinding({
    required List<BalanceTelemetryFinding> findings,
    required String playerId,
    required int value,
    required int min,
    required int max,
    required String lowCode,
    required String highCode,
    required String message,
  }) {
    if (min > 0 && value < min) {
      findings.add(
        BalanceTelemetryFinding(
          code: lowCode,
          severity: BalanceTelemetryFindingSeverity.warning,
          playerId: playerId,
          message: message,
        ),
      );
      return;
    }
    if (max > 0 && value > max) {
      findings.add(
        BalanceTelemetryFinding(
          code: highCode,
          severity: BalanceTelemetryFindingSeverity.warning,
          playerId: playerId,
          message: message,
        ),
      );
    }
  }
}

class _PlayerReportBuilder {
  int? firstTechnologyTurn;
  int? firstBuildingTurn;
  int? secondCityTurn;
  int? firstContactTurn;
  int? firstCombatTurn;
  int? firstDominationThresholdTurn;
  double maxDominationControlPercent = 0;
  int maxDominationHoldTurns = 0;
  int deadTurnCount = 0;
  int longestDeadTurnStreak = 0;
  final deadTurnRuns = <BalanceTelemetryDeadTurnRun>[];
  final objectiveActionAdviceCounts = <GameObjectiveAdvice, int>{};
  final objectiveActionTargetCounts =
      <BalanceTelemetryObjectiveActionTarget, int>{};
  int finalTechnologyCount = 0;
  int? finalSciencePerTurn;
  int finalCityCount = 0;
  int finalUnitCount = 0;
  int? finalGold;
  int? finalNetGoldPerTurn;

  void captureMilestones({
    required String playerId,
    required BalanceTelemetryTurnSample sample,
    required BalanceTelemetryTurnSample? previous,
  }) {
    captureEndPace(playerId: playerId, sample: sample);
    final summary = _PlayerSnapshotSummary.fromState(sample.state, playerId);
    firstTechnologyTurn ??= summary.technologyCount > 0 ? sample.turn : null;
    firstBuildingTurn ??= summary.buildingCount > 0 ? sample.turn : null;
    secondCityTurn ??= summary.cityCount >= 2 ? sample.turn : null;
    firstContactTurn ??= _hasContact(sample.state, playerId)
        ? sample.turn
        : null;
    firstCombatTurn ??=
        _hasCombatEventForPlayer(
          playerId: playerId,
          state: sample.state,
          previousState: previous?.state,
          events: sample.events,
        )
        ? sample.turn
        : null;

    final domination = sample.dominationByPlayerId[playerId];
    if (domination == null) return;
    if (domination.controlPercent > maxDominationControlPercent) {
      maxDominationControlPercent = domination.controlPercent;
    }
    if (domination.holdTurns > maxDominationHoldTurns) {
      maxDominationHoldTurns = domination.holdTurns;
    }
    firstDominationThresholdTurn ??= domination.atThreshold
        ? sample.turn
        : null;
  }

  void captureEndPace({
    required String playerId,
    required BalanceTelemetryTurnSample sample,
  }) {
    final summary = _PlayerSnapshotSummary.fromState(sample.state, playerId);
    finalTechnologyCount = summary.technologyCount;
    finalCityCount = summary.cityCount;
    finalUnitCount = summary.unitCount;
    final endPace = sample.endPaceByPlayerId[playerId];
    if (endPace != null) {
      finalTechnologyCount = endPace.completedTechnologyCount;
      finalSciencePerTurn = endPace.sciencePerTurn;
      finalCityCount = endPace.cityCount;
      finalUnitCount = endPace.unitCount;
      finalGold = endPace.gold;
      finalNetGoldPerTurn = endPace.netGoldPerTurn;
    }
  }

  void captureObjectiveAction(BalanceTelemetryObjectiveActionSample sample) {
    objectiveActionAdviceCounts.update(
      sample.advice,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    objectiveActionTargetCounts.update(
      sample.target,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }

  BalanceTelemetryPlayerReport build(String playerId) {
    return BalanceTelemetryPlayerReport(
      playerId: playerId,
      firstTechnologyTurn: firstTechnologyTurn,
      firstBuildingTurn: firstBuildingTurn,
      secondCityTurn: secondCityTurn,
      firstContactTurn: firstContactTurn,
      firstCombatTurn: firstCombatTurn,
      firstDominationThresholdTurn: firstDominationThresholdTurn,
      maxDominationControlPercent: maxDominationControlPercent,
      maxDominationHoldTurns: maxDominationHoldTurns,
      deadTurnCount: deadTurnCount,
      longestDeadTurnStreak: longestDeadTurnStreak,
      deadTurnRuns: List.unmodifiable(deadTurnRuns),
      objectiveActionAdviceCounts: Map.unmodifiable(
        objectiveActionAdviceCounts,
      ),
      objectiveActionTargetCounts: Map.unmodifiable(
        objectiveActionTargetCounts,
      ),
      finalTechnologyCount: finalTechnologyCount,
      finalSciencePerTurn: finalSciencePerTurn,
      finalCityCount: finalCityCount,
      finalUnitCount: finalUnitCount,
      finalGold: finalGold,
      finalNetGoldPerTurn: finalNetGoldPerTurn,
    );
  }
}
