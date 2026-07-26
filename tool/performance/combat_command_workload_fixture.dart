part of 'combat_command_workload.dart';

final class _CombatCommandFixture {
  const _CombatCommandFixture({
    required this.entityCount,
    required this.artifacts,
    required this.mapTiles,
    required this.kernelState,
    required this.persistentState,
    required this.domainState,
  });

  factory _CombatCommandFixture.forScale(int scale) {
    if (!combatCommandScales.contains(scale)) {
      throw ArgumentError.value(
        scale,
        'scale',
        'Supported scales are 100, 1000, and 10000.',
      );
    }
    final units = [
      GameUnit.produced(
        id: _combatAttackerId,
        ownerPlayerId: _combatActorId,
        type: GameUnitType.warrior,
        col: 1,
        row: 2,
      ),
      GameUnit.produced(
        id: _combatDefenderId,
        ownerPlayerId: _combatOpponentId,
        type: GameUnitType.settler,
        col: 2,
        row: 2,
      ),
    ];
    final artifacts = [
      for (var index = 0; index < scale - units.length; index++)
        WorldArtifact(
          id: 'combat_benchmark_artifact_$index',
          type: WorldArtifactType.astronomersTablets,
          location: const WorldArtifactLocation.map(col: 4, row: 4),
        ),
    ];
    final fogOfWar = _combatVisibleFog();
    final persistent = PersistentGameState.snapshot(
      playerColors: const {
        _combatActorId: 0xFF112233,
        _combatOpponentId: 0xFF445566,
      },
      playerCountries: const {
        _combatActorId: PlayerCountry.poland,
        _combatOpponentId: PlayerCountry.france,
      },
      playerGold: const {_combatActorId: 10, _combatOpponentId: 10},
      units: units,
      artifacts: artifacts,
      fogOfWar: fogOfWar,
      runtimeState: GameRuntimeState.snapshot(),
    );
    final domain = DomainState.snapshot(
      turn: _combatTurn,
      matchRules: MatchRules.standard,
      participants: const [
        Player(
          id: _combatActorId,
          name: 'Benchmark actor',
          colorValue: 0xFF112233,
          country: PlayerCountry.poland,
        ),
        Player(
          id: _combatOpponentId,
          name: 'Benchmark opponent',
          colorValue: 0xFF445566,
          country: PlayerCountry.france,
        ),
      ],
      playerGold: const {_combatActorId: 10, _combatOpponentId: 10},
      units: units,
      artifacts: artifacts,
      fogOfWar: fogOfWar,
    );
    return _CombatCommandFixture(
      entityCount: scale,
      artifacts: artifacts,
      mapTiles: _combatMap(),
      kernelState: CombatCommandState(
        units: domain.units,
        cities: domain.cities,
        artifacts: domain.artifacts,
        fogOfWar: domain.fogOfWar,
        research: domain.research,
        intendedAttacks: domain.intendedAttacks,
        diplomacy: domain.diplomacy,
        resourceTradeAgreements: domain.resourceTradeAgreements,
        playerIds: domain.participants.map((player) => player.id),
      ),
      persistentState: persistent,
      domainState: domain,
    );
  }

  final int entityCount;
  final List<WorldArtifact> artifacts;
  final MapTileLookup mapTiles;
  final CombatCommandState kernelState;
  final PersistentGameState persistentState;
  final DomainState domainState;
}

FogOfWarState _combatVisibleFog() {
  final visible = {
    const HexCoordinate(col: 1, row: 2),
    const HexCoordinate(col: 2, row: 2),
  };
  return FogOfWarState(
    players: {
      _combatActorId: PlayerFogOfWar(
        playerId: _combatActorId,
        visibleHexes: visible,
      ),
      _combatOpponentId: PlayerFogOfWar(
        playerId: _combatOpponentId,
        visibleHexes: visible,
      ),
    },
  );
}

MapTileLookup _combatMap() {
  return WorldMapReadView(
    WorldMap(
      cols: 5,
      rows: 5,
      tiles: [
        for (var row = 0; row < 5; row++)
          for (var col = 0; col < 5; col++)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: const [TerrainType.grassland],
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}

final class _CountingCombatMapTiles implements MapTileLookup {
  _CountingCombatMapTiles(this._delegate);

  final MapTileLookup _delegate;
  int calls = 0;
  int hits = 0;

  @override
  MapTileView? tileAt(int col, int row) {
    calls++;
    final tile = _delegate.tileAt(col, row);
    if (tile != null) hits++;
    return tile;
  }
}

final class _CombatBoundaryExecution {
  const _CombatBoundaryExecution({
    required this.output,
    required this.fogCounters,
  });

  final Map<String, Object?> output;
  final FogOfWarRecomputeCounters fogCounters;
}

final class _CountedCombatBoundaries {
  const _CountedCombatBoundaries({
    required this.kernel,
    required this.persistent,
    required this.domain,
    required this.tileLookupCalls,
    required this.tileLookupHits,
  });

  final _CombatBoundaryExecution kernel;
  final _CombatBoundaryExecution persistent;
  final _CombatBoundaryExecution domain;
  final Map<String, int> tileLookupCalls;
  final Map<String, int> tileLookupHits;

  Map<String, _CombatBoundaryExecution> get outputs => {
    'kernel': kernel,
    'persistent': persistent,
    'domain': domain,
  };
}

final class _CombatCommandScaleResult {
  const _CombatCommandScaleResult({
    required this.stable,
    required this.observations,
  });

  final Map<String, Object?> stable;
  final Map<String, Object?> observations;
}
