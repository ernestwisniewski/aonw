import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/domain.dart';

List<CityHex> foundingHexes(int ac, int ar, int bc, int br) => [
  CityHex(col: ac, row: ar),
  CityHex(col: bc, row: br),
];

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
    final source = mapData ?? MctsSimulatorParityFixtures.mapData();
    return WorldMap.fromTileViews(
      cols: source.cols,
      rows: source.rows,
      tiles: source.tiles,
      objectives: source.objectives,
      mapName: source.mapName,
      defaultZoom: source.defaultZoom,
    );
  }

  static SimulatedState advanceSimulatedTurn(
    PersistentGameState state, {
    TracingMctsSimulator simulator = const TracingMctsSimulator(),
    MapData? mapData,
    bool ignoreFogOfWar = false,
    bool includeEngineSnapshot = true,
  }) {
    final actualMapData = mapData ?? MctsSimulatorParityFixtures.mapData();
    final view = GameView.fromPersistentState(
      state,
      forPlayerId: 'player_1',
      turn: 1,
      mapData: actualMapData,
      ruleset: GameRuleset.defaults,
      engineSnapshot: includeEngineSnapshot ? engineSnapshot(state) : null,
      ignoreFogOfWar: ignoreFogOfWar,
    );
    return simulator.advanceTurn(
      SimulatedState.fromView(view, maxPlanningDepth: 4),
    );
  }

  static CanonicalGameSnapshot engineSnapshot(PersistentGameState state) {
    final playerIds = state.knownPlayerIds.isEmpty
        ? const {'player_1'}
        : state.knownPlayerIds;
    final participants = [
      for (final playerId in playerIds)
        Player(
          id: playerId,
          name: playerId,
          colorValue: state.playerColors[playerId] ?? 0,
          country: state.playerCountries[playerId] ?? PlayerCountry.poland,
        ),
    ];
    final runtime = state.runtimeState;
    return CanonicalGameSnapshot.snapshot(
      domain: DomainState.snapshot(
        turn: 1,
        matchRules: MatchRules.standard,
        participants: participants,
        playerGold: state.playerGold,
        playerWarWeariness: state.playerWarWeariness,
        playerStabilityNet: state.playerStabilityNet,
        units: state.units,
        cities: state.cities,
        artifacts: state.artifacts,
        fieldImprovements: state.fieldImprovements,
        fogOfWar: state.fogOfWar,
        research: state.research,
        wonderRegistry: state.wonderRegistry,
        intendedAttacks: runtime.intendedAttacks,
        diplomacy: runtime.diplomacy,
        resourceTradeAgreements: runtime.resourceTradeAgreements,
        dominationHoldTurnsByPlayerId: runtime.dominationHoldTurnsByPlayerId,
        culturalVictoryHoldTurnsByPlayerId:
            runtime.culturalVictoryHoldTurnsByPlayerId,
        mapObjectiveHoldStatesByObjectiveId:
            runtime.mapObjectiveHoldStatesByObjectiveId,
      ),
      session: MatchSessionState.snapshot(gameMode: GameMode.hotSeat),
      metadata: GameSnapshotMetadata(
        id: 'mcts_parity',
        schemaVersion: 3,
        name: 'MCTS parity',
        world: const WorldReference(name: 'test', source: MapSource.asset),
        savedAtUtc: DateTime.utc(1970),
        camera: GameSnapshotCamera.zero,
      ),
      interaction: PersistedInteractionState(
        cityFoundingDraft: runtime.cityFoundingDraft,
        pendingAction: runtime.pendingAction,
      ),
    );
  }

  static SimulationGameEngineResult resolveEngineCommand(
    PersistentGameState state,
    DomainCommand command, {
    MapReadView? mapView,
    String actorPlayerId = 'player_1',
  }) {
    return const SimulationGameEngineAdapter().apply(
      snapshot: engineSnapshot(state),
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      commandTick: 0,
      mapView: mapView ?? WorldMapReadView(worldMap()),
      ruleset: GameRuleset.defaults,
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
