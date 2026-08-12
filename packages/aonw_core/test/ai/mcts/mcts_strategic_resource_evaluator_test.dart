import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'mcts_simulator_parity_support.dart';

void main() {
  test('StateHeuristicEvaluator lightly rewards useful strategic stock', () {
    const evaluator = StateHeuristicEvaluator();
    final empty = _state(DomainState.snapshot(matchRules: MatchRules.standard));
    final stocked = _state(
      DomainState.snapshot(
        matchRules: MatchRules.standard,
        strategicResources: StrategicResourceAccounts(
          byPlayerId: {
            'player_1': StrategicResourceStockpile(
              onHand: StrategicResourceBundle.oilTwo,
            ),
          },
        ),
      ),
    );

    expect(
      evaluator.score(stocked, 'player_1'),
      greaterThan(evaluator.score(empty, 'player_1')),
    );
  });
}

SimulatedState _state(DomainState state) =>
    MctsSimulatorParityFixtures.simulatedState(
      state,
      mapData: MctsSimulatorParityFixtures.mapData(),
    );
