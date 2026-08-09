import 'package:aonw_core/domain.dart';

import 'package:aonw_server/src/multiplayer/multiplayer_map_catalog.dart';

final class InitialMultiplayerSnapshotFactory {
  const InitialMultiplayerSnapshotFactory({
    MultiplayerMapCatalog mapCatalog = const FileMultiplayerMapCatalog(),
  }) : _mapCatalog = mapCatalog;

  final MultiplayerMapCatalog _mapCatalog;

  Future<CanonicalGameSnapshot> create({
    required String matchId,
    required String matchName,
    required String mapName,
    required List<Player> participants,
    required DateTime startedAt,
  }) async {
    final players = List<Player>.unmodifiable(participants);
    final mapData = await _mapCatalog.loadAssetMap(mapName);
    final resolvedMapName = mapData.mapName ?? mapName;
    final worldMap = mapData.copyWith(mapName: resolvedMapName);
    final startPositionSeed = StartingPositionSeed.fromParts([
      startedAt,
      matchId,
      mapName,
      players.length,
      for (final player in players) player.id,
    ]);
    final units = StartingUnits.unitsForPlayers(
      players,
      mapData: worldMap,
      startPositionSeed: startPositionSeed,
    );
    final artifacts = WorldArtifactGenerator.generate(
      mapData: worldMap,
      startingUnits: units,
      seed: startPositionSeed,
    );
    final playerIds = players.map((player) => player.id);
    final fogOfWar = const FogOfWarService().recompute(
      current: FogOfWarState.empty,
      mapData: worldMap,
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
    return CanonicalGameSnapshot.snapshot(
      domain: DomainState.snapshot(
        turn: 1,
        matchRules: MatchRules.standard,
        participants: players,
        units: units,
        artifacts: artifacts,
        fogOfWar: fogOfWar,
        diplomacy: diplomacy,
        gameMode: GameMode.multiplayer,
        turnStatesByPlayerId: {
          for (final player in players) player.id: PlayerTurnState.active,
        },
        turnStartedAt: startedAt,
      ),
      metadata: GameSnapshotMetadata(
        id: matchId,
        schemaVersion: gameSaveCurrentSchemaVersion,
        name: MultiplayerSaveName.fromMatchName(matchName),
        world: WorldReference(name: mapName, source: MapSource.asset),
        savedAtUtc: startedAt,
        camera: GameSnapshotCamera.zero,
        origin: GameSaveOrigin.network,
      ),
    );
  }
}
