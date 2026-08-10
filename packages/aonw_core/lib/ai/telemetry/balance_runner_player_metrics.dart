part of 'balance_runner.dart';

extension BalanceBatchPlayerMetrics on BalanceBatchReport {
  double winRate(String playerId) {
    if (games.isEmpty) return 0;
    final wins = games.where((game) => game.winnerPlayerId == playerId).length;
    return wins / games.length;
  }

  double averageFinalTechnologyCount(String playerId) {
    return _averagePlayerMetric(
      playerId,
      (player) => player.finalTechnologyCount.toDouble(),
    );
  }

  double averageFinalSciencePerTurn(String playerId) {
    return _averagePlayerMetric(
      playerId,
      (player) => player.finalSciencePerTurn?.toDouble(),
    );
  }

  double averageFinalCityCount(String playerId) {
    return _averagePlayerMetric(
      playerId,
      (player) => player.finalCityCount.toDouble(),
    );
  }

  double averageFinalUnitCount(String playerId) {
    return _averagePlayerMetric(
      playerId,
      (player) => player.finalUnitCount.toDouble(),
    );
  }

  double averageFinalGold(String playerId) {
    return _averagePlayerMetric(
      playerId,
      (player) => player.finalGold?.toDouble(),
    );
  }

  double averageFinalNetGoldPerTurn(String playerId) {
    return _averagePlayerMetric(
      playerId,
      (player) => player.finalNetGoldPerTurn?.toDouble(),
    );
  }

  double averageAttackCommands(String playerId) {
    if (games.isEmpty) return 0;
    var total = 0;
    var count = 0;
    for (final game in games) {
      if (!game.playerIds.contains(playerId)) continue;
      total += game.attackCommandCount(playerId);
      count += 1;
    }
    return count == 0 ? 0 : total / count;
  }

  double averageCityCenterDistance(String playerId) {
    return _averageSpacingMetric(
      playerId,
      (spacing) => spacing.averageDistance,
    );
  }

  double averageMinimumCityCenterDistance(String playerId) {
    return _averageSpacingMetric(
      playerId,
      (spacing) => spacing.minimumDistance?.toDouble(),
    );
  }

  double averageFirstCityTurn(String playerId) {
    return _averageOpeningMetric(
      playerId,
      (opening) => opening.firstCityTurn?.toDouble(),
    );
  }

  double settlerLostBeforeFirstCityRate(String playerId) {
    return _openingRate(
      playerId,
      (opening) => opening.lostSettlerBeforeFirstCity,
    );
  }

  double firstCityLostRate(String playerId) {
    return _openingRate(playerId, (opening) => opening.lostFirstCity);
  }

  double lastMilitaryLostRate(String playerId) {
    return _openingRate(playerId, (opening) => opening.lostLastMilitary);
  }

  double finishedWithoutCityRate(String playerId) {
    return _openingRate(playerId, (opening) => opening.finishedWithoutCity);
  }

