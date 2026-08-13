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

  test('MCTS applies extraction from known opponent improvements', () {
    final mapData = WorldMap(
      cols: 3,
      rows: 1,
      tiles: [
        WorldTile(
          col: 0,
          row: 0,
          terrains: [TerrainType.grassland],
          resources: [],
          height: 0,
        ),
        WorldTile(
          col: 1,
          row: 0,
          terrains: [TerrainType.grassland],
          resources: [],
          height: 0,
        ),
        WorldTile(
          col: 2,
          row: 0,
          terrains: [TerrainType.grassland],
          resources: [ResourceType.oil],
          height: 0,
        ),
      ],
    );
    final state = DomainState.snapshot(
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: 'player_1', name: 'Player 1', colorValue: 1),
        Player(id: 'player_2', name: 'Player 2', colorValue: 2),
      ],
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Own',
          center: CityHex(col: 0, row: 0),
        ),
        GameCity(
          id: 'city_2',
          ownerPlayerId: 'player_2',
          name: 'Known rival',
          center: CityHex(col: 2, row: 0),
          controlledHexes: [CityHex(col: 2, row: 0)],
        ),
      ],
      fieldImprovements: const [
        FieldImprovement(
          hex: CityHex(col: 2, row: 0),
          type: FieldImprovementType.oilWell,
          builtByCityId: 'city_2',
        ),
      ],
      research: ResearchState(
        players: {
          'player_2': PlayerResearchState(
            unlockedTechnologyIds: {TechnologyId.combustion},
          ),
        },
      ),
    );
    final view = GameView.fromDomainState(
      state,
      forPlayerId: 'player_1',
      turn: 1,
      mapData: mapData,
      ruleset: GameRuleset.defaults,
      engineSnapshot: MctsSimulatorParityFixtures.engineSnapshot(state),
      ignoreFogOfWar: true,
    );

    final advanced = const TracingMctsSimulator(
      simulateOpponentPlans: false,
    ).advanceTurn(SimulatedState.fromView(view, maxPlanningDepth: 1));

    expect(
      advanced.view.engineSnapshot!.domain.strategicResources
          .forPlayer('player_2')
          .amountFor(ResourceType.oil),
      1,
    );
  });
}
