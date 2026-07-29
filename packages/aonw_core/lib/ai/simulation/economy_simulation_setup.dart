part of 'economy_simulation.dart';

abstract final class _EconomySimulationSetup {
  static PersistentGameState recomputeFog({
    required PersistentGameState state,
    required MapReadView mapView,
    required Iterable<String> playerIds,
  }) {
    return state.copyWith(
      fogOfWar: const FogOfWarService().recompute(
        current: state.fogOfWar,
        mapData: mapView,
        playerIds: playerIds,
        units: state.units,
        cities: state.cities,
      ),
    );
  }

  static GameView planningView({
    required PersistentGameState state,
    required String playerId,
    required int turn,
    required MapReadView mapView,
    required GameRuleset ruleset,
    required CanonicalGameSnapshot engineSnapshot,
    required Iterable<String> recentHostilePlayerIds,
  }) {
    return GameView.fromPersistentState(
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
    required PersistentGameState state,
    required MapReadView mapView,
  }) {
    final runtime = state.runtimeState;
    return CanonicalGameSnapshot.snapshot(
      domain: DomainState.snapshot(
        turn: 0,
        matchRules: config.matchRules,
        participants: [config.player, ...config.opponents],
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
      session: MatchSessionState.snapshot(
        gameMode: GameMode.hotSeat,
        turnStatesByPlayerId: {
          for (final player in [config.player, ...config.opponents])
            player.id: PlayerTurnState.active,
        },
        submittedPlayerIds: runtime.submittedPlayerIds,
        timeoutStreaksByPlayerId: runtime.timeoutStreaksByPlayerId,
        afkPlayerIds: runtime.afkPlayerIds,
        kickedPlayerIds: runtime.kickedPlayerIds,
        turnStartedAt: runtime.turnStartedAt,
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
      interaction: PersistedInteractionState(
        cityFoundingDraft: runtime.cityFoundingDraft,
        pendingAction: runtime.pendingAction,
      ),
    );
  }

  static PersistentGameState initialState({
    required Player player,
    required List<Player> opponents,
    required MapReadView mapView,
  }) {
    final players = [player, ...opponents];
    final units = StartingUnits.unitsForPlayers(players, mapData: mapView);
    final state = PersistentGameState.snapshot(
      playerColors: {
        for (final simulationPlayer in players)
          simulationPlayer.id: simulationPlayer.colorValue,
      },
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

  static MapData simulationMap() {
    const size = 9;
    return MapData(
      cols: size,
      rows: size,
      mapName: 'economy_simulation',
      tiles: [
        for (var row = 0; row < size; row++)
          for (var col = 0; col < size; col++) _tile(col, row),
      ],
    );
  }

  static TileData _tile(int col, int row) {
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
    return TileData(
      col: col,
      row: row,
      terrains: [terrain],
      resources: [?resource],
      height: terrain == TerrainType.hills ? 1 : 0,
    );
  }
}
