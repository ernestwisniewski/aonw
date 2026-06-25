import 'package:aonw_core/ai/ai_difficulty.dart';
import 'package:aonw_core/ai/ai_player.dart';
import 'package:aonw_core/ai/ai_strategy_id.dart';
import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/telemetry.dart';

part 'balance_runner_recovery_reports.dart';

class BalanceGameReport {
  const BalanceGameReport({
    required this.index,
    required this.config,
    required this.result,
  });

  final int index;
  final EconomySimulationConfig config;
  final EconomySimulationResult result;

  BalanceTelemetryReport get telemetry => result.telemetry;

  int? get victoryTurn => telemetry.victoryTurn;
  GameOutcomeCondition? get victoryCondition => telemetry.victoryCondition;
  String? get winnerPlayerId => telemetry.winnerPlayerId;
  bool get finished => victoryCondition != null;
  int get rejectedCommandCount => result.rejectedCommands.length;
  Iterable<String> get playerIds => telemetry.players.keys;
  List<Player> get players => [config.player, ...config.opponents];

  Map<String, PlayerCountry> get countryByPlayerId {
    return {for (final player in players) player.id: player.country};
  }

  PlayerCountry? countryForPlayer(String playerId) {
    return countryByPlayerId[playerId];
  }

  BalanceTelemetryPlayerReport player(String playerId) {
    return telemetry.player(playerId);
  }

  CitySpacingReport citySpacing(String playerId) {
    return CitySpacingReport.fromCenters(
      result.state.cities
          .where((city) => city.ownerPlayerId == playerId)
          .map((city) => city.center.toCoordinate()),
    );
  }

  int attackCommandCount(String playerId) {
    return result.rowsByPlayerId[playerId]?.fold<int>(
          0,
          (total, row) => total + row.attackCommands,
        ) ??
        0;
  }

  OpeningSurvivalReport openingSurvival(String playerId) {
    return OpeningSurvivalReport.fromSamples(
      result.rowsByPlayerId[playerId]?.map(OpeningSurvivalTurnSample.fromRow) ??
          const [],
    );
  }

  ExpansionRecoveryReport expansionRecovery(String playerId) {
    return ExpansionRecoveryReport.fromSamples(
      result.rowsByPlayerId[playerId]?.map(
            ExpansionRecoveryTurnSample.fromRow,
          ) ??
          const [],
    );
  }
}

class BalanceGameFailure {
  const BalanceGameFailure({
    required this.index,
    required this.error,
    required this.stackTrace,
  });

  final int index;
  final Object error;
  final StackTrace stackTrace;
}

class BalanceBatchReport {
  const BalanceBatchReport({required this.games, required this.failures});

  final List<BalanceGameReport> games;
  final List<BalanceGameFailure> failures;

  int get gameCount => games.length;
  int get attemptedGameCount => games.length + failures.length;
  int get crashCount => failures.length;
  int get totalRejectedCommands =>
      games.fold(0, (total, game) => total + game.rejectedCommandCount);

  Set<String> get playerIds {
    return {
      for (final game in games)
        for (final playerId in game.playerIds) playerId,
    };
  }

  Set<PlayerCountry> get countries {
    return {
      for (final game in games)
        for (final country in game.countryByPlayerId.values) country,
    };
  }

  double winRate(String playerId) {
    if (games.isEmpty) return 0;
    final wins = games.where((game) => game.winnerPlayerId == playerId).length;
    return wins / games.length;
  }

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

