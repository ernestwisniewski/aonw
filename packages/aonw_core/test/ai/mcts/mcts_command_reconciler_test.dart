import 'package:aonw_core/ai/mcts/mcts_baseline_command_merger.dart';
import 'package:aonw_core/ai/mcts/mcts_command_reconciler.dart';
import 'package:aonw_core/ai/mcts/mcts_command_validator.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  const simulator = TracingMctsSimulator();

  group('MctsCommandValidator', () {
    const validator = MctsCommandValidator();

    test('keeps only one validated action per unit', () {
      final view = _unitView();
      final commands = validator.validatedCommands(
        const [
          CommandMctsAction(MoveUnitCommand('warrior_1', 1, 0)),
          CommandMctsAction(FortifyUnitCommand('warrior_1')),
        ],
        rootState: SimulatedState.fromView(view, maxPlanningDepth: 2),
        simulator: simulator,
      );

      expect(commands, const [MoveUnitCommand('warrior_1', 1, 0)]);
    });
  });

  group('MctsBaselineCommandMerger', () {
    const merger = MctsBaselineCommandMerger();

    test('keeps baseline economy commands after tactical search commands', () {
      final view = _cityUnitView();
      const searched = [FortifyUnitCommand('warrior_1')];
      const production = StartUnitProductionCommand(
        'city_1',
        GameUnitType.worker,
      );

      final commands = merger.withBaselineSupportCommands(
        searched,
        const [production],
        view,
        _context(mapData: _unitMap()),
        simulator: simulator,
      );

      expect(commands, const [...searched, production]);
    });
  });

  group('MctsCommandReconciler', () {
    const reconciler = MctsCommandReconciler();

    test('keeps facade API for strategy orchestration', () {
      final view = _unitView();

      final commands = reconciler.validatedCommands(
        const [CommandMctsAction(MoveUnitCommand('warrior_1', 1, 0))],
        rootState: SimulatedState.fromView(view, maxPlanningDepth: 1),
        simulator: simulator,
      );

      expect(commands, const [MoveUnitCommand('warrior_1', 1, 0)]);
    });
  });
}

AiContext _context({MapData? mapData}) {
  final actualMapData = mapData ?? MapData(cols: 1, rows: 1, tiles: const []);
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: actualMapData,
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
  );
}

GameView _unitView() {
  final mapData = _unitMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      units: [
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

GameView _cityUnitView() {
  final mapData = _unitMap();
  return GameView.fromPersistentState(
    PersistentGameState(
      cities: const [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 0, row: 0),
        ),
      ],
      units: [
        GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
      ],
      fogOfWar: FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            visibleHexes: {
              const HexCoordinate(col: 0, row: 0),
              const HexCoordinate(col: 1, row: 0),
            },
          ),
        },
      ),
    ),
    forPlayerId: 'player_1',
    turn: 1,
    mapData: mapData,
    ruleset: GameRuleset.defaults,
  );
}

MapData _unitMap() {
  return MapData(
    cols: 2,
    rows: 1,
    tiles: const [
      TileData(
        col: 0,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 1,
      ),
      TileData(
        col: 1,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 1,
      ),
    ],
  );
}
