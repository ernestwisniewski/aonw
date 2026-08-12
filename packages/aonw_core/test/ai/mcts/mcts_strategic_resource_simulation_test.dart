import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'mcts_simulator_parity_support.dart';

void main() {
  test('MCTS reserves strategic stock like the canonical engine', () {
    final state = DomainState.snapshot(
      matchRules: MatchRules.standard,
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 1, row: 0),
        ),
      ],
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.massProduction},
          ),
        },
      ),
      strategicResources: StrategicResourceAccounts(
        byPlayerId: {
          'player_1': StrategicResourceStockpile(
            onHand: StrategicResourceBundle.oilTwo,
          ),
        },
      ),
    );
    const command = StartUnitProductionCommand('city_1', GameUnitType.tank);

    final persistent = MctsSimulatorParityFixtures.resolveEngineCommand(
      state,
      command,
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 1,
      mapData: MctsSimulatorParityFixtures.mapData(),
      ruleset: GameRuleset.defaults,
      engineSnapshot: MctsSimulatorParityFixtures.engineSnapshot(state),
    );
    final simulated = const TracingMctsSimulator().applyAction(
      SimulatedState.fromView(view, maxPlanningDepth: 4),
      const CommandMctsAction(command),
    );

    expect(persistent.accepted, isTrue);
    expect(
      simulated.ownCities.single.productionQueue,
      persistent.state.cities.single.productionQueue,
    );
    expect(
      simulated.view.ownStrategicResources,
      persistent.state.strategicResources.forPlayer('player_1'),
    );
  });
}
