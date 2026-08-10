part of 'balance_pass.dart';

Map<String, Object?> _summaryJson({
  required _BalancePassOptions options,
  required BalanceBatchReport report,
}) {
  return {
    'generatedBy': 'dart run tool/balance_pass.dart',
    'parameters': {
      'games': options.games,
      'targetMinutes': options.gameLength.targetMinutes,
      'estimatedTurnSeconds': GameLengthConfig.estimatedMultiplayerTurnSeconds,
      'rawTurnOverride': options.rawTurnOverride,
      'turns': options.turns,
      'difficulty': options.difficulty.name,
      'mctsProfile': options.mctsProfileMode.name,
      'seed': options.seed,
      'primaryCiv': options.primaryCiv.name,
      'civs': [for (final civ in options.civs) civ.name],
    },
    'attemptedGameCount': report.attemptedGameCount,
    'completedGameCount': report.gameCount,
    'crashCount': report.crashCount,
    'totalRejectedCommands': report.totalRejectedCommands,
    'mctsRuntime': _runtimeSummaryJson(report),
    'players': [
      for (final playerId in _orderedPlayerIds(report))
        _playerJson(report, playerId),
    ],
    'countries': [
      for (final country in _orderedCountries(report))
        _countryJson(report, country),
    ],
    'games': [
      for (final game in report.games)
        {
          'index': game.index,
          'winnerPlayerId': game.winnerPlayerId,
          'victoryTurn': game.victoryTurn,
          'victoryCondition': game.victoryCondition?.name,
          'rejectedCommandCount': game.rejectedCommandCount,
          'rejectedCommands': [
            for (final rejected in game.result.rejectedCommandRecords)
              {
                'turn': rejected.turn,
                'tick': rejected.tick,
                'playerId': rejected.playerId,
                'reason': rejected.reason,
                'command': DomainCommandCodec.toJson(rejected.command),
              },
          ],
          'aiTurnRuntime': [
            for (final runtime in game.result.aiTurnRuntimes)
              {
                'turn': runtime.turn,
                'playerId': runtime.playerId,
                'strategyId': runtime.strategyId.name,
                'mctsProfileMode': runtime.profileMode.name,
                'mctsRuntimeProfile': runtime.runtimeProfile?.name,
                'adaptiveLateGame': runtime.adaptiveLateGame,
                'planningMicros': runtime.planningDuration.inMicroseconds,
                'planningMs': runtime.planningDuration.inMicroseconds / 1000.0,
                'plannedCommands': runtime.plannedCommands,
                'totalUnits': runtime.totalUnitCount,
                'totalCities': runtime.totalCityCount,
                'debugNotes': runtime.debugNotes,
                'debugMetrics': runtime.debugMetrics,
              },
          ],
        },
    ],
    'failures': [
      for (final failure in report.failures)
        {
          'index': failure.index,
          'error': failure.error.toString(),
          'stackTrace': failure.stackTrace.toString(),
        },
    ],
  };
}

Map<String, Object?> _playerJson(BalanceBatchReport report, String playerId) {
  return {
    'playerId': playerId,
    'country': _countryForPlayer(report, playerId)?.name,
    'winRate': report.winRate(playerId),
    'averageFinalCityCount': report.averageFinalCityCount(playerId),
    'averageCityCenterDistance': report.averageCityCenterDistance(playerId),
    'averageMinimumCityCenterDistance': report.averageMinimumCityCenterDistance(
      playerId,
    ),
    'averageFinalUnitCount': report.averageFinalUnitCount(playerId),
    'averageAttackCommands': report.averageAttackCommands(playerId),
    'averageFinalTechnologyCount': report.averageFinalTechnologyCount(playerId),
    'averageFinalSciencePerTurn': report.averageFinalSciencePerTurn(playerId),
    'averageFinalGold': report.averageFinalGold(playerId),
    'averageFinalNetGoldPerTurn': report.averageFinalNetGoldPerTurn(playerId),
    'openingSurvival': {
      'averageFirstCityTurn': report.averageFirstCityTurn(playerId),
      'settlerLostBeforeFirstCityRate': report.settlerLostBeforeFirstCityRate(
        playerId,
      ),
      'firstCityLostRate': report.firstCityLostRate(playerId),
      'lastMilitaryLostRate': report.lastMilitaryLostRate(playerId),
      'finishedWithoutCityRate': report.finishedWithoutCityRate(playerId),
    },
    'expansionRecovery': {
      'averageSecondCityTurn': report.averageSecondCityTurn(playerId),
      'secondCityCompletionRate': report.secondCityCompletionRate(playerId),
      'averageThirdCityTurn': report.averageThirdCityTurn(playerId),
      'thirdCityCompletionRate': report.thirdCityCompletionRate(playerId),
      'averageMaxCityCount': report.averageMaxCityCount(playerId),
      'finishedBelowTwoCitiesRate': report.finishedBelowTwoCitiesRate(playerId),
      'secondCityLostAfterFoundingRate': report.secondCityLostAfterFoundingRate(
        playerId,
      ),
      'averageSecondCityLossTurn': report.averageSecondCityLossTurn(playerId),
      'averageCityCountDropCount': report.averageCityCountDropCount(playerId),
      'averageFirstPostCitySettlerTurn': report.averageFirstPostCitySettlerTurn(
        playerId,
      ),
      'averageOneCityNoSettlerTurns': report.averageOneCityNoSettlerTurns(
        playerId,
      ),
      'averageOneCityWithSettlerTurns': report.averageOneCityWithSettlerTurns(
        playerId,
      ),
      'averageOneCityAttackCommands': report.averageOneCityAttackCommands(
        playerId,
      ),
      'averageFirstPostSecondCitySettlerTurn': report
          .averageFirstPostSecondCitySettlerTurn(playerId),
      'averageTwoCityNoSettlerTurns': report.averageTwoCityNoSettlerTurns(
        playerId,
      ),
      'averageTwoCityWithSettlerTurns': report.averageTwoCityWithSettlerTurns(
        playerId,
      ),
      'averageTwoCityStartUnitCommands': report.averageTwoCityStartUnitCommands(
        playerId,
      ),
      'averageTwoCityStartBuildingCommands': report
          .averageTwoCityStartBuildingCommands(playerId),
      'averageTwoCityStartProjectCommands': report
          .averageTwoCityStartProjectCommands(playerId),
      'averageTwoCityAttackCommands': report.averageTwoCityAttackCommands(
        playerId,
      ),
    },
  };
}

