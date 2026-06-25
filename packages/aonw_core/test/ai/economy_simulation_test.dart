import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('EconomySimulation', () {
    test(
      'keeps unit count bounded and moves production into infrastructure',
      () {
        final result = EconomySimulation.run();
        final last = result.rows.last;

        expect(result.rows, hasLength(36));
        expect(result.rejectedCommands, isEmpty);
        expect(last.cityCount, greaterThanOrEqualTo(1));
        expect(last.unitCount, lessThanOrEqualTo(8));
        expect(last.unitSupplyUsed, lessThanOrEqualTo(last.unitSupplyCapacity));
        expect(last.unitSupplyAvailable, greaterThanOrEqualTo(1));
        expect(last.militaryCount, greaterThanOrEqualTo(2));
        final infrastructureRows = result.rows.where(
          (row) =>
              row.buildingQueues +
                  row.projectQueues +
                  row.startBuildingCommands +
                  row.startProjectCommands >
              0,
        );
        expect(
          infrastructureRows,
          isNotEmpty,
          reason: 'AI should spend some production on non-unit development',
        );
        expect(last.gold, greaterThan(0));
        expect(last.netGoldPerTurn, greaterThanOrEqualTo(0));
        expect(last.sciencePerTurn, greaterThanOrEqualTo(2));
        expect(last.rejectedCommands, 0);
        expect(
          result.appliedCommandRecords,
          hasLength(result.appliedCommands.length),
        );
        expect(
          result.appliedCommandRecords.map((record) => record.command),
          result.appliedCommands,
        );
      },
    );

    test('collects telemetry for pace preset simulations', () {
      const simulationTurns = 48;
      for (final gameLength in [
        GameLengthConfig.standard60,
        GameLengthConfig.normal90,
        GameLengthConfig.long120,
      ]) {
        final result = EconomySimulation.run(
          config: EconomySimulationConfig.forGameLength(
            gameLength: gameLength,
            turns: simulationTurns,
            opponents: const [_rival],
            mctsConfig: _testMctsConfig,
          ),
        );
        final player = result.telemetry.player('player_1');
        final targets = BalanceTelemetryTuningTargets.forPaceProfile(
          gameLength.paceProfile,
        );
        final last = result.rows.last;
        final isMilitaryVictoryWinner =
            result.telemetry.winnerPlayerId == 'player_1' &&
            (result.telemetry.victoryCondition ==
                    GameOutcomeCondition.conquest ||
                result.telemetry.victoryCondition ==
                    GameOutcomeCondition.domination);
        final hasCombat = result.appliedCommands
            .whereType<AttackHexCommand>()
            .isNotEmpty;

        expect(result.rows, hasLength(simulationTurns));
        expect(
          result.rowsByPlayerId.keys,
          containsAll(['player_1', 'player_2']),
        );
        expect(result.rowsByPlayerId['player_1'], result.rows);
        expect(result.rowsByPlayerId['player_2'], hasLength(simulationTurns));
        expect(
          result.rejectedCommands,
          isEmpty,
          reason: [
            'pace=${gameLength.paceProfile.name}',
            for (final record in result.rejectedCommandRecords)
              'turn=${record.turn} player=${record.playerId} '
                  'reason=${record.reason} '
                  'command=${_commandSummary(record.command)}',
          ].join('\n'),
        );
        expect(result.telemetry.lastTurn, simulationTurns);
        expect(
          result.telemetry.players.keys,
          containsAll(['player_1', 'player_2']),
        );
        expect(player.secondCityTurn, isNotNull);
        expect(player.firstContactTurn, isNotNull);
        if (hasCombat) {
          expect(player.firstCombatTurn, isNotNull);
        }
        expect(
          player.firstTechnologyTurn,
          lessThanOrEqualTo(targets.firstTechnologyMaxTurn),
        );
        expect(player.firstBuildingTurn, isNotNull);
        if (!isMilitaryVictoryWinner) {
          expect(player.secondCityTurn, lessThanOrEqualTo(simulationTurns));
        }
        expect(player.firstContactTurn, lessThanOrEqualTo(simulationTurns));
        if (hasCombat) {
          expect(player.firstCombatTurn, lessThanOrEqualTo(simulationTurns));
        }
        expect(player.finalTechnologyCount, last.completedTechCount);
        expect(player.finalSciencePerTurn, last.sciencePerTurn);
        expect(player.finalCityCount, last.cityCount);
        expect(player.finalUnitCount, last.unitCount);
        expect(player.finalGold, last.gold);
        expect(player.finalNetGoldPerTurn, last.netGoldPerTurn);
        expect(
          result.telemetry.victoryCondition,
          anyOf(
            isNull,
            isIn(const [
              GameOutcomeCondition.score,
              GameOutcomeCondition.conquest,
              GameOutcomeCondition.domination,
            ]),
          ),
        );
        if (result.telemetry.victoryTurn case final victoryTurn?) {
          expect(victoryTurn, lessThanOrEqualTo(simulationTurns));
        }
        if (result.telemetry.victoryCondition ==
                GameOutcomeCondition.domination &&
            result.telemetry.winnerPlayerId == 'player_1') {
          expect(player.firstDominationThresholdTurn, isNotNull);
          if (targets.dominationThresholdMaxTurn > 0) {
            expect(
              player.firstDominationThresholdTurn,
              lessThanOrEqualTo(targets.dominationThresholdMaxTurn),
            );
          }
        }
        expect(player.longestDeadTurnStreak, lessThanOrEqualTo(2));
        final findingCodes = result.telemetry.findings
            .where((finding) => finding.playerId == 'player_1')
            .map((finding) => finding.code);
        expect(
          findingCodes.where(
            (code) =>
                !code.startsWith('high_final_') &&
                !code.startsWith('low_final_') &&
                code != 'late_first_building' &&
                code != 'late_first_contact' &&
                code != 'late_first_combat' &&
                code != 'late_second_city',
          ),
          isEmpty,
        );
      }
    });

    test(
      'records objective action diagnostics in the score pressure window',
      () {
        final matchRules = MatchRules.forGameLength(
          GameLengthConfig.standard60,
        );
        final scoreCapRules = matchRules.copyWith(
          victory: matchRules.victory.copyWith(
            conquestEnabled: false,
            dominationEnabled: false,
            turnLimit: 12,
          ),
        );
        final result = EconomySimulation.run(
          config: EconomySimulationConfig(
            turns: scoreCapRules.victory.turnLimit!,
            opponents: const [_rival],
            matchRules: scoreCapRules,
            ruleset: GameRuleset.defaults.copyWith(
              paceBalance: scoreCapRules.paceBalance,
            ),
            telemetryTargets: BalanceTelemetryTuningTargets.forPaceProfile(
              scoreCapRules.gameLength.paceProfile,
            ),
            mctsConfig: _testMctsConfig,
          ),
        );

        final diagnosticRows = result.rows.where(
          (row) => row.objectiveActionAdvice.isNotEmpty,
        );
        final player = result.telemetry.player('player_1');

        expect(diagnosticRows, hasLength(6));
        expect(player.objectiveActionSampleCount, 6);
        expect(
          player.objectiveActionAdviceCounts.values.fold(
            0,
            (total, count) => total + count,
          ),
          6,
        );
        expect(
          player.objectiveActionTargetCounts.values.fold(
            0,
            (total, count) => total + count,
          ),
          6,
        );
      },
    );

    test(
      'runs MCTS players with a deterministic bounded simulation budget',
      () {
        const player = Player(
          id: 'player_1',
          name: 'AI MCTS',
          colorValue: 0xFFDC2626,
          kind: PlayerKind.ai,
          ai: AiPlayer(
            strategyId: AiStrategyId.mcts,
            difficulty: AiDifficulty.normal,
            seed: 3003,
          ),
        );
        const config = EconomySimulationConfig(turns: 6, player: player);

        final first = EconomySimulation.run(config: config);
        final second = EconomySimulation.run(config: config);

        expect(first.rows, hasLength(6));
        expect(first.rejectedCommands, isEmpty);
        expect(first.appliedCommands, isNotEmpty);
        expect(first.toCsv(), second.toCsv());
      },
    );

    test('records MCTS runtime samples for configured profile mode', () {
      const player = Player(
        id: 'player_1',
        name: 'AI MCTS',
        colorValue: 0xFFDC2626,
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.mcts,
          difficulty: AiDifficulty.easy,
          seed: 3003,
        ),
      );
      const config = EconomySimulationConfig(
        turns: 1,
        player: player,
        mctsProfileMode: EconomySimulationMctsProfileMode.batterySaver,
      );

      final result = EconomySimulation.run(config: config);
      final runtime = result.aiTurnRuntimes.single;

      expect(runtime.playerId, 'player_1');
      expect(runtime.strategyId, AiStrategyId.mcts);
      expect(
        runtime.profileMode,
        EconomySimulationMctsProfileMode.batterySaver,
      );
      expect(runtime.runtimeProfile, MctsRuntimeProfile.batterySaver);
      expect(runtime.adaptiveLateGame, isFalse);
      expect(runtime.planningDuration.inMicroseconds, greaterThanOrEqualTo(0));
      expect(runtime.plannedCommands, greaterThanOrEqualTo(0));
      expect(runtime.debugNotes, isNotEmpty);
      expect(runtime.debugMetrics['mcts.iterations'], 8);
      expect(runtime.debugMetrics['mcts.candidateCalls'], greaterThan(0));
      expect(runtime.debugMetrics['mcts.sourcePlanCalls'], greaterThan(0));
      expect(
        runtime.debugMetrics['mcts.sourcePlanElapsedMicros'],
        greaterThanOrEqualTo(0),
      );
      expect(
        runtime.debugMetrics['mcts.baselinePlanElapsedMicros'],
        greaterThanOrEqualTo(0),
      );
      expect(
        runtime.debugMetrics['mcts.mergeElapsedMicros'],
        greaterThanOrEqualTo(0),
      );
      expect(
        runtime.debugMetrics['mcts.strategyElapsedMicros'],
        greaterThanOrEqualTo(0),
      );
    });

    test('starts adaptive local single-player MCTS in interactive mode', () {
      const config = EconomySimulationConfig(
        turns: 1,
        player: Player(
          id: 'player_1',
          name: 'Simulated Human',
          colorValue: 0xFF3D5FA8,
          country: PlayerCountry.poland,
          kind: PlayerKind.human,
        ),
        opponents: [
          Player(
            id: 'player_2',
            name: 'Germany',
            colorValue: 0xFFB83A3A,
            country: PlayerCountry.germany,
            kind: PlayerKind.ai,
            ai: AiPlayer(
              strategyId: AiStrategyId.mcts,
              difficulty: AiDifficulty.easy,
              seed: 4002,
            ),
          ),
        ],
        mctsProfileMode:
            EconomySimulationMctsProfileMode.adaptiveLocalSinglePlayer,
      );

      final result = EconomySimulation.run(config: config);
      final runtime = result.aiTurnRuntimes.singleWhere(
        (runtime) => runtime.strategyId == AiStrategyId.mcts,
      );

      expect(
        runtime.profileMode,
        EconomySimulationMctsProfileMode.adaptiveLocalSinglePlayer,
      );
      expect(runtime.runtimeProfile, MctsRuntimeProfile.interactive);
      expect(runtime.adaptiveLateGame, isFalse);
    });

    test('tracks all players in a four-player MCTS smoke simulation', () {
      const playerIds = {'player_1', 'player_2', 'player_3', 'player_4'};
      const config = EconomySimulationConfig(
        turns: 4,
        player: Player(
          id: 'player_1',
          name: 'Simulated Human',
          colorValue: 0xFF3D5FA8,
          country: PlayerCountry.poland,
          kind: PlayerKind.human,
        ),
        opponents: [
          Player(
            id: 'player_2',
            name: 'Germany',
            colorValue: 0xFFB83A3A,
            country: PlayerCountry.germany,
            kind: PlayerKind.ai,
            ai: AiPlayer(
              strategyId: AiStrategyId.mcts,
              difficulty: AiDifficulty.easy,
              seed: 4002,
            ),
          ),
          Player(
            id: 'player_3',
            name: 'Netherlands',
            colorValue: 0xFF6D4A8C,
            country: PlayerCountry.netherlands,
            kind: PlayerKind.ai,
            ai: AiPlayer(
              strategyId: AiStrategyId.mcts,
              difficulty: AiDifficulty.easy,
              seed: 4003,
            ),
          ),
          Player(
            id: 'player_4',
            name: 'Japan',
            colorValue: 0xFFC8741F,
            country: PlayerCountry.japan,
            kind: PlayerKind.ai,
            ai: AiPlayer(
              strategyId: AiStrategyId.mcts,
              difficulty: AiDifficulty.easy,
              seed: 4004,
            ),
          ),
        ],
      );

      final result = EconomySimulation.run(config: config);

      expect(result.rows, result.rowsByPlayerId['player_1']);
      expect(result.rowsByPlayerId.keys.toSet(), playerIds);
      for (final playerId in playerIds) {
        expect(result.rowsByPlayerId[playerId], hasLength(4));
      }
      expect(result.telemetry.players.keys.toSet(), playerIds);
      expect(result.rejectedCommands, isEmpty);
      expect(result.appliedCommands, isNotEmpty);
    });
  });
}

const _rival = Player(
  id: 'player_2',
  name: 'AI Rival',
  colorValue: 0xFF2563EB,
  kind: PlayerKind.ai,
  ai: AiPlayer(strategyId: AiStrategyId.mcts, seed: 2002),
);

const _testMctsConfig = MctsConfig(
  iterationBudget: 24,
  minIterations: 24,
  maxPlanningDepth: 3,
  candidateLimit: 6,
);

String _commandSummary(GameCommand command) {
  return switch (command) {
    AttackHexCommand(
      :final attackerUnitId,
      :final defenderCol,
      :final defenderRow,
    ) =>
      'AttackHexCommand(attackerUnitId: $attackerUnitId, '
          'defenderCol: $defenderCol, defenderRow: $defenderRow)',
    _ => command.toString(),
  };
}