  String toMarkdownSummary() {
    final buffer = StringBuffer()
      ..writeln(
        '| Player | Country | Win rate | Cities | City dist | Min dist | Units | Attacks | Techs | Science | Gold | Net gold |',
      )
      ..writeln(
        '| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |',
      );
    final orderedPlayerIds = playerIds.toList()..sort();
    for (final playerId in orderedPlayerIds) {
      final country = _countryNameForPlayer(playerId);
      buffer.writeln(
        '| $playerId | $country | ${_percent(winRate(playerId))} | '
        '${averageFinalCityCount(playerId).toStringAsFixed(1)} | '
        '${_distance(averageCityCenterDistance(playerId))} | '
        '${_distance(averageMinimumCityCenterDistance(playerId))} | '
        '${averageFinalUnitCount(playerId).toStringAsFixed(1)} | '
        '${averageAttackCommands(playerId).toStringAsFixed(1)} | '
        '${averageFinalTechnologyCount(playerId).toStringAsFixed(1)} | '
        '${averageFinalSciencePerTurn(playerId).toStringAsFixed(1)} | '
        '${averageFinalGold(playerId).toStringAsFixed(1)} | '
        '${averageFinalNetGoldPerTurn(playerId).toStringAsFixed(1)} |',
      );
    }
    buffer
      ..writeln()
      ..writeln('- Attempted games: $attemptedGameCount')
      ..writeln('- Completed games: $gameCount')
      ..writeln('- Crashes: $crashCount')
      ..writeln('- Rejected commands: $totalRejectedCommands');
    return buffer.toString();
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

  String _countryNameForPlayer(String playerId) {
    for (final game in games) {
      final country = game.countryForPlayer(playerId);
      if (country != null) return country.name;
    }
    return '-';
  }

  String _distance(double value) => value == 0 ? '-' : value.toStringAsFixed(1);

  String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';
}

abstract final class BalanceRunner {
  static BalanceBatchReport run({
    required Iterable<EconomySimulationConfig> configs,
  }) {
    final games = <BalanceGameReport>[];
    final failures = <BalanceGameFailure>[];
    var index = 0;
    for (final config in configs) {
      try {
        games.add(
          BalanceGameReport(
            index: index,
            config: config,
            result: EconomySimulation.run(config: config),
          ),
        );
      } catch (error, stackTrace) {
        failures.add(
          BalanceGameFailure(
            index: index,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      }
      index += 1;
    }
    return BalanceBatchReport(
      games: List.unmodifiable(games),
      failures: List.unmodifiable(failures),
    );
  }

  static EconomySimulationConfig fourPlayerMctsSmokeConfig({
    int turns = 12,
    AiDifficulty aiDifficulty = AiDifficulty.easy,
    int seed = 4000,
    GameLengthConfig gameLength = GameLengthConfig.unlimited,
    EconomySimulationMctsProfileMode mctsProfileMode =
        EconomySimulationMctsProfileMode.simulation,
  }) {
    return fourPlayerMctsConfig(
      turns: turns,
      aiDifficulty: aiDifficulty,
      seed: seed,
      gameLength: gameLength,
      mctsProfileMode: mctsProfileMode,
      primaryCountry: PlayerCountry.poland,
      opponentCountries: const [
        PlayerCountry.germany,
        PlayerCountry.netherlands,
        PlayerCountry.japan,
      ],
    );
  }

  static EconomySimulationConfig fourPlayerMctsConfig({
    required List<PlayerCountry> opponentCountries,
    int turns = 12,
    AiDifficulty aiDifficulty = AiDifficulty.easy,
    int seed = 4000,
    PlayerCountry primaryCountry = PlayerCountry.poland,
    GameLengthConfig gameLength = GameLengthConfig.unlimited,
    EconomySimulationMctsProfileMode mctsProfileMode =
        EconomySimulationMctsProfileMode.simulation,
  }) {
    if (opponentCountries.length != 3) {
      throw ArgumentError.value(
        opponentCountries,
        'opponentCountries',
        'Expected exactly three AI civilizations.',
      );
    }
    return EconomySimulationConfig.forGameLength(
      gameLength: gameLength,
      turns: turns,
      player: Player(
        id: 'player_1',
        name: _countryLabel(primaryCountry),
        colorValue: 0xFF3D5FA8,
        country: primaryCountry,
        kind: PlayerKind.human,
      ),
      opponents: [
        for (var index = 0; index < opponentCountries.length; index++)
          _mctsPlayer(
            id: 'player_${index + 2}',
            name: _countryLabel(opponentCountries[index]),
            colorValue: Player.palette[(index + 1) % Player.palette.length],
            country: opponentCountries[index],
            difficulty: aiDifficulty,
            seed: seed + index + 2,
          ),
      ],
      mctsProfileMode: mctsProfileMode,
    );
  }

  static Player _mctsPlayer({
    required String id,
    required String name,
    required int colorValue,
    required PlayerCountry country,
    required AiDifficulty difficulty,
    required int seed,
  }) {
    return Player(
      id: id,
      name: name,
      colorValue: colorValue,
      country: country,
      kind: PlayerKind.ai,
      ai: AiPlayer(
        strategyId: AiStrategyId.mcts,
        difficulty: difficulty,
        seed: seed,
      ),
    );
  }

  static String _countryLabel(PlayerCountry country) {
    final spaced = country.name.replaceAllMapped(
      RegExp(r'(?<=[a-z])([A-Z])'),
      (match) => ' ${match.group(1)}',
    );
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }
}
