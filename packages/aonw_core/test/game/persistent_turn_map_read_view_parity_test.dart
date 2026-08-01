import 'package:aonw_core/ai/simulation/simulation_game_engine_adapter.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  test('advancePlayer forwards objectives owned by MapData', () {
    const objective = MapObjectiveDefinition(
      id: 'pass_1',
      type: MapObjectiveType.strategicPass,
      hex: HexCoord(col: 1, row: 0),
      requiredHoldTurns: 1,
      victoryPoints: 3,
      goldPerTurn: 4,
    );
    final mapData = _mapData(objectives: const [objective]);
    final state = PersistentGameState(
      playerGold: const {'player_1': 10},
      units: [
        GameUnit.startingWarrior(ownerPlayerId: 'player_1', col: 1, row: 0),
      ],
    );

    final snapshot = _snapshot(state);
    final result = const SimulationGameEngineAdapter().finalizeSimultaneousTurn(
      snapshot: snapshot,
      state: state,
      playerIds: const ['player_1'],
      commandTick: 1,
      mapView: mapData,
      ruleset: GameRuleset.defaults,
    );

    expect(
      result
          .state
          .runtimeState
          .mapObjectiveHoldStatesByObjectiveId['pass_1']
          ?.holdTurns,
      1,
    );
    expect(result.state.playerGold['player_1'], 14);
    expect(
      result.events,
      contains(
        isA<MapObjectiveSecuredEvent>()
            .having((event) => event.objectiveId, 'objectiveId', 'pass_1')
            .having((event) => event.playerId, 'playerId', 'player_1'),
      ),
    );
  });

  test(
    'MapData and canonical read views advance economy and movement equally',
    () {
      final mapData = _mapData();
      final mapView = WorldMapReadView(
        WorldMap.fromTileViews(
          cols: mapData.cols,
          rows: mapData.rows,
          tiles: mapData.tiles,
          objectives: mapData.objectives,
          mapName: mapData.mapName,
          defaultZoom: mapData.defaultZoom,
        ),
      );
      final state = _turnState();

      final legacyEconomy = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: state,
        playerIds: const ['player_1'],
        mapData: mapData,
      );
      final canonicalEconomy = PersistentTurnEconomyProcessor.advanceForPlayers(
        state: state,
        playerIds: const ['player_1'],
        mapData: mapView,
      );

      expect(canonicalEconomy.state, legacyEconomy.state);
      expect(canonicalEconomy.scienceGained, legacyEconomy.scienceGained);
      expect(
        canonicalEconomy.events.map(GameEventSerializer.toJson),
        legacyEconomy.events.map(GameEventSerializer.toJson),
      );

      final legacyMovement = PersistentTurnMovementProcessor.resetForPlayers(
        state: legacyEconomy.state,
        playerIds: const ['player_1'],
        mapData: mapData,
      );
      final canonicalMovement = PersistentTurnMovementProcessor.resetForPlayers(
        state: canonicalEconomy.state,
        playerIds: const ['player_1'],
        mapData: mapView,
      );

      expect(canonicalMovement.changed, legacyMovement.changed);
      expect(canonicalMovement.state, legacyMovement.state);
      expect(canonicalMovement.state.units.single.col, 2);
      expect(canonicalMovement.state.units.single.row, 0);
    },
  );
}

CanonicalGameSnapshot _snapshot(PersistentGameState state) {
  return CanonicalGameSnapshot.snapshot(
    domain: DomainState.snapshot(
      turn: 1,
      matchRules: MatchRules.standard,
      participants: const [
        Player(id: 'player_1', name: 'Player 1', colorValue: 1),
      ],
      playerGold: state.playerGold,
      units: state.units,
    ),
    session: MatchSessionState.snapshot(
      gameMode: GameMode.hotSeat,
      turnStatesByPlayerId: const {'player_1': PlayerTurnState.active},
    ),
    metadata: GameSnapshotMetadata(
      id: 'turn_map_view_parity',
      schemaVersion: 3,
      name: 'Turn map view parity',
      world: const WorldReference(name: 'test', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 1, 1),
      camera: GameSnapshotCamera.zero,
    ),
  );
}

MapData _mapData({Iterable<MapObjectiveDefinition> objectives = const []}) {
  return MapData(
    cols: 4,
    rows: 2,
    tiles: [
      for (var col = 0; col < 4; col++)
        for (var row = 0; row < 2; row++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 1,
          ),
    ],
    objectives: objectives,
  );
}

PersistentGameState _turnState() {
  final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1')
      .copyWith(movementPoints: 0)
      .copyWithQueuedPath(
        QueuedMovePath(
          targetCol: 2,
          targetRow: 0,
          steps: const [
            UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
            UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
          ],
        ),
      );
  return PersistentGameState(
    playerGold: const {'player_1': 3},
    units: [commander],
    cities: const [
      GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City 1',
        center: CityHex(col: 0, row: 1),
        controlledHexes: [CityHex(col: 1, row: 1)],
      ),
    ],
  );
}