Map<String, Object?> _countryJson(
  BalanceBatchReport report,
  PlayerCountry country,
) {
  return {
    'country': country.name,
    'label': _label(country),
    'winRate': report.winRateForCountry(country),
    'averageFinalCityCount': report.averageFinalCityCountForCountry(country),
    'averageCityCenterDistance': report.averageCityCenterDistanceForCountry(
      country,
    ),
    'averageMinimumCityCenterDistance': report
        .averageMinimumCityCenterDistanceForCountry(country),
    'averageFinalUnitCount': report.averageFinalUnitCountForCountry(country),
    'averageAttackCommands': report.averageAttackCommandsForCountry(country),
    'averageFinalTechnologyCount': report.averageFinalTechnologyCountForCountry(
      country,
    ),
    'averageFinalSciencePerTurn': report.averageFinalSciencePerTurnForCountry(
      country,
    ),
    'averageFinalGold': report.averageFinalGoldForCountry(country),
    'averageFinalNetGoldPerTurn': report.averageFinalNetGoldPerTurnForCountry(
      country,
    ),
    'openingSurvival': {
      'averageFirstCityTurn': report.averageFirstCityTurnForCountry(country),
      'settlerLostBeforeFirstCityRate': report
          .settlerLostBeforeFirstCityRateForCountry(country),
      'firstCityLostRate': report.firstCityLostRateForCountry(country),
      'lastMilitaryLostRate': report.lastMilitaryLostRateForCountry(country),
      'finishedWithoutCityRate': report.finishedWithoutCityRateForCountry(
        country,
      ),
    },
    'expansionRecovery': {
      'averageSecondCityTurn': report.averageSecondCityTurnForCountry(country),
      'secondCityCompletionRate': report.secondCityCompletionRateForCountry(
        country,
      ),
      'averageThirdCityTurn': report.averageThirdCityTurnForCountry(country),
      'thirdCityCompletionRate': report.thirdCityCompletionRateForCountry(
        country,
      ),
      'averageMaxCityCount': report.averageMaxCityCountForCountry(country),
      'finishedBelowTwoCitiesRate': report.finishedBelowTwoCitiesRateForCountry(
        country,
      ),
      'secondCityLostAfterFoundingRate': report
          .secondCityLostAfterFoundingRateForCountry(country),
      'averageSecondCityLossTurn': report.averageSecondCityLossTurnForCountry(
        country,
      ),
      'averageCityCountDropCount': report.averageCityCountDropCountForCountry(
        country,
      ),
      'averageFirstPostCitySettlerTurn': report
          .averageFirstPostCitySettlerTurnForCountry(country),
      'averageOneCityNoSettlerTurns': report
          .averageOneCityNoSettlerTurnsForCountry(country),
      'averageOneCityWithSettlerTurns': report
          .averageOneCityWithSettlerTurnsForCountry(country),
      'averageOneCityAttackCommands': report
          .averageOneCityAttackCommandsForCountry(country),
      'averageFirstPostSecondCitySettlerTurn': report
          .averageFirstPostSecondCitySettlerTurnForCountry(country),
      'averageTwoCityNoSettlerTurns': report
          .averageTwoCityNoSettlerTurnsForCountry(country),
      'averageTwoCityWithSettlerTurns': report
          .averageTwoCityWithSettlerTurnsForCountry(country),
      'averageTwoCityStartUnitCommands': report
          .averageTwoCityStartUnitCommandsForCountry(country),
      'averageTwoCityStartBuildingCommands': report
          .averageTwoCityStartBuildingCommandsForCountry(country),
      'averageTwoCityStartProjectCommands': report
          .averageTwoCityStartProjectCommandsForCountry(country),
      'averageTwoCityAttackCommands': report
          .averageTwoCityAttackCommandsForCountry(country),
    },
  };
}
