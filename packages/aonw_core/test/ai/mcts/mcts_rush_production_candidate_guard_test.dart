import 'package:aonw_core/ai/mcts/mcts_command_validator.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'mcts_simulator_parity_support.dart';

const _rush = RushProductionCommand('city_1');
const _simulator = TracingMctsSimulator();

void main() {
  group('MCTS RushProduction fail-closed guard', () {
    test('rejects RushProduction at the canonical candidate boundary', () {
      expect(isLegalMctsCommandCandidate(_rush, _view()), isFalse);
    });

    test('does not expose RushProduction as a lightweight candidate', () {
      const generator = BasicPlanMctsActionGenerator(
        source: _RushStrategy(),
        candidateLimit: 8,
      );
      final view = _view();

      final actions = generator.candidatesFor(
        SimulatedState.fromView(view, maxPlanningDepth: 2),
        _context(),
      );

      expect(actions, isNot(contains(const CommandMctsAction(_rush))));
    });

    test('drops an injected RushProduction search action', () {
      final view = _view();

      final commands = const MctsCommandValidator().validatedCommands(
        const [CommandMctsAction(_rush)],
        rootState: SimulatedState.fromView(view, maxPlanningDepth: 2),
        simulator: _simulator,
      );

      expect(commands, isEmpty);
    });

    test('filters RushProduction from an expired-deadline fallback', () {
      const strategy = MctsStrategy(
        config: MctsConfig(minimumBudget: Duration(seconds: 1)),
        fallback: _RushStrategy(),
      );

      final plan = strategy.plan(
        _view(),
        _context(deadline: DateTime.now().subtract(const Duration(seconds: 1))),
      );

      expect(plan.commands, isNot(contains(_rush)));
      expect(plan.debug?.strategyId, 'mcts');
      expect(
        plan.debug?.notes,
        contains('bypassed search: deadline below minimum budget'),
      );
      expect(plan.debug?.metrics['mcts.searchBypassed'], true);
      expect(
        plan.debug?.metrics['mcts.bypassReason'],
        'deadline below minimum budget',
      );
    });

    test('filters RushProduction injected into the searched action route', () {
      const strategy = MctsStrategy(
        config: MctsConfig(
          wallClockBudget: Duration.zero,
          minIterations: 1,
          maxPlanningDepth: 1,
        ),
        actionGenerator: _RushActionGenerator(),
      );

      final plan = strategy.plan(_view(), _context());

      expect(plan.commands, isNot(contains(_rush)));
      expect(plan.debug?.strategyId, 'mcts');
    });
  });
}

GameView _view() {
  return MctsSimulatorParityFixtures.viewFromPersistentState(
    PersistentGameState(
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: _mapData,
    ruleset: GameRuleset.defaults,
  );
}

AiContext _context({DateTime? deadline}) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: _mapData,
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
    deadline: deadline,
  );
}

final _mapData = MapData(cols: 1, rows: 1, tiles: const []);

final class _RushStrategy implements AiStrategy {
  const _RushStrategy();

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    return AiTurnPlan(commands: const [_rush]);
  }
}

final class _RushActionGenerator implements MctsActionGenerator {
  const _RushActionGenerator();

  @override
  List<MctsAction> candidatesFor(SimulatedState state, AiContext context) {
    return const [CommandMctsAction(_rush)];
  }
}
