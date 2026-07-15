import 'package:aonw_core/domain.dart';

final class MctsSimulatorParityFixtures {
  const MctsSimulatorParityFixtures._();

  static MapData mapData() {
    return MapData(
      cols: 3,
      rows: 1,
      tiles: const [
        TileData(
          col: 0,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [],
          height: 0,
        ),
        TileData(
          col: 1,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [],
          height: 0,
        ),
        TileData(
          col: 2,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [],
          height: 0,
        ),
      ],
    );
  }

  static WorldMap worldMap({MapData? mapData}) {
    return LegacyWorldMapAdapter.fromMapData(
      mapData ?? MctsSimulatorParityFixtures.mapData(),
    );
  }

  static SimulatedState advanceSimulatedTurn(
    PersistentGameState state, {
    TracingMctsSimulator simulator = const TracingMctsSimulator(),
    MapData? mapData,
    bool ignoreFogOfWar = false,
  }) {
    final actualMapData = mapData ?? MctsSimulatorParityFixtures.mapData();
    final view = GameView.fromPersistentState(
      state,
      forPlayerId: 'player_1',
      turn: 1,
      mapData: actualMapData,
      ruleset: GameRuleset.defaults,
      ignoreFogOfWar: ignoreFogOfWar,
    );
    return simulator.advanceTurn(
      SimulatedState.fromView(view, maxPlanningDepth: 4),
    );
  }

  static GameUnit unitById(List<GameUnit> units, String id) {
    return units.singleWhere((unit) => unit.id == id);
  }

  static PersistentGameState opponentWorkerState() {
    return PersistentGameState(
      units: [
        GameUnit(
          id: 'worker_2',
          ownerPlayerId: 'player_2',
          type: GameUnitType.worker,
          name: GameUnitType.worker.defaultNameToken,
          col: 2,
          row: 0,
        ),
      ],
      cities: [
        const GameCity(
          id: 'city_2',
          ownerPlayerId: 'player_2',
          name: 'Opponent City',
          center: CityHex(col: 1, row: 0),
          controlledHexes: [CityHex(col: 2, row: 0)],
        ),
      ],
    );
  }

  static PersistentGameState advancePersistentEconomyForPlayers(
    PersistentGameState state, {
    MapData? mapData,
  }) {
    final actualMapData = mapData ?? MctsSimulatorParityFixtures.mapData();
    return PersistentTurnEconomyProcessor.advanceForPlayers(
      state: state,
      playerIds: const ['player_1', 'player_2'],
      mapData: actualMapData,
      ruleset: GameRuleset.defaults,
      mapObjectives: actualMapData.objectives,
    ).state;
  }

  static MapData explorationMapData() {
    return MapData(
      cols: 6,
      rows: 1,
      tiles: [
        for (var col = 0; col < 6; col += 1)
          TileData(
            col: col,
            row: 0,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
      ],
    );
  }

  static AiStrategy fixedPlanStrategy(List<GameCommand> commands) {
    return _FixedPlanStrategy(commands);
  }
}

final class _FixedPlanStrategy implements AiStrategy {
  const _FixedPlanStrategy(this.commands);

  final List<GameCommand> commands;

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    return AiTurnPlan(commands: commands);
  }
}
