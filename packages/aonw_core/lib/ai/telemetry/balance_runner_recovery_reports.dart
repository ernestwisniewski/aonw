part of 'balance_runner.dart';

class CitySpacingReport {
  const CitySpacingReport({
    required this.cityCount,
    required this.pairCount,
    required this.minimumDistance,
    required this.averageDistance,
  });

  factory CitySpacingReport.fromCenters(Iterable<HexCoordinate> centers) {
    final orderedCenters = centers.toList();
    if (orderedCenters.length < 2) {
      return CitySpacingReport(
        cityCount: orderedCenters.length,
        pairCount: 0,
        minimumDistance: null,
        averageDistance: null,
      );
    }

    var pairCount = 0;
    var totalDistance = 0;
    int? minimumDistance;
    for (var left = 0; left < orderedCenters.length; left++) {
      for (var right = left + 1; right < orderedCenters.length; right++) {
        final distance = HexDistance.between(
          orderedCenters[left],
          orderedCenters[right],
        );
        pairCount += 1;
        totalDistance += distance;
        if (minimumDistance == null || distance < minimumDistance) {
          minimumDistance = distance;
        }
      }
    }

    return CitySpacingReport(
      cityCount: orderedCenters.length,
      pairCount: pairCount,
      minimumDistance: minimumDistance,
      averageDistance: totalDistance / pairCount,
    );
  }

  final int cityCount;
  final int pairCount;
  final int? minimumDistance;
  final double? averageDistance;
}

class OpeningSurvivalTurnSample {
  const OpeningSurvivalTurnSample({
    required this.turn,
    required this.cityCount,
    required this.settlerCount,
    required this.militaryCount,
    required this.unitCount,
  });

  factory OpeningSurvivalTurnSample.fromRow(EconomySimulationTurnRow row) {
    return OpeningSurvivalTurnSample(
      turn: row.turn,
      cityCount: row.cityCount,
      settlerCount: row.settlerCount,
      militaryCount: row.militaryCount,
      unitCount: row.unitCount,
    );
  }

  final int turn;
  final int cityCount;
  final int settlerCount;
  final int militaryCount;
  final int unitCount;
}

class OpeningSurvivalReport {
  const OpeningSurvivalReport({
    required this.firstCityTurn,
    required this.settlerLostBeforeFirstCityTurn,
    required this.firstCityLostTurn,
    required this.lastMilitaryLostTurn,
    required this.eliminationTurn,
    required this.finalCityCount,
    required this.finalMilitaryCount,
    required this.finalUnitCount,
  });

  factory OpeningSurvivalReport.fromSamples(
    Iterable<OpeningSurvivalTurnSample> samples,
  ) {
    final orderedSamples = samples.toList()
      ..sort((left, right) => left.turn.compareTo(right.turn));
    int? firstCityTurn;
    int? settlerLostBeforeFirstCityTurn;
    int? firstCityLostTurn;
    int? lastMilitaryLostTurn;
    int? eliminationTurn;
    var hadCity = false;
    var hadMilitary = false;
    var finalCityCount = 0;
    var finalMilitaryCount = 0;
    var finalUnitCount = 0;

    for (final sample in orderedSamples) {
      finalCityCount = sample.cityCount;
      finalMilitaryCount = sample.militaryCount;
      finalUnitCount = sample.unitCount;

      if (firstCityTurn == null && sample.cityCount > 0) {
        firstCityTurn = sample.turn;
      }
      if (settlerLostBeforeFirstCityTurn == null &&
          firstCityTurn == null &&
          sample.cityCount == 0 &&
          sample.settlerCount == 0) {
        settlerLostBeforeFirstCityTurn = sample.turn;
      }
      if (sample.cityCount > 0) {
        hadCity = true;
      } else if (hadCity && firstCityLostTurn == null) {
        firstCityLostTurn = sample.turn;
      }

      if (sample.militaryCount > 0) {
        hadMilitary = true;
      } else if (hadMilitary && lastMilitaryLostTurn == null) {
        lastMilitaryLostTurn = sample.turn;
      }

      if (eliminationTurn == null &&
          sample.cityCount == 0 &&
          sample.unitCount == 0) {
        eliminationTurn = sample.turn;
      }
    }

    return OpeningSurvivalReport(
      firstCityTurn: firstCityTurn,
      settlerLostBeforeFirstCityTurn: settlerLostBeforeFirstCityTurn,
      firstCityLostTurn: firstCityLostTurn,
      lastMilitaryLostTurn: lastMilitaryLostTurn,
      eliminationTurn: eliminationTurn,
      finalCityCount: finalCityCount,
      finalMilitaryCount: finalMilitaryCount,
      finalUnitCount: finalUnitCount,
    );
  }

