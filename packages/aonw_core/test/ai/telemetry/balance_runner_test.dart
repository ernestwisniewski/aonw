import 'package:aonw_core/ai/ai_difficulty.dart';
import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/ai/telemetry/balance_runner.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:test/test.dart';

void main() {
  group('BalanceRunner', () {
    test('calculates city center spacing from hex distances', () {
      final spacing = CitySpacingReport.fromCenters([
        const HexCoordinate(col: 0, row: 0),
        const HexCoordinate(col: 0, row: 2),
        const HexCoordinate(col: 3, row: 0),
      ]);

      expect(spacing.cityCount, 3);
      expect(spacing.pairCount, 3);
      expect(spacing.minimumDistance, 2);
      expect(spacing.averageDistance, closeTo(8 / 3, 0.01));
    });

    test('detects opening survival milestones', () {
      final stable = OpeningSurvivalReport.fromSamples([
        const OpeningSurvivalTurnSample(
          turn: 1,
          cityCount: 1,
          settlerCount: 0,
          militaryCount: 1,
          unitCount: 1,
        ),
        const OpeningSurvivalTurnSample(
          turn: 2,
          cityCount: 2,
          settlerCount: 0,
          militaryCount: 2,
          unitCount: 3,
        ),
      ]);

      expect(stable.firstCityTurn, 1);
      expect(stable.lostSettlerBeforeFirstCity, isFalse);
      expect(stable.lostFirstCity, isFalse);
      expect(stable.lostLastMilitary, isFalse);
      expect(stable.finishedWithoutCity, isFalse);

      final collapsed = OpeningSurvivalReport.fromSamples([
        const OpeningSurvivalTurnSample(
          turn: 1,
          cityCount: 0,
          settlerCount: 1,
          militaryCount: 1,
          unitCount: 2,
        ),
        const OpeningSurvivalTurnSample(
          turn: 2,
          cityCount: 0,
          settlerCount: 0,
          militaryCount: 1,
          unitCount: 1,
        ),
        const OpeningSurvivalTurnSample(
          turn: 3,
          cityCount: 1,
          settlerCount: 0,
          militaryCount: 1,
          unitCount: 1,
        ),
        const OpeningSurvivalTurnSample(
          turn: 4,
          cityCount: 0,
          settlerCount: 0,
          militaryCount: 0,
          unitCount: 0,
        ),
      ]);

      expect(collapsed.firstCityTurn, 3);
      expect(collapsed.settlerLostBeforeFirstCityTurn, 2);
      expect(collapsed.firstCityLostTurn, 4);
      expect(collapsed.lastMilitaryLostTurn, 4);
      expect(collapsed.eliminationTurn, 4);
      expect(collapsed.finishedWithoutCity, isTrue);
    });

    test('detects second-city recovery shape', () {
      final report = ExpansionRecoveryReport.fromSamples([
        const ExpansionRecoveryTurnSample(
          turn: 1,
          cityCount: 1,
          settlerCount: 0,
          militaryCount: 1,
          unitQueueCount: 1,
          foundCityCommands: 0,
          startUnitCommands: 1,
          startBuildingCommands: 0,
          startProjectCommands: 0,
          attackCommands: 0,
        ),
        const ExpansionRecoveryTurnSample(
          turn: 2,
          cityCount: 1,
          settlerCount: 1,
          militaryCount: 1,
          unitQueueCount: 0,
          foundCityCommands: 0,
          startUnitCommands: 0,
          startBuildingCommands: 0,
          startProjectCommands: 0,
          attackCommands: 2,
        ),
        const ExpansionRecoveryTurnSample(
          turn: 3,
          cityCount: 1,
          settlerCount: 1,
          militaryCount: 2,
          unitQueueCount: 0,
          foundCityCommands: 1,
          startUnitCommands: 0,
          startBuildingCommands: 0,
          startProjectCommands: 0,
          attackCommands: 0,
        ),
        const ExpansionRecoveryTurnSample(
          turn: 4,
          cityCount: 2,
          settlerCount: 0,
          militaryCount: 2,
          unitQueueCount: 0,
          foundCityCommands: 0,
          startUnitCommands: 0,
          startBuildingCommands: 1,
          startProjectCommands: 0,
          attackCommands: 0,
        ),
        const ExpansionRecoveryTurnSample(
          turn: 5,
          cityCount: 1,
          settlerCount: 0,
          militaryCount: 1,
          unitQueueCount: 1,
          foundCityCommands: 0,
          startUnitCommands: 1,
          startBuildingCommands: 0,
          startProjectCommands: 0,
          attackCommands: 0,
        ),
        const ExpansionRecoveryTurnSample(
          turn: 6,
          cityCount: 2,
          settlerCount: 1,
          militaryCount: 2,
          unitQueueCount: 1,
          foundCityCommands: 0,
          startUnitCommands: 1,
          startBuildingCommands: 2,
          startProjectCommands: 1,
          attackCommands: 3,
        ),
        const ExpansionRecoveryTurnSample(
          turn: 7,
          cityCount: 3,
          settlerCount: 0,
          militaryCount: 2,
          unitQueueCount: 0,
          foundCityCommands: 1,
          startUnitCommands: 0,
          startBuildingCommands: 0,
          startProjectCommands: 0,
          attackCommands: 0,
        ),
      ]);

      expect(report.firstCityTurn, 1);
      expect(report.secondCityTurn, 4);
      expect(report.thirdCityTurn, 7);
      expect(report.maxCityCount, 3);
      expect(report.firstPostCitySettlerTurn, 2);
      expect(report.firstPostCityFoundCommandTurn, 3);
      expect(report.firstPostSecondCitySettlerTurn, 6);
      expect(report.firstPostSecondCityFoundCommandTurn, 7);
      expect(report.firstDropBelowTwoAfterSecondCityTurn, 5);
      expect(report.oneCityNoSettlerTurns, 1);
      expect(report.oneCityWithSettlerTurns, 2);
      expect(report.oneCityUnitQueueTurns, 1);
      expect(report.oneCityStartUnitCommands, 1);
      expect(report.oneCityAttackCommands, 2);
      expect(report.twoCityNoSettlerTurns, 1);
      expect(report.twoCityWithSettlerTurns, 1);
      expect(report.twoCityUnitQueueTurns, 1);
      expect(report.twoCityStartUnitCommands, 1);
      expect(report.twoCityStartBuildingCommands, 3);
      expect(report.twoCityStartProjectCommands, 1);
      expect(report.twoCityAttackCommands, 3);
      expect(report.cityCountDropCount, 1);
      expect(report.foundedSecondCity, isTrue);
      expect(report.foundedThirdCity, isTrue);
      expect(report.finishedBelowTwoCities, isFalse);
      expect(report.lostSecondCityAfterFounding, isTrue);
    });

    test('separates threshold founding commands from next expansion phase', () {
      final report = ExpansionRecoveryReport.fromSamples([
        const ExpansionRecoveryTurnSample(
          turn: 1,
          cityCount: 1,
          settlerCount: 0,
          militaryCount: 1,
          unitQueueCount: 0,
          foundCityCommands: 1,
          startUnitCommands: 0,
          startBuildingCommands: 0,
          startProjectCommands: 0,
          attackCommands: 0,
        ),
        const ExpansionRecoveryTurnSample(
          turn: 2,
          cityCount: 2,
          settlerCount: 0,
          militaryCount: 1,
          unitQueueCount: 0,
          foundCityCommands: 1,
          startUnitCommands: 0,
          startBuildingCommands: 0,
          startProjectCommands: 0,
          attackCommands: 0,
        ),
        const ExpansionRecoveryTurnSample(
          turn: 3,
          cityCount: 2,
          settlerCount: 1,
          militaryCount: 1,
          unitQueueCount: 0,
          foundCityCommands: 0,
          startUnitCommands: 0,
          startBuildingCommands: 0,
          startProjectCommands: 0,
          attackCommands: 0,
        ),
        const ExpansionRecoveryTurnSample(
          turn: 4,
          cityCount: 3,
          settlerCount: 0,
          militaryCount: 1,
          unitQueueCount: 0,
          foundCityCommands: 1,
          startUnitCommands: 0,
          startBuildingCommands: 0,
          startProjectCommands: 0,
          attackCommands: 0,
        ),
      ]);

      expect(report.firstCityTurn, 1);
      expect(report.secondCityTurn, 2);
      expect(report.thirdCityTurn, 4);
      expect(report.firstPostCityFoundCommandTurn, 2);
      expect(report.firstPostSecondCityFoundCommandTurn, 4);
    });

    test('builds a four-player MCTS smoke config', () {
      final config = BalanceRunner.fourPlayerMctsSmokeConfig(turns: 7);

      expect(config.turns, 7);
      expect(config.player.id, 'player_1');
      expect(config.player.kind, PlayerKind.human);
      expect(config.opponents, hasLength(3));
      expect(config.opponents.map((player) => player.country).toList(), [
        PlayerCountry.germany,
        PlayerCountry.netherlands,
        PlayerCountry.japan,
      ]);
      expect(config.opponents.map((player) => player.ai?.difficulty).toSet(), {
        AiDifficulty.easy,
      });
    });

    test('builds a custom four-player MCTS config', () {
      final config = BalanceRunner.fourPlayerMctsConfig(
        turns: 6,
        aiDifficulty: AiDifficulty.hard,
        seed: 6000,
        gameLength: GameLengthConfig.standard60,
        mctsProfileMode:
            EconomySimulationMctsProfileMode.adaptiveLocalSinglePlayer,
        primaryCountry: PlayerCountry.canada,
        opponentCountries: const [
          PlayerCountry.spain,
          PlayerCountry.korea,
          PlayerCountry.sweden,
        ],
      );

      expect(config.turns, 6);
      expect(config.matchRules.gameLength, GameLengthConfig.standard60);
      expect(
        config.mctsProfileMode,
        EconomySimulationMctsProfileMode.adaptiveLocalSinglePlayer,
      );
      expect(config.player.country, PlayerCountry.canada);
      expect(config.player.name, 'Canada');
      expect(config.opponents.map((player) => player.country).toList(), [
        PlayerCountry.spain,
        PlayerCountry.korea,
        PlayerCountry.sweden,
      ]);
      expect(config.opponents.map((player) => player.name).toList(), [
        'Spain',
        'Korea',
        'Sweden',
      ]);
      expect(config.opponents.map((player) => player.ai?.difficulty).toSet(), {
        AiDifficulty.hard,
      });
      expect(config.opponents.map((player) => player.ai?.seed).toList(), [
        6002,
        6003,
        6004,
      ]);
    });

    test('runs a deterministic batch and aggregates per-player metrics', () {
      final configs = [
        BalanceRunner.fourPlayerMctsSmokeConfig(turns: 4, seed: 4100),
        BalanceRunner.fourPlayerMctsSmokeConfig(turns: 4, seed: 4200),
      ];

      final report = BalanceRunner.run(configs: configs);

      expect(report.attemptedGameCount, 2);
      expect(report.gameCount, 2);
      expect(report.crashCount, 0);
      expect(report.totalRejectedCommands, 0);
      expect(report.playerIds, {
        'player_1',
        'player_2',
        'player_3',
        'player_4',
      });
      expect(report.countries, {
        PlayerCountry.poland,
        PlayerCountry.germany,
        PlayerCountry.netherlands,
        PlayerCountry.japan,
      });
      expect(report.averageFinalCityCount('player_1'), greaterThanOrEqualTo(1));
      expect(report.averageFinalUnitCount('player_2'), greaterThan(0));
      expect(report.averageAttackCommands('player_2'), greaterThanOrEqualTo(0));
      expect(
        report.averageCityCenterDistance('player_1'),
        greaterThanOrEqualTo(0),
      );
      expect(report.averageFirstCityTurn('player_1'), greaterThanOrEqualTo(1));
      expect(
        report.settlerLostBeforeFirstCityRate('player_2'),
        greaterThanOrEqualTo(0),
      );
      expect(report.firstCityLostRate('player_2'), greaterThanOrEqualTo(0));
      expect(report.lastMilitaryLostRate('player_2'), greaterThanOrEqualTo(0));
      expect(
        report.finishedWithoutCityRate('player_2'),
        greaterThanOrEqualTo(0),
      );
      expect(report.averageSecondCityTurn('player_1'), greaterThanOrEqualTo(0));
      expect(
        report.secondCityCompletionRate('player_1'),
        greaterThanOrEqualTo(0),
      );
      expect(report.averageThirdCityTurn('player_1'), greaterThanOrEqualTo(0));
      expect(
        report.thirdCityCompletionRate('player_1'),
        greaterThanOrEqualTo(0),
      );
      expect(report.averageMaxCityCount('player_1'), greaterThanOrEqualTo(0));
      expect(
        report.finishedBelowTwoCitiesRate('player_1'),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.secondCityLostAfterFoundingRate('player_1'),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageCityCountDropCount('player_1'),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageOneCityNoSettlerTurns('player_1'),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageOneCityAttackCommands('player_1'),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageTwoCityNoSettlerTurns('player_1'),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageTwoCityStartBuildingCommands('player_1'),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageTwoCityStartProjectCommands('player_1'),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageFinalCityCountForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(1),
      );
      expect(
        report.averageFinalUnitCountForCountry(PlayerCountry.germany),
        greaterThan(0),
      );
      expect(
        report.averageFinalTechnologyCountForCountry(PlayerCountry.germany),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageFinalGoldForCountry(PlayerCountry.germany),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageAttackCommandsForCountry(PlayerCountry.germany),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageCityCenterDistanceForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageFirstCityTurnForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(1),
      );
      expect(
        report.settlerLostBeforeFirstCityRateForCountry(PlayerCountry.germany),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.firstCityLostRateForCountry(PlayerCountry.germany),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.lastMilitaryLostRateForCountry(PlayerCountry.germany),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.finishedWithoutCityRateForCountry(PlayerCountry.germany),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageSecondCityTurnForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.secondCityCompletionRateForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageThirdCityTurnForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.thirdCityCompletionRateForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageMaxCityCountForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.finishedBelowTwoCitiesRateForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.secondCityLostAfterFoundingRateForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageCityCountDropCountForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageOneCityNoSettlerTurnsForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageTwoCityNoSettlerTurnsForCountry(PlayerCountry.poland),
        greaterThanOrEqualTo(0),
      );
      expect(
        report.averageTwoCityStartProjectCommandsForCountry(
          PlayerCountry.poland,
        ),
        greaterThanOrEqualTo(0),
      );
      expect(report.winRate('unknown'), 0);
      expect(report.winRateForCountry(PlayerCountry.spain), 0);

      final repeated = BalanceRunner.run(configs: configs);
      expect(report.toMarkdownSummary(), repeated.toMarkdownSummary());
      expect(report.toMarkdownSummary(), contains('| City dist |'));
      expect(report.toMarkdownSummary(), contains('| Attacks |'));
      expect(report.toMarkdownSummary(), contains('| player_1 | poland |'));
      expect(report.toMarkdownSummary(), contains('- Crashes: 0'));
    });
  });
}
