part of 'turn_engine_handler_test.dart';

GameEngineResult _apply(
  CanonicalGameSnapshot snapshot,
  DomainCommand command, {
  String actorPlayerId = _one,
  List<String> turnPlayerIds = const [_one, _two],
}) {
  return const GameEngine().apply(
    snapshot: snapshot,
    command: command,
    context: GameEngineContext(
      actorPlayerId: actorPlayerId,
      mapView: _map,
      ruleset: GameRuleset.defaults,
      commandTick: 7,
      turnPlayerIds: turnPlayerIds,
      requiredTurnSubmissionPlayerIds: turnPlayerIds,
      savedAt: _savedAt,
    ),
  );
}

GameEngineResult _applySystem(
  CanonicalGameSnapshot snapshot,
  SystemCommand command,
) {
  return const GameEngine().applySystem(
    snapshot: snapshot,
    command: command,
    context: GameEngineContext(
      actorPlayerId: 'server',
      mapView: _map,
      ruleset: GameRuleset.defaults,
      commandTick: 7,
      savedAt: _savedAt,
    ),
  );
}

GameEngineAccepted _accepted(GameEngineResult result) {
  expect(result, isA<GameEngineAccepted>());
  return result as GameEngineAccepted;
}

CanonicalGameSnapshot _snapshot({
  GameMode gameMode = GameMode.multiplayer,
  Set<String> submittedPlayerIds = const {},
  List<GameUnit> units = const [],
  List<Player> participants = const [
    Player(id: _one, name: 'One', colorValue: 1),
    Player(id: _two, name: 'Two', colorValue: 2),
  ],
  Map<String, PlayerTurnState>? turnStatesByPlayerId,
}) {
  return CanonicalGameSnapshot.snapshot(
    domain:
        (DomainState.snapshot(
          turn: 7,
          matchRules: MatchRules.standard,
          participants: participants,
          units: units,
        )).copyWith(
          gameMode: gameMode,
          turnStatesByPlayerId:
              turnStatesByPlayerId ??
              const {
                _one: PlayerTurnState.active,
                _two: PlayerTurnState.active,
              },
          submittedPlayerIds: submittedPlayerIds,
          turnStartedAt: DateTime.utc(2026, 7, 30, 11),
        ),
    metadata: GameSnapshotMetadata(
      id: 'turn',
      schemaVersion: 3,
      name: 'Turn',
      world: const WorldReference(name: 'turn', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 30, 11),
      camera: GameSnapshotCamera.zero,
    ),
  );
}

final _map = WorldMap(
  cols: 2,
  rows: 1,
  tiles: [
    WorldTile.at(
      coordinate: const HexCoord(col: 0, row: 0),
      terrains: const [TerrainType.grassland],
      resources: const [],
      height: 0,
    ),
    WorldTile.at(
      coordinate: const HexCoord(col: 1, row: 0),
      terrains: const [TerrainType.grassland],
      resources: const [],
      height: 0,
    ),
  ],
);
