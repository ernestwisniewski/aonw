part of '../initial_multiplayer_snapshot_factory_test.dart';

final _initialSnapshotStartedAt = DateTime.utc(2026, 7, 28, 12, 34, 56);

final _initialSnapshotMatch = WireMatch(
  id: 'initial-match',
  ownerUserId: 'owner-user',
  name: 'Initial canonical match',
  mapName: 'canonical-fixture',
  players: const [
    WirePlayer(
      id: 'player-human',
      userId: 'owner-user',
      name: 'Human',
      colorValue: 0xFF123456,
      country: PlayerCountry.poland,
      kind: WirePlayerKind.human,
      connectionState: WirePlayerConnectionState.connected,
      ready: true,
    ),
    WirePlayer(
      id: 'player-ai',
      userId: 'ai-user',
      name: 'Sentinel AI',
      colorValue: 0xFF654321,
      country: PlayerCountry.japan,
      kind: WirePlayerKind.ai,
      connectionState: WirePlayerConnectionState.offline,
      ready: true,
      ai: WireAiPlayer(
        strategyId: AiStrategyId.utility,
        difficulty: AiDifficulty.hard,
        persona: AiPersona.aggressive,
      ),
    ),
  ],
  turn: 1,
  state: 'running',
  createdAt: DateTime.utc(2026, 7, 28, 12),
);

final _initialSnapshotPlayers = [
  const Player(
    id: 'player-human',
    name: 'Human',
    colorValue: 0xFF123456,
    country: PlayerCountry.poland,
    kind: PlayerKind.human,
  ),
  Player(
    id: 'player-ai',
    name: 'Sentinel AI',
    colorValue: 0xFF654321,
    country: PlayerCountry.japan,
    kind: PlayerKind.ai,
    ai: AiPlayer(
      strategyId: AiStrategyId.utility,
      difficulty: AiDifficulty.hard,
      persona: AiPersona.aggressive,
      seed: StartingPositionSeed.fromParts(const [
        'player-ai',
        'Sentinel AI',
        'japan',
      ]),
    ),
  ),
];

WireSnapshot _currentInitialSnapshotOracle({
  required WorldMap mapData,
  required WireMatch match,
  required DateTime startedAt,
}) {
  final effectiveMap = mapData.mapName != null
      ? mapData
      : WorldMap(
          cols: mapData.cols,
          rows: mapData.rows,
          tiles: mapData.tiles,
          objectives: mapData.objectives,
          mapName: match.mapName,
          defaultZoom: mapData.defaultZoom,
        );
  final startPositionSeed = StartingPositionSeed.fromParts([
    startedAt,
    match.id,
    match.mapName,
    _initialSnapshotPlayers.length,
    for (final player in _initialSnapshotPlayers) player.id,
  ]);
  final units = StartingUnits.unitsForPlayers(
    _initialSnapshotPlayers,
    mapData: effectiveMap,
    startPositionSeed: startPositionSeed,
  );
  final artifacts = WorldArtifactGenerator.generate(
    mapData: effectiveMap,
    startingUnits: units,
    seed: startPositionSeed,
  );
  final playerIds = _initialSnapshotPlayers.map((player) => player.id);
  final fogOfWar = const FogOfWarService().recompute(
    current: FogOfWarState.empty,
    mapData: effectiveMap,
    playerIds: playerIds,
    units: units,
    cities: const [],
  );
  final diplomacy = DiplomaticContact.mergeDiscoveredContacts(
    diplomacy: DiplomacyState.empty,
    fogOfWar: fogOfWar,
    units: units,
    cities: const [],
    playerIds: playerIds,
  );
  final save = GameSave(
    id: match.id,
    name: MultiplayerSaveName.fromMatchName(match.name),
    mapName: match.mapName,
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: {
      for (final player in _initialSnapshotPlayers)
        player.id: PlayerTurnState.active,
    },
    savedAt: startedAt,
    camera: CameraState.zero,
    matchRules: MatchRules.standard,
    players: _initialSnapshotPlayers,
    gameMode: GameMode.multiplayer,
    origin: GameSaveOrigin.network,
  );
  final state = DomainState.snapshot(
    playerColors: {
      for (final player in _initialSnapshotPlayers)
        player.id: player.colorValue,
    },
    playerCountries: {
      for (final player in _initialSnapshotPlayers) player.id: player.country,
    },
    units: units,
    artifacts: artifacts,
    fogOfWar: fogOfWar,
    diplomacy: diplomacy,
    turnStartedAt: startedAt,
  );
  return WireSnapshot(
    matchId: match.id,
    offset: 0,
    save: save.toJson(),
    state: CanonicalGameSnapshotCodec.encodeDomainState(state),
  );
}

WorldMap _initialSnapshotMap() {
  return WorldMap(
    cols: 8,
    rows: 8,
    tiles: [
      for (var col = 0; col < 8; col += 1)
        for (var row = 0; row < 8; row += 1)
          WorldTile(
            col: col,
            row: row,
            terrains: const [TerrainType.grassland],
            resources: const [],
            height: 1,
          ),
    ],
  );
}

final class _InitialSnapshotMapCatalog implements MultiplayerMapCatalog {
  const _InitialSnapshotMapCatalog(this.mapData);

  final WorldMap mapData;

  @override
  Future<WorldMap> loadAssetMap(String mapName) async => mapData;
}
