import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'mcts_simulator_parity_support.dart';

void main() {
  test('opponent unit actions fail loudly without an engine envelope', () {
    final ownUnit = GameUnit.produced(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 0,
      row: 0,
    );
    final opponent = GameUnit.produced(
      id: 'warrior_2',
      ownerPlayerId: 'player_2',
      type: GameUnitType.warrior,
      col: 1,
      row: 0,
    );
    final state = PersistentGameState(units: [ownUnit, opponent]);
    final simulator = TracingMctsSimulator(
      opponentStrategy: MctsSimulatorParityFixtures.fixedPlanStrategy(const [
        SkipUnitTurnCommand('warrior_2'),
      ]),
    );

    expect(
      () => MctsSimulatorParityFixtures.advanceSimulatedTurn(
        state,
        simulator: simulator,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
