import 'package:aonw_core/domain/world_map.dart';

class MapPlayerCapacity {
  const MapPlayerCapacity({
    required this.mapName,
    required this.maxPlayers,
    int? singlePlayerPlayers,
  }) : singlePlayerPlayers = singlePlayerPlayers ?? maxPlayers;

  final String mapName;
  final int maxPlayers;
  final int singlePlayerPlayers;
}

abstract final class MapPlayerCapacityRules {
  static const int minPlayers = 2;
  static const int absoluteMaxPlayers = 4;

  /// Canonical placeholder while every player shares one quickplay queue.
  /// The actual start map is selected only after the player count is known.
  static const String quickplayLobbyMapName = 'verdantia';

  static const official = <MapPlayerCapacity>[
    MapPlayerCapacity(mapName: 'verdantia', maxPlayers: 4),
    MapPlayerCapacity(mapName: 'myranth', maxPlayers: 3),
    MapPlayerCapacity(mapName: 'terenos', maxPlayers: 3),
    MapPlayerCapacity(mapName: 'dravonia', maxPlayers: 4),
  ];

  static int maxPlayersForWorldMap(WorldMap mapData) {
    return maxPlayersForMap(
      mapName: mapData.mapName,
      tileCount: mapData.tileCount,
    );
  }

  static int singlePlayerPlayersForWorldMap(WorldMap mapData) {
    return singlePlayerPlayersForMap(
      mapName: mapData.mapName,
      tileCount: mapData.tileCount,
    );
  }

  static int maxPlayersForMap({
    required String? mapName,
    required int tileCount,
  }) {
    final profile = profileForMapName(mapName);
    if (profile != null) return profile.maxPlayers;
    return maxPlayersForTileCount(tileCount);
  }

  static int singlePlayerPlayersForMap({
    required String? mapName,
    required int tileCount,
  }) {
    final profile = profileForMapName(mapName);
    if (profile != null) return profile.singlePlayerPlayers;
    return maxPlayersForTileCount(tileCount);
  }

  static int maxPlayersForMapName(String? mapName) {
    return profileForMapName(mapName)?.maxPlayers ?? absoluteMaxPlayers;
  }

  static int singlePlayerPlayersForMapName(String? mapName) {
    return profileForMapName(mapName)?.singlePlayerPlayers ??
        absoluteMaxPlayers;
  }

  static int aiOpponentsForPlayerCount(int playerCount) {
    return playerCount <= 1 ? 0 : playerCount - 1;
  }

  static bool supportsPlayerCount({
    required String? mapName,
    required int playerCount,
  }) {
    return playerCount >= minPlayers &&
        playerCount <= maxPlayersForMapName(mapName);
  }

  /// Selects a quickplay start map using the stable official order and seed.
  static String multiplayerStartMapName({
    required int playerCount,
    required int seed,
  }) {
    if (playerCount < minPlayers) {
      throw RangeError.range(playerCount, minPlayers, null, 'playerCount');
    }
    final candidates = [
      for (final profile in official)
        if (profile.maxPlayers >= playerCount) profile.mapName,
    ];
    if (candidates.isEmpty) {
      throw StateError(
        'No official multiplayer map supports $playerCount players.',
      );
    }

    final index = seed.abs() % candidates.length;
    return candidates[index];
  }

  static MapPlayerCapacity? profileForMapName(String? mapName) {
    final normalized = _normalize(mapName);
    if (normalized == null) return null;
    for (final profile in official) {
      if (profile.mapName == normalized) return profile;
    }
    return null;
  }

  static int maxPlayersForTileCount(int tileCount) {
    if (tileCount >= 540) return 4;
    if (tileCount >= 220) return 3;
    return 2;
  }

  static String? _normalize(String? mapName) {
    final normalized = mapName?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
