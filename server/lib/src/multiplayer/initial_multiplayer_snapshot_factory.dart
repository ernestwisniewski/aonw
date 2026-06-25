import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

class InitialMultiplayerSnapshotFactory {
  const InitialMultiplayerSnapshotFactory({
    MultiplayerMapCatalog mapCatalog = const FileMultiplayerMapCatalog(),
  }) : _mapCatalog = mapCatalog;

  final MultiplayerMapCatalog _mapCatalog;

  Future<WireSnapshot> create({
    required WireMatch match,
    required DateTime startedAt,
  }) async {
    final players = match.players.map(_domainPlayer).toList();
    final mapData = await _mapCatalog.loadAssetMap(match.mapName);
    mapData.mapName ??= match.mapName;
    final startPositionSeed = StartingPositionSeed.fromParts([
      startedAt,
      match.id,
      match.mapName,
      players.length,
      for (final player in players) player.id,
    ]);
    final units = StartingUnits.unitsForPlayers(
      players,
      mapData: mapData,
      startPositionSeed: startPositionSeed,
    );
    final artifacts = WorldArtifactGenerator.generate(
      mapData: mapData,
      startingUnits: units,
      seed: startPositionSeed,
    );
    final playerIds = players.map((player) => player.id);
    final fogOfWar = const FogOfWarService().recompute(
      current: FogOfWarState.empty,
      mapData: mapData,
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
      name: match.name,
      mapName: match.mapName,
      mapSource: MapSource.asset,
      turn: 1,
      playerStates: {
        for (final player in players) player.id: PlayerTurnState.active,
      },
      savedAt: startedAt,
      camera: CameraState.zero,
      matchRules: MatchRules.standard,
      players: players,
      gameMode: GameMode.multiplayer,
    );
    final state = PersistentGameState(
      playerColors: {
        for (final player in players) player.id: player.colorValue,
      },
      playerCountries: {
        for (final player in players) player.id: player.country,
      },
      units: units,
      artifacts: artifacts,
      fogOfWar: fogOfWar,
      runtimeState: GameRuntimeState(diplomacy: diplomacy),
    );
    return WireSnapshot(
      matchId: match.id,
      offset: 0,
      save: save.toJson(),
      state: state.toJson(),
    );
  }

  Player _domainPlayer(WirePlayer player) {
    return Player(
      id: player.id,
      name: player.name,
      colorValue: player.colorValue,
      country: player.country,
      kind: switch (player.kind) {
        WirePlayerKind.human => PlayerKind.human,
        WirePlayerKind.ai => PlayerKind.ai,
      },
      ai: player.ai == null
          ? null
          : AiPlayer(
              strategyId: player.ai!.strategyId,
              difficulty: player.ai!.difficulty,
              persona: player.ai!.persona,
              seed: StartingPositionSeed.fromParts([
                player.id,
                player.name,
                player.country.name,
              ]),
            ),
    );
  }
}

abstract interface class MultiplayerMapCatalog {
  Future<MapData> loadAssetMap(String mapName);
}

class FileMultiplayerMapCatalog implements MultiplayerMapCatalog {
  const FileMultiplayerMapCatalog({List<String>? roots}) : _roots = roots;

  final List<String>? _roots;

  @override
  Future<MapData> loadAssetMap(String mapName) async {
    final safeName = _safeMapName(mapName);
    final roots = _roots ?? const ['assets/maps', '../assets/maps'];
    for (final root in roots) {
      final file = File('$root/$safeName/map.json');
      if (await file.exists()) {
        return MapDataCodec.fromJson(await file.readAsString());
      }
    }
    throw StateError('Map asset not found: $safeName');
  }

  String _safeMapName(String mapName) {
    final trimmed = mapName.trim();
    if (trimmed.isEmpty ||
        trimmed.contains('/') ||
        trimmed.contains(r'\') ||
        trimmed.contains('..')) {
      throw ArgumentError.value(mapName, 'mapName', 'Invalid map asset name');
    }
    return trimmed;
  }
}
