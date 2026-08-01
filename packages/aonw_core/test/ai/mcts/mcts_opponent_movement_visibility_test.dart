import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'mcts_simulator_parity_support.dart';

void main() {
  test(
    'opponent movement uses omniscient visibility at the adapter boundary',
    () {
      final mapData = _mapData();
      final mover = GameUnit.produced(
        id: 'mover_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final hiddenFriendlyBlocker = GameUnit.produced(
        id: 'blocker_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 2,
        row: 0,
      );
      final executionWitness = GameUnit.produced(
        id: 'witness_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 3,
        row: 0,
      );
      final state = DomainState.snapshot(
        units: [mover, hiddenFriendlyBlocker, executionWitness],
        fogOfWar: FogOfWarState(
          players: {
            'player_2': PlayerFogOfWar(
              playerId: 'player_2',
              visibleHexes: {const HexCoordinate(col: 0, row: 0)},
            ),
          },
        ),
      );
      const command = MoveUnitCommand('mover_2', 2, 0);
      final pathingOnly = const SimulationGameEngineAdapter().apply(
        snapshot: MctsSimulatorParityFixtures.engineSnapshot(state),
        state: state,
        command: command,
        actorPlayerId: 'player_2',
        commandTick: 0,
        mapView: mapData,
        ruleset: GameRuleset.defaults,
        movementVisibilityMode:
            MovementCommandVisibilityMode.unrestrictedPathing,
      );
      final omniscient = const SimulationGameEngineAdapter().apply(
        snapshot: MctsSimulatorParityFixtures.engineSnapshot(state),
        state: state,
        command: command,
        actorPlayerId: 'player_2',
        commandTick: 0,
        mapView: mapData,
        ruleset: GameRuleset.defaults,
        movementVisibilityMode: MovementCommandVisibilityMode.unrestricted,
      );

      final simulated = MctsSimulatorParityFixtures.advanceSimulatedTurn(
        state,
        mapData: mapData,
        ignoreFogOfWar: true,
        simulator: TracingMctsSimulator(
          opponentStrategy: MctsSimulatorParityFixtures.fixedPlanStrategy([
            command,
            const MoveUnitCommand('witness_2', 4, 0),
          ]),
        ),
      );

      expect(pathingOnly.accepted, isTrue);
      expect(omniscient.accepted, isFalse);
      expect(omniscient.reason, 'move_target_occupied');
      expect(
        MctsSimulatorParityFixtures.unitById(
          pathingOnly.state.units,
          mover.id,
        ).col,
        1,
      );
      expect(
        MctsSimulatorParityFixtures.unitById(
          simulated.view.movementBlockingUnits,
          mover.id,
        ).toJson(),
        MctsSimulatorParityFixtures.unitById(
          omniscient.state.units,
          mover.id,
        ).toJson(),
      );
      expect(
        MctsSimulatorParityFixtures.unitById(
          simulated.view.movementBlockingUnits,
          executionWitness.id,
        ).col,
        4,
      );
    },
  );
}

WorldMap _mapData() {
  return WorldMap(
    cols: 5,
    rows: 1,
    tiles: [
      for (var col = 0; col < 5; col += 1)
        WorldTile(
          col: col,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
