import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/domain.dart';

List<CityHex> foundingHexes(int ac, int ar, int bc, int br) => [
  CityHex(col: ac, row: ar),
  CityHex(col: bc, row: br),
];

final class MctsSimulatorParityFixtures {
  const MctsSimulatorParityFixtures._();

  static WorldMap mapData() {
    return WorldMap(
      cols: 3,
      rows: 1,
      tiles: [
        WorldTile(
          col: 0,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [],
          height: 0,
        ),
        WorldTile(
          col: 1,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [],
          height: 0,
        ),
        WorldTile(
          col: 2,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [],
          height: 0,
        ),
      ],
    );
  }

  static WorldMap worldMap({WorldMap? mapData}) {
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
    DomainState state, {
    TracingMctsSimulator simulator = const TracingMctsSimulator(),
    WorldMap? mapData,
    bool ignoreFogOfWar = false,
    bool includeEngineSnapshot = true,
  }) {
    final actualMapData = mapData ?? MctsSimulatorParityFixtures.mapData();
    final view = GameView.fromDomainState(
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

  static CanonicalGameSnapshot engineSnapshot(DomainState state) {
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
    final canonicalState = state.copyWith(
      turn: 1,
      participants: participants,
      gameMode: GameMode.hotSeat,
    );
    return CanonicalGameSnapshot.snapshot(
      domain: canonicalState,

      metadata: GameSnapshotMetadata(
        id: 'mcts_parity',
        schemaVersion: 3,
        name: 'MCTS parity',
        world: const WorldReference(name: 'test', source: MapSource.asset),
        savedAtUtc: DateTime.utc(1970),
        camera: GameSnapshotCamera.zero,
      ),
    );
  }

  static GameView viewFromPersistentState(
    DomainState state, {
    required String forPlayerId,
    required int turn,
    required MapReadView mapData,
    required GameRuleset ruleset,
    Iterable<String> recentHostilePlayerIds = const [],
    Iterable<String> activeHostilePlayerIds = const [],
    Iterable<String> pressureTargetPlayerIds = const [],
    Iterable<String> defaultNeutralPlayerIds = const [],
    Iterable<PendingCityAttackThreat> pendingCityAttackThreats = const [],
    Iterable<String> forcedVisibleEnemyUnitIds = const [],
    bool ignoreFogOfWar = false,
    bool ignoreDynamicFogOfWar = false,
  }) {
    return GameView.fromDomainState(
      state,
      forPlayerId: forPlayerId,
      turn: turn,
      mapData: mapData,
      ruleset: ruleset,
      engineSnapshot: engineSnapshot(state),
      recentHostilePlayerIds: recentHostilePlayerIds,
      activeHostilePlayerIds: activeHostilePlayerIds,
      pressureTargetPlayerIds: pressureTargetPlayerIds,
      defaultNeutralPlayerIds: defaultNeutralPlayerIds,
      pendingCityAttackThreats: pendingCityAttackThreats,
      forcedVisibleEnemyUnitIds: forcedVisibleEnemyUnitIds,
      ignoreFogOfWar: ignoreFogOfWar,
      ignoreDynamicFogOfWar: ignoreDynamicFogOfWar,
    );
  }

  static SimulatedState simulatedState(
    DomainState state, {
    required MapReadView mapData,
    int maxPlanningDepth = 4,
  }) {
    return SimulatedState.fromView(
      viewFromPersistentState(
        state,
        forPlayerId: 'player_1',
        turn: 1,
        mapData: mapData,
        ruleset: GameRuleset.defaults,
      ),
      maxPlanningDepth: maxPlanningDepth,
    );
  }

  static SimulationGameEngineResult resolveEngineCommand(
    DomainState state,
    DomainCommand command, {
    MapReadView? mapView,
    String actorPlayerId = 'player_1',
  }) {
    final snapshot = engineSnapshot(state);
    return const SimulationGameEngineAdapter().apply(
      snapshot: snapshot,
      state: snapshot.domain,
      command: command,
      actorPlayerId: actorPlayerId,
      commandTick: 0,
      mapView: mapView ?? worldMap(),
      ruleset: GameRuleset.defaults,
    );
  }

  static GameUnit unitById(List<GameUnit> units, String id) {
    return units.singleWhere((unit) => unit.id == id);
  }

  static DomainState opponentWorkerState() {
    return DomainState.snapshot(
      participants: const [
        Player(id: 'player_2', name: 'player_2', colorValue: 0),
      ],
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

  static DomainState advancePersistentEconomyForPlayers(
    DomainState state, {
    WorldMap? mapData,
  }) {
    final actualMapData = mapData ?? MctsSimulatorParityFixtures.mapData();
    final snapshot = engineSnapshot(state);
    final result = const SimulationGameEngineAdapter().finalizeSimultaneousTurn(
      snapshot: snapshot,
      state: snapshot.domain,
      playerIds: snapshot.domain.participants.map((player) => player.id),
      commandTick: 1,
      mapView: actualMapData,
      ruleset: GameRuleset.defaults,
    );
    if (!result.accepted) {
      throw StateError(result.reason ?? 'turn finalization rejected');
    }
    return result.state;
  }

  static WorldMap explorationMapData() {
    return WorldMap(
      cols: 6,
      rows: 1,
      tiles: [
        for (var col = 0; col < 6; col += 1)
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

  static AiStrategy fixedPlanStrategy(List<DomainCommand> commands) {
    return _FixedPlanStrategy(commands);
  }
}

final class _FixedPlanStrategy implements AiStrategy {
  const _FixedPlanStrategy(this.commands);

  final List<DomainCommand> commands;

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    return AiTurnPlan(commands: commands);
  }
}
