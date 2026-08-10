part of 'balance_runner.dart';

extension BalanceBatchCountryMetrics on BalanceBatchReport {
  double winRateForCountry(PlayerCountry country) {
    var wins = 0;
    var appearances = 0;
    for (final game in games) {
      for (final entry in game.countryByPlayerId.entries) {
        if (entry.value != country) continue;
        appearances += 1;
        if (game.winnerPlayerId == entry.key) {
          wins += 1;
        }
      }
    }
    return appearances == 0 ? 0 : wins / appearances;
  }

  double averageFinalCityCountForCountry(PlayerCountry country) {
    return _averageCountryMetric(
      country,
      (player) => player.finalCityCount.toDouble(),
    );
  }

  double averageFinalUnitCountForCountry(PlayerCountry country) {
    return _averageCountryMetric(
      country,
      (player) => player.finalUnitCount.toDouble(),
    );
  }

  double averageFinalSciencePerTurnForCountry(PlayerCountry country) {
    return _averageCountryMetric(
      country,
      (player) => player.finalSciencePerTurn?.toDouble(),
    );
  }

  double averageFinalTechnologyCountForCountry(PlayerCountry country) {
    return _averageCountryMetric(
      country,
      (player) => player.finalTechnologyCount.toDouble(),
    );
  }

  double averageFinalGoldForCountry(PlayerCountry country) {
    return _averageCountryMetric(
      country,
      (player) => player.finalGold?.toDouble(),
    );
  }

  double averageFinalNetGoldPerTurnForCountry(PlayerCountry country) {
    return _averageCountryMetric(
      country,
      (player) => player.finalNetGoldPerTurn?.toDouble(),
    );
  }

  double averageAttackCommandsForCountry(PlayerCountry country) {
    var total = 0;
    var count = 0;
    for (final game in games) {
      for (final entry in game.countryByPlayerId.entries) {
        if (entry.value != country) continue;
        total += game.attackCommandCount(entry.key);
        count += 1;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  double averageCityCenterDistanceForCountry(PlayerCountry country) {
    return _averageCountrySpacingMetric(
      country,
      (spacing) => spacing.averageDistance,
    );
  }

  double averageMinimumCityCenterDistanceForCountry(PlayerCountry country) {
    return _averageCountrySpacingMetric(
      country,
      (spacing) => spacing.minimumDistance?.toDouble(),
    );
  }

  double averageFirstCityTurnForCountry(PlayerCountry country) {
    return _averageCountryOpeningMetric(
      country,
      (opening) => opening.firstCityTurn?.toDouble(),
    );
  }

  double settlerLostBeforeFirstCityRateForCountry(PlayerCountry country) {
    return _countryOpeningRate(
      country,
      (opening) => opening.lostSettlerBeforeFirstCity,
    );
  }

  double firstCityLostRateForCountry(PlayerCountry country) {
    return _countryOpeningRate(country, (opening) => opening.lostFirstCity);
  }

  double lastMilitaryLostRateForCountry(PlayerCountry country) {
    return _countryOpeningRate(country, (opening) => opening.lostLastMilitary);
  }

  double finishedWithoutCityRateForCountry(PlayerCountry country) {
    return _countryOpeningRate(
      country,
      (opening) => opening.finishedWithoutCity,
    );
  }

  double _averageCountryMetric(
    PlayerCountry country,
    double? Function(BalanceTelemetryPlayerReport player) metric,
  ) {
    var total = 0.0;
    var count = 0;
    for (final game in games) {
      for (final entry in game.countryByPlayerId.entries) {
        if (entry.value != country) continue;
        final player = game.telemetry.players[entry.key];
        if (player == null) continue;
        final value = metric(player);
        if (value == null) continue;
        total += value;
        count += 1;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  double _averageCountryOpeningMetric(
    PlayerCountry country,
    double? Function(OpeningSurvivalReport opening) metric,
  ) {
    var total = 0.0;
    var count = 0;
    for (final game in games) {
      for (final entry in game.countryByPlayerId.entries) {
        if (entry.value != country) continue;
        final value = metric(game.openingSurvival(entry.key));
        if (value == null) continue;
        total += value;
        count += 1;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  double _countryOpeningRate(
    PlayerCountry country,
    bool Function(OpeningSurvivalReport opening) predicate,
  ) {
    var hits = 0;
    var count = 0;
    for (final game in games) {
      for (final entry in game.countryByPlayerId.entries) {
        if (entry.value != country) continue;
        count += 1;
        if (predicate(game.openingSurvival(entry.key))) hits += 1;
      }
    }
    return count == 0 ? 0 : hits / count;
  }

  double _averageCountrySpacingMetric(
    PlayerCountry country,
    double? Function(CitySpacingReport spacing) metric,
  ) {
    var total = 0.0;
    var count = 0;
    for (final game in games) {
      for (final entry in game.countryByPlayerId.entries) {
        if (entry.value != country) continue;
        final value = metric(game.citySpacing(entry.key));
        if (value == null) continue;
        total += value;
        count += 1;
      }
    }
    return count == 0 ? 0 : total / count;
  }
}