  final int? firstCityTurn;
  final int? settlerLostBeforeFirstCityTurn;
  final int? firstCityLostTurn;
  final int? lastMilitaryLostTurn;
  final int? eliminationTurn;
  final int finalCityCount;
  final int finalMilitaryCount;
  final int finalUnitCount;

  bool get foundedCity => firstCityTurn != null;
  bool get lostSettlerBeforeFirstCity => settlerLostBeforeFirstCityTurn != null;
  bool get lostFirstCity => firstCityLostTurn != null;
  bool get lostLastMilitary => lastMilitaryLostTurn != null;
  bool get eliminated => eliminationTurn != null;
  bool get finishedWithoutCity => finalCityCount == 0;
}

class ExpansionRecoveryTurnSample {
  const ExpansionRecoveryTurnSample({
    required this.turn,
    required this.cityCount,
    required this.settlerCount,
    required this.militaryCount,
    required this.unitQueueCount,
    required this.foundCityCommands,
    required this.startUnitCommands,
    required this.startBuildingCommands,
    required this.startProjectCommands,
    required this.attackCommands,
  });

  factory ExpansionRecoveryTurnSample.fromRow(EconomySimulationTurnRow row) {
    return ExpansionRecoveryTurnSample(
      turn: row.turn,
      cityCount: row.cityCount,
      settlerCount: row.settlerCount,
      militaryCount: row.militaryCount,
      unitQueueCount: row.unitQueues,
      foundCityCommands: row.foundCityCommands,
      startUnitCommands: row.startUnitCommands,
      startBuildingCommands: row.startBuildingCommands,
      startProjectCommands: row.startProjectCommands,
      attackCommands: row.attackCommands,
    );
  }

  final int turn;
  final int cityCount;
  final int settlerCount;
  final int militaryCount;
  final int unitQueueCount;
  final int foundCityCommands;
  final int startUnitCommands;
  final int startBuildingCommands;
  final int startProjectCommands;
  final int attackCommands;
}

class ExpansionRecoveryReport {
  const ExpansionRecoveryReport({
    required this.firstCityTurn,
    required this.secondCityTurn,
    required this.thirdCityTurn,
    required this.maxCityCount,
    required this.firstPostCitySettlerTurn,
    required this.firstPostCityFoundCommandTurn,
    required this.firstPostSecondCitySettlerTurn,
    required this.firstPostSecondCityFoundCommandTurn,
    required this.firstDropBelowTwoAfterSecondCityTurn,
    required this.oneCityNoSettlerTurns,
    required this.oneCityWithSettlerTurns,
    required this.oneCityUnitQueueTurns,
    required this.oneCityStartUnitCommands,
    required this.oneCityAttackCommands,
    required this.twoCityNoSettlerTurns,
    required this.twoCityWithSettlerTurns,
    required this.twoCityUnitQueueTurns,
    required this.twoCityStartUnitCommands,
    required this.twoCityStartBuildingCommands,
    required this.twoCityStartProjectCommands,
    required this.twoCityAttackCommands,
    required this.cityCountDropCount,
    required this.finalCityCount,
    required this.finalSettlerCount,
    required this.finalMilitaryCount,
  });

  factory ExpansionRecoveryReport.fromSamples(
    Iterable<ExpansionRecoveryTurnSample> samples,
  ) {
    final orderedSamples = samples.toList()
      ..sort((left, right) => left.turn.compareTo(right.turn));
    final builder = _ExpansionRecoveryReportBuilder();
    for (final sample in orderedSamples) {
      builder.capture(sample);
    }
    return builder.build();
  }

  final int? firstCityTurn;
  final int? secondCityTurn;
  final int? thirdCityTurn;
  final int maxCityCount;
  final int? firstPostCitySettlerTurn;
  final int? firstPostCityFoundCommandTurn;
  final int? firstPostSecondCitySettlerTurn;
  final int? firstPostSecondCityFoundCommandTurn;
  final int? firstDropBelowTwoAfterSecondCityTurn;
  final int oneCityNoSettlerTurns;
  final int oneCityWithSettlerTurns;
  final int oneCityUnitQueueTurns;
  final int oneCityStartUnitCommands;
  final int oneCityAttackCommands;
  final int twoCityNoSettlerTurns;
  final int twoCityWithSettlerTurns;
  final int twoCityUnitQueueTurns;
  final int twoCityStartUnitCommands;
  final int twoCityStartBuildingCommands;
  final int twoCityStartProjectCommands;
  final int twoCityAttackCommands;
  final int cityCountDropCount;
  final int finalCityCount;
  final int finalSettlerCount;
  final int finalMilitaryCount;