  double averageSecondCityTurn(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.secondCityTurn?.toDouble(),
    );
  }

  double secondCityCompletionRate(String playerId) {
    return _expansionRate(playerId, (expansion) => expansion.foundedSecondCity);
  }

  double averageThirdCityTurn(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.thirdCityTurn?.toDouble(),
    );
  }

  double thirdCityCompletionRate(String playerId) {
    return _expansionRate(playerId, (expansion) => expansion.foundedThirdCity);
  }

  double averageMaxCityCount(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.maxCityCount.toDouble(),
    );
  }

  double finishedBelowTwoCitiesRate(String playerId) {
    return _expansionRate(
      playerId,
      (expansion) => expansion.finishedBelowTwoCities,
    );
  }

  double secondCityLostAfterFoundingRate(String playerId) {
    return _expansionRate(
      playerId,
      (expansion) => expansion.lostSecondCityAfterFounding,
    );
  }

  double averageSecondCityLossTurn(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.firstDropBelowTwoAfterSecondCityTurn?.toDouble(),
    );
  }

  double averageCityCountDropCount(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.cityCountDropCount.toDouble(),
    );
  }

  double averageFirstPostCitySettlerTurn(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.firstPostCitySettlerTurn?.toDouble(),
    );
  }

  double averageOneCityNoSettlerTurns(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.oneCityNoSettlerTurns.toDouble(),
    );
  }

  double averageOneCityWithSettlerTurns(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.oneCityWithSettlerTurns.toDouble(),
    );
  }

  double averageOneCityAttackCommands(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.oneCityAttackCommands.toDouble(),
    );
  }

  double averageFirstPostSecondCitySettlerTurn(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.firstPostSecondCitySettlerTurn?.toDouble(),
    );
  }

  double averageTwoCityNoSettlerTurns(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.twoCityNoSettlerTurns.toDouble(),
    );
  }

  double averageTwoCityWithSettlerTurns(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.twoCityWithSettlerTurns.toDouble(),
    );
  }

  double averageTwoCityStartUnitCommands(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.twoCityStartUnitCommands.toDouble(),
    );
  }

  double averageTwoCityStartBuildingCommands(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.twoCityStartBuildingCommands.toDouble(),
    );
  }

  double averageTwoCityStartProjectCommands(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.twoCityStartProjectCommands.toDouble(),
    );
  }

  double averageTwoCityAttackCommands(String playerId) {
    return _averageExpansionMetric(
      playerId,
      (expansion) => expansion.twoCityAttackCommands.toDouble(),
    );
  }

  double _averagePlayerMetric(
    String playerId,
    double? Function(BalanceTelemetryPlayerReport player) metric,
  ) {
    var total = 0.0;
    var count = 0;
    for (final game in games) {
      final player = game.telemetry.players[playerId];
      if (player == null) continue;
      final value = metric(player);
      if (value == null) continue;
      total += value;
      count += 1;
    }
    return count == 0 ? 0 : total / count;
  }

  double _averageSpacingMetric(
    String playerId,
    double? Function(CitySpacingReport spacing) metric,
  ) {
    var total = 0.0;
    var count = 0;
    for (final game in games) {
      if (!game.playerIds.contains(playerId)) continue;
      final value = metric(game.citySpacing(playerId));
      if (value == null) continue;
      total += value;
      count += 1;
    }
    return count == 0 ? 0 : total / count;
  }

  double _averageOpeningMetric(
    String playerId,
    double? Function(OpeningSurvivalReport opening) metric,
  ) {
    var total = 0.0;
    var count = 0;
    for (final game in games) {
      if (!game.playerIds.contains(playerId)) continue;
      final value = metric(game.openingSurvival(playerId));
      if (value == null) continue;
      total += value;
      count += 1;
    }
    return count == 0 ? 0 : total / count;
  }

  double _openingRate(
    String playerId,
    bool Function(OpeningSurvivalReport opening) predicate,
  ) {
    var hits = 0;
    var count = 0;
    for (final game in games) {
      if (!game.playerIds.contains(playerId)) continue;
      count += 1;
      if (predicate(game.openingSurvival(playerId))) hits += 1;
    }
    return count == 0 ? 0 : hits / count;
  }

  double _averageExpansionMetric(
    String playerId,
    double? Function(ExpansionRecoveryReport expansion) metric,
  ) {
    var total = 0.0;
    var count = 0;
    for (final game in games) {
      if (!game.playerIds.contains(playerId)) continue;
      final value = metric(game.expansionRecovery(playerId));
      if (value == null) continue;
      total += value;
      count += 1;
    }
    return count == 0 ? 0 : total / count;
  }

  double _expansionRate(
    String playerId,
    bool Function(ExpansionRecoveryReport expansion) predicate,
  ) {
    var hits = 0;
    var count = 0;
    for (final game in games) {
      if (!game.playerIds.contains(playerId)) continue;
      count += 1;
      if (predicate(game.expansionRecovery(playerId))) hits += 1;
    }
    return count == 0 ? 0 : hits / count;
  }
}
