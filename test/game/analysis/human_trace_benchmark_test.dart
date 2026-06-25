import 'package:aonw/game/analysis/human_trace_benchmark.dart';
import 'package:aonw_core/ai/ai_player.dart';
import 'package:aonw_core/ai/ai_strategy_id.dart';
import 'package:aonw_core/ai/simulation/economy_simulation.dart';
import 'package:aonw_core/ai/telemetry/balance_runner.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HumanTraceSimulationBenchmark', () {
    test('evaluates a simulation against extracted human trace targets', () {
      final benchmark = HumanTraceBenchmark.fromTraceJson({
        'source': 'test-trace.json',
        'humanPlayerId': 'player_1',
        'lastCompletedTurn': 12,
        'humanFoundCities': [
          {'turn': 1},
          {'turn': 8},
          {'turn': 12},
        ],
        'humanAttacks': [
          {'turn': 10},
        ],
        'repeatedAiCommands': [
          {'commandType': 'MoveUnit', 'count': 20},
        ],
        'aiWorkerStalls': [
          {'selectionCount': 6},
        ],
      });
      final simulation = BalanceRunner.run(
        configs: const [
          EconomySimulationConfig(
            turns: 4,
            player: Player(
              id: 'player_1',
              name: 'Poland',
              colorValue: 0xFF3D5FA8,
              country: PlayerCountry.poland,
              kind: PlayerKind.ai,
              ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 1001),
            ),
            opponents: [
              Player(
                id: 'player_2',
                name: 'Germany',
                colorValue: 0xFFB83A3A,
                country: PlayerCountry.germany,
                kind: PlayerKind.ai,
                ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 1002),
              ),
            ],
          ),
        ],
      );

      final report = HumanTraceSimulationBenchmark(
        benchmark,
      ).evaluate(simulation);

      expect(report.attemptedGames, 1);
      expect(report.observations, hasLength(2));
      expect(report.benchmark.secondCityMaxTurn, 23);
      expect(report.benchmark.minimumMaxCityCount, 2);
      expect(
        report.findings.map((finding) => finding.code),
        contains('missing_second_city'),
      );
      expect(report.toJson()['passed'], isFalse);
    });
  });
}
