part of 'balance_runner.dart';

extension BalanceBatchCountryExpansionMetrics on BalanceBatchReport {
  double averageSecondCityTurnForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.secondCityTurn?.toDouble(),
    );
  }

  double secondCityCompletionRateForCountry(PlayerCountry country) {
    return _countryExpansionRate(
      country,
      (expansion) => expansion.foundedSecondCity,
    );
  }

  double averageThirdCityTurnForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.thirdCityTurn?.toDouble(),
    );
  }

  double thirdCityCompletionRateForCountry(PlayerCountry country) {
    return _countryExpansionRate(
      country,
      (expansion) => expansion.foundedThirdCity,
    );
  }

  double averageMaxCityCountForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.maxCityCount.toDouble(),
    );
  }

  double finishedBelowTwoCitiesRateForCountry(PlayerCountry country) {
    return _countryExpansionRate(
      country,
      (expansion) => expansion.finishedBelowTwoCities,
    );
  }

  double secondCityLostAfterFoundingRateForCountry(PlayerCountry country) {
    return _countryExpansionRate(
      country,
      (expansion) => expansion.lostSecondCityAfterFounding,
    );
  }

  double averageSecondCityLossTurnForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.firstDropBelowTwoAfterSecondCityTurn?.toDouble(),
    );
  }

  double averageCityCountDropCountForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.cityCountDropCount.toDouble(),
    );
  }

  double averageFirstPostCitySettlerTurnForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.firstPostCitySettlerTurn?.toDouble(),
    );
  }

  double averageOneCityNoSettlerTurnsForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.oneCityNoSettlerTurns.toDouble(),
    );
  }

  double averageOneCityWithSettlerTurnsForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.oneCityWithSettlerTurns.toDouble(),
    );
  }

  double averageOneCityAttackCommandsForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.oneCityAttackCommands.toDouble(),
    );
  }

  double averageFirstPostSecondCitySettlerTurnForCountry(
    PlayerCountry country,
  ) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.firstPostSecondCitySettlerTurn?.toDouble(),
    );
  }

  double averageTwoCityNoSettlerTurnsForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.twoCityNoSettlerTurns.toDouble(),
    );
  }

  double averageTwoCityWithSettlerTurnsForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.twoCityWithSettlerTurns.toDouble(),
    );
  }

  double averageTwoCityStartUnitCommandsForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.twoCityStartUnitCommands.toDouble(),
    );
  }

  double averageTwoCityStartBuildingCommandsForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.twoCityStartBuildingCommands.toDouble(),
    );
  }

  double averageTwoCityStartProjectCommandsForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.twoCityStartProjectCommands.toDouble(),
    );
  }

  double averageTwoCityAttackCommandsForCountry(PlayerCountry country) {
    return _averageCountryExpansionMetric(
      country,
      (expansion) => expansion.twoCityAttackCommands.toDouble(),
    );
  }

  double _averageCountryExpansionMetric(
    PlayerCountry country,
    double? Function(ExpansionRecoveryReport expansion) metric,
  ) {
    var total = 0.0;
    var count = 0;
    for (final game in games) {
      for (final entry in game.countryByPlayerId.entries) {
        if (entry.value != country) continue;
        final value = metric(game.expansionRecovery(entry.key));
        if (value == null) continue;
        total += value;
        count += 1;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  double _countryExpansionRate(
    PlayerCountry country,
    bool Function(ExpansionRecoveryReport expansion) predicate,
  ) {
    var hits = 0;
    var count = 0;
    for (final game in games) {
      for (final entry in game.countryByPlayerId.entries) {
        if (entry.value != country) continue;
        count += 1;
        if (predicate(game.expansionRecovery(entry.key))) hits += 1;
      }
    }
    return count == 0 ? 0 : hits / count;
  }
}
