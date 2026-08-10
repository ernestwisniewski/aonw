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
part 'balance_runner_player_metrics.dart';
part 'balance_runner_country_metrics.dart';
part 'balance_runner_country_expansion_metrics.dart';

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