  bool get foundedSecondCity => secondCityTurn != null;
  bool get foundedThirdCity => thirdCityTurn != null;
  bool get finishedBelowTwoCities => finalCityCount < 2;
  bool get lostSecondCityAfterFounding =>
      firstDropBelowTwoAfterSecondCityTurn != null;
}

class _ExpansionRecoveryReportBuilder {
  int? firstCityTurn;
  int? secondCityTurn;
  int? thirdCityTurn;
  int? firstDropBelowTwoAfterSecondCityTurn;
  int? firstPostCitySettlerTurn;
  int? firstPostCityFoundCommandTurn;
  int? firstPostSecondCitySettlerTurn;
  int? firstPostSecondCityFoundCommandTurn;
  int? previousCityCount;
  var maxCityCount = 0;
  var oneCityNoSettlerTurns = 0;
  var oneCityWithSettlerTurns = 0;
  var oneCityUnitQueueTurns = 0;
  var oneCityStartUnitCommands = 0;
  var oneCityAttackCommands = 0;
  var twoCityNoSettlerTurns = 0;
  var twoCityWithSettlerTurns = 0;
  var twoCityUnitQueueTurns = 0;
  var twoCityStartUnitCommands = 0;
  var twoCityStartBuildingCommands = 0;
  var twoCityStartProjectCommands = 0;
  var twoCityAttackCommands = 0;
  var cityCountDropCount = 0;
  var finalCityCount = 0;
  var finalSettlerCount = 0;
  var finalMilitaryCount = 0;

  void capture(ExpansionRecoveryTurnSample sample) {
    final hadFirstCityBeforeSample = firstCityTurn != null;
    final hadSecondCityBeforeSample = secondCityTurn != null;

    _captureLatestShape(sample);
    _captureFoundingMilestones(
      sample,
      hadFirstCityBeforeSample: hadFirstCityBeforeSample,
      hadSecondCityBeforeSample: hadSecondCityBeforeSample,
    );
    _captureExpansionWindow(
      sample,
      hadFirstCityBeforeSample: hadFirstCityBeforeSample,
    );
    previousCityCount = sample.cityCount;
  }

  void _captureLatestShape(ExpansionRecoveryTurnSample sample) {
    finalCityCount = sample.cityCount;
    finalSettlerCount = sample.settlerCount;
    finalMilitaryCount = sample.militaryCount;
    if (sample.cityCount > maxCityCount) {
      maxCityCount = sample.cityCount;
    }
    if (previousCityCount != null && sample.cityCount < previousCityCount!) {
      cityCountDropCount += 1;
    }
  }

  void _captureFoundingMilestones(
    ExpansionRecoveryTurnSample sample, {
    required bool hadFirstCityBeforeSample,
    required bool hadSecondCityBeforeSample,
  }) {
    if (firstCityTurn == null && sample.cityCount > 0) {
      firstCityTurn = sample.turn;
    }
    if (secondCityTurn == null && sample.cityCount >= 2) {
      secondCityTurn = sample.turn;
    }
    _captureSecondCityFoundCommand(
      sample,
      hadFirstCityBeforeSample: hadFirstCityBeforeSample,
      hadSecondCityBeforeSample: hadSecondCityBeforeSample,
    );
    _captureThirdCityMilestone(
      sample,
      hadSecondCityBeforeSample: hadSecondCityBeforeSample,
    );
    if (secondCityTurn != null &&
        sample.turn > secondCityTurn! &&
        sample.cityCount < 2) {
      firstDropBelowTwoAfterSecondCityTurn ??= sample.turn;
    }
  }

  void _captureSecondCityFoundCommand(
    ExpansionRecoveryTurnSample sample, {
    required bool hadFirstCityBeforeSample,
    required bool hadSecondCityBeforeSample,
  }) {
    if (hadSecondCityBeforeSample) return;
    if (secondCityTurn != sample.turn) return;
    if (sample.foundCityCommands == 0) return;
    if (!hadFirstCityBeforeSample) return;
    if (firstCityTurn == null || sample.turn <= firstCityTurn!) return;
    firstPostCityFoundCommandTurn ??= sample.turn;
  }

  void _captureThirdCityMilestone(
    ExpansionRecoveryTurnSample sample, {
    required bool hadSecondCityBeforeSample,
  }) {
    if (thirdCityTurn != null || sample.cityCount < 3) return;
    if (hadSecondCityBeforeSample && sample.foundCityCommands > 0) {
      firstPostSecondCityFoundCommandTurn ??= sample.turn;
    }
    thirdCityTurn = sample.turn;
  }

