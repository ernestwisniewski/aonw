import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'mcts_simulator_parity_support.dart';

void main() {
  group('TracingMctsSimulator opponent WorldMap command parity', () {
    test('auto-explores with the persistent WorldMap resolver', () {
      final mapData = MctsSimulatorParityFixtures.explorationMapData();
      final scout = GameUnit.produced(
        id: 'scout_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.scout,
        col: 1,
        row: 0,
      );
      final state = PersistentGameState(
        units: [scout],
        fogOfWar: FogOfWarState(
          players: {
            'player_2': PlayerFogOfWar(
              playerId: 'player_2',
              discoveredHexes: {
                const HexCoordinate(col: 0, row: 0),
                const HexCoordinate(col: 1, row: 0),
                const HexCoordinate(col: 2, row: 0),
              },
            ),
          },
        ),
      );
      const command = AutoExploreUnitCommand('scout_2');

      final persistent = const PersistentUnitActionResolver().autoExploreUnit(
        state: state,
        command: command,
        actorPlayerId: 'player_2',
        mapData: WorldMapReadView(
          MctsSimulatorParityFixtures.worldMap(mapData: mapData),
        ),
      );
      final expected =
          MctsSimulatorParityFixtures.advancePersistentEconomyForPlayers(
            persistent.state,
            mapData: mapData,
          );
      final simulated = MctsSimulatorParityFixtures.advanceSimulatedTurn(
        state,
        mapData: mapData,
        ignoreFogOfWar: true,
        simulator: TracingMctsSimulator(
          opponentStrategy: MctsSimulatorParityFixtures.fixedPlanStrategy([
            command,
          ]),
        ),
      );

      expect(persistent.accepted, isTrue);
      expect(
        MctsSimulatorParityFixtures.unitById(
          simulated.view.movementBlockingUnits,
          'scout_2',
        ).toJson(),
        MctsSimulatorParityFixtures.unitById(
          expected.units,
          'scout_2',
        ).toJson(),
      );
    });

    test('rejects an unavailable worker improvement like the resolver', () {
      final state = MctsSimulatorParityFixtures.opponentWorkerState();
      const command = SelectWorkerImprovementCommand(
        'worker_2',
        FieldImprovementType.farm,
      );

      final persistent = const PersistentWorkerCommandResolver()
          .selectWorkerImprovement(
            state: state,
            command: command,
            actorPlayerId: 'player_2',
            mapTiles: WorldMapReadView(MctsSimulatorParityFixtures.worldMap()),
            cityRuleset: GameRuleset.defaults.city,
            technologyRuleset: GameRuleset.defaults.technology,
            paceBalance: GameRuleset.defaults.paceBalance,
          );
      final expected =
          MctsSimulatorParityFixtures.advancePersistentEconomyForPlayers(
            persistent.state,
          );
      final simulated = MctsSimulatorParityFixtures.advanceSimulatedTurn(
        state,
        ignoreFogOfWar: true,
        simulator: TracingMctsSimulator(
          opponentStrategy: MctsSimulatorParityFixtures.fixedPlanStrategy([
            command,
          ]),
        ),
      );

      expect(persistent.accepted, isFalse);
      expect(
        MctsSimulatorParityFixtures.unitById(
          simulated.view.movementBlockingUnits,
          'worker_2',
        ).toJson(),
        MctsSimulatorParityFixtures.unitById(
          expected.units,
          'worker_2',
        ).toJson(),
      );
    });

    test('rejects an unavailable confirmed improvement like the resolver', () {
      final state = MctsSimulatorParityFixtures.opponentWorkerState();
      const command = ConfirmWorkerImprovementCommand(
        'worker_2',
        improvementType: FieldImprovementType.farm,
      );

      final persistent = const PersistentWorkerCommandResolver()
          .confirmWorkerImprovement(
            state: state,
            command: command,
            actorPlayerId: 'player_2',
            mapTiles: WorldMapReadView(MctsSimulatorParityFixtures.worldMap()),
            cityRuleset: GameRuleset.defaults.city,
            technologyRuleset: GameRuleset.defaults.technology,
            paceBalance: GameRuleset.defaults.paceBalance,
          );
      final expected =
          MctsSimulatorParityFixtures.advancePersistentEconomyForPlayers(
            persistent.state,
          );
      final simulated = MctsSimulatorParityFixtures.advanceSimulatedTurn(
        state,
        ignoreFogOfWar: true,
        simulator: TracingMctsSimulator(
          opponentStrategy: MctsSimulatorParityFixtures.fixedPlanStrategy([
            command,
          ]),
        ),
      );

      expect(persistent.accepted, isFalse);
      expect(
        MctsSimulatorParityFixtures.unitById(
          simulated.view.movementBlockingUnits,
          'worker_2',
        ).toJson(),
        MctsSimulatorParityFixtures.unitById(
          expected.units,
          'worker_2',
        ).toJson(),
      );
    });

    test('rejects an unavailable worker assignment like the resolver', () {
      final state = MctsSimulatorParityFixtures.opponentWorkerState();
      const command = AssignWorkerToHexCommand('worker_2');

      final persistent = const PersistentWorkerCommandResolver()
          .assignWorkerToHex(
            state: state,
            command: command,
            actorPlayerId: 'player_2',
            mapTiles: WorldMapReadView(MctsSimulatorParityFixtures.worldMap()),
          );
      final expected =
          MctsSimulatorParityFixtures.advancePersistentEconomyForPlayers(
            persistent.state,
          );
      final simulated = MctsSimulatorParityFixtures.advanceSimulatedTurn(
        state,
        ignoreFogOfWar: true,
        simulator: TracingMctsSimulator(
          opponentStrategy: MctsSimulatorParityFixtures.fixedPlanStrategy([
            command,
          ]),
        ),
      );

      expect(persistent.accepted, isFalse);
      expect(
        MctsSimulatorParityFixtures.unitById(
          simulated.view.movementBlockingUnits,
          'worker_2',
        ).toJson(),
        MctsSimulatorParityFixtures.unitById(
          expected.units,
          'worker_2',
        ).toJson(),
      );
    });
  });
}
