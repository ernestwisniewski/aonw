import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

import 'mcts_simulator_parity_support.dart';

void main() {
  group('TracingMctsSimulator movement city visibility', () {
    test('rejects a route through a visible foreign city like the engine', () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      const city = GameCity(
        id: 'foreign_city',
        ownerPlayerId: 'player_2',
        name: 'Foreign city',
        center: CityHex(col: 1, row: 0),
      );
      final state = PersistentGameState(
        units: [unit],
        cities: const [city],
        fogOfWar: _visibleFog(),
      );
      const command = MoveUnitCommand('warrior_1', 2, 0);

      final engine = MctsSimulatorParityFixtures.resolveEngineCommand(
        state,
        command,
      );
      final simulated = _simulate(state, command);

      expect(engine.accepted, isFalse);
      expect(_unitById(simulated.ownUnits, 'warrior_1'), unit);
    });

    test('does not reveal a remembered hidden city during simulation', () {
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      const city = GameCity(
        id: 'remembered_city',
        ownerPlayerId: 'player_2',
        name: 'Remembered city',
        center: CityHex(col: 1, row: 0),
      );
      final state = PersistentGameState(
        units: [unit],
        cities: const [city],
        fogOfWar: FogOfWarState(
          players: {
            'player_1': PlayerFogOfWar(
              playerId: 'player_1',
              discoveredHexes: {
                const HexCoordinate(col: 0, row: 0),
                const HexCoordinate(col: 1, row: 0),
              },
              visibleHexes: {const HexCoordinate(col: 0, row: 0)},
            ),
          },
        ),
      );
      const command = MoveUnitCommand('warrior_1', 1, 0);

      final engine = MctsSimulatorParityFixtures.resolveEngineCommand(
        state,
        command,
      );
      final simulated = _simulate(state, command);

      expect(engine.accepted, isTrue);
      expect(engine.state, same(state));
      expect(_unitById(simulated.ownUnits, 'warrior_1'), unit);
    });
  });
}

SimulatedState _simulate(PersistentGameState state, DomainCommand command) {
  final view = GameView.fromPersistentState(
    state,
    forPlayerId: 'player_1',
    turn: 1,
    mapData: MctsSimulatorParityFixtures.mapData(),
    ruleset: GameRuleset.defaults,
    engineSnapshot: MctsSimulatorParityFixtures.engineSnapshot(state),
  );
  return const TracingMctsSimulator().applyAction(
    SimulatedState.fromView(view, maxPlanningDepth: 4),
    CommandMctsAction(command),
  );
}

GameUnit _unitById(List<GameUnit> units, String id) =>
    MctsSimulatorParityFixtures.unitById(units, id);

FogOfWarState _visibleFog() {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        visibleHexes: {
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 1, row: 0),
          const HexCoordinate(col: 2, row: 0),
        },
      ),
    },
  );
}
