part of 'economy_simulation.dart';

abstract final class _EconomySimulationSetup {
  static GameView planningView({
    required DomainState state,
    required String playerId,
    required int turn,
    required MapReadView mapView,
    required GameRuleset ruleset,
    required CanonicalGameSnapshot engineSnapshot,
    required Iterable<String> recentHostilePlayerIds,
  }) {
    return GameView.fromDomainState(
      state,
      forPlayerId: playerId,
      turn: turn,
      mapData: mapView,
      ruleset: ruleset,
      engineSnapshot: engineSnapshot,
      recentHostilePlayerIds: recentHostilePlayerIds,
      ignoreFogOfWar: true,
    );
  }

  static CanonicalGameSnapshot engineSnapshot({
    required EconomySimulationConfig config,
    required DomainState state,
    required MapReadView mapView,
  }) {
    return CanonicalGameSnapshot.snapshot(
      domain: state.copyWith(
        turn: 0,
        matchRules: config.matchRules,
        participants: [config.player, ...config.opponents],
        gameMode: GameMode.hotSeat,
        turnStatesByPlayerId: {
          for (final player in [config.player, ...config.opponents])
            player.id: PlayerTurnState.active,
        },
      ),
      metadata: GameSnapshotMetadata(
        id: 'economy_simulation',
        schemaVersion: 3,
        name: 'Economy simulation',
        world: WorldReference(
          name: mapView.mapName ?? 'economy_simulation',
          source: MapSource.asset,
        ),
        savedAtUtc: DateTime.utc(1970),
        camera: GameSnapshotCamera.zero,
      ),
    );
  }

  static DomainState initialState({
    required Player player,
    required List<Player> opponents,
    required MapReadView mapView,
  }) {
    final players = [player, ...opponents];
    final units = StartingUnits.unitsForPlayers(players, mapData: mapView);
    final state = DomainState.snapshot(
      turn: 0,
      matchRules: MatchRules.standard,
      participants: players,
      playerGold: {
        for (final simulationPlayer in players) simulationPlayer.id: 0,
      },
      units: units,
    );
    final fogOfWar = const FogOfWarService().recompute(
      current: state.fogOfWar,
      mapData: mapView,
      playerIds: [for (final simulationPlayer in players) simulationPlayer.id],
      units: state.units,
      cities: state.cities,
    );
    return state.copyWith(fogOfWar: fogOfWar);
  }

  static WorldMap simulationMap() {
    const size = 9;
    return WorldMap(
      cols: size,
      rows: size,
      mapName: 'economy_simulation',
      tiles: [
        for (var row = 0; row < size; row++)
          for (var col = 0; col < size; col++) _tile(col, row),
      ],
    );
  }

  static WorldTile _tile(int col, int row) {
    final resource = switch ((col, row)) {
      (3, 2) || (7, 7) => ResourceType.wheat,
      (2, 4) || (8, 6) => ResourceType.iron,
      (4, 3) => ResourceType.deer,
      _ => null,
    };
    final terrain = switch ((col + row) % 7) {
      0 => TerrainType.hills,
      1 => TerrainType.forest,
      2 => TerrainType.grassland,
      _ => TerrainType.plains,
    };
    return WorldTile(
      col: col,
      row: row,
      terrains: [terrain],
      resources: [?resource],
      height: terrain == TerrainType.hills ? 1 : 0,
    );
  }
}