  void _captureExpansionWindow(
    ExpansionRecoveryTurnSample sample, {
    required bool hadFirstCityBeforeSample,
  }) {
    if (_waitingForSecondCity(sample)) {
      _captureOneCityExpansionWindow(
        sample,
        hadFirstCityBeforeSample: hadFirstCityBeforeSample,
      );
      return;
    }
    if (_waitingForThirdCity(sample)) {
      _captureTwoCityExpansionWindow(sample);
    }
  }

  bool _waitingForSecondCity(ExpansionRecoveryTurnSample sample) {
    return firstCityTurn != null &&
        secondCityTurn == null &&
        sample.cityCount == 1;
  }

  bool _waitingForThirdCity(ExpansionRecoveryTurnSample sample) {
    return secondCityTurn != null &&
        thirdCityTurn == null &&
        sample.cityCount == 2;
  }

  void _captureOneCityExpansionWindow(
    ExpansionRecoveryTurnSample sample, {
    required bool hadFirstCityBeforeSample,
  }) {
    if (sample.settlerCount > 0) {
      firstPostCitySettlerTurn ??= sample.turn;
      oneCityWithSettlerTurns += 1;
    } else {
      oneCityNoSettlerTurns += 1;
    }
    if (sample.foundCityCommands > 0 &&
        hadFirstCityBeforeSample &&
        firstCityTurn != null &&
        sample.turn > firstCityTurn!) {
      firstPostCityFoundCommandTurn ??= sample.turn;
    }
    if (sample.unitQueueCount > 0) {
      oneCityUnitQueueTurns += 1;
    }
    oneCityStartUnitCommands += sample.startUnitCommands;
    oneCityAttackCommands += sample.attackCommands;
  }

  void _captureTwoCityExpansionWindow(ExpansionRecoveryTurnSample sample) {
    if (sample.settlerCount > 0) {
      firstPostSecondCitySettlerTurn ??= sample.turn;
      twoCityWithSettlerTurns += 1;
    } else {
      twoCityNoSettlerTurns += 1;
    }
    if (sample.foundCityCommands > 0 &&
        secondCityTurn != null &&
        sample.turn > secondCityTurn!) {
      firstPostSecondCityFoundCommandTurn ??= sample.turn;
    }
    if (sample.unitQueueCount > 0) {
      twoCityUnitQueueTurns += 1;
    }
    twoCityStartUnitCommands += sample.startUnitCommands;
    twoCityStartBuildingCommands += sample.startBuildingCommands;
    twoCityStartProjectCommands += sample.startProjectCommands;
    twoCityAttackCommands += sample.attackCommands;
  }

  ExpansionRecoveryReport build() {
    return ExpansionRecoveryReport(
      firstCityTurn: firstCityTurn,
      secondCityTurn: secondCityTurn,
      thirdCityTurn: thirdCityTurn,
      maxCityCount: maxCityCount,
      firstPostCitySettlerTurn: firstPostCitySettlerTurn,
      firstPostCityFoundCommandTurn: firstPostCityFoundCommandTurn,
      firstPostSecondCitySettlerTurn: firstPostSecondCitySettlerTurn,
      firstPostSecondCityFoundCommandTurn: firstPostSecondCityFoundCommandTurn,
      firstDropBelowTwoAfterSecondCityTurn:
          firstDropBelowTwoAfterSecondCityTurn,
      oneCityNoSettlerTurns: oneCityNoSettlerTurns,
      oneCityWithSettlerTurns: oneCityWithSettlerTurns,
      oneCityUnitQueueTurns: oneCityUnitQueueTurns,
      oneCityStartUnitCommands: oneCityStartUnitCommands,
      oneCityAttackCommands: oneCityAttackCommands,
      twoCityNoSettlerTurns: twoCityNoSettlerTurns,
      twoCityWithSettlerTurns: twoCityWithSettlerTurns,
      twoCityUnitQueueTurns: twoCityUnitQueueTurns,
      twoCityStartUnitCommands: twoCityStartUnitCommands,
      twoCityStartBuildingCommands: twoCityStartBuildingCommands,
      twoCityStartProjectCommands: twoCityStartProjectCommands,
      twoCityAttackCommands: twoCityAttackCommands,
      cityCountDropCount: cityCountDropCount,
      finalCityCount: finalCityCount,
      finalSettlerCount: finalSettlerCount,
      finalMilitaryCount: finalMilitaryCount,
    );
  }
}
