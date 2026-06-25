import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/widgets/multiplayer/multiplayer_avatar_models.dart';

class MultiplayerStatusSheetData {
  const MultiplayerStatusSheetData({
    required this.players,
    required this.hasEmpireStats,
  });

  final List<MultiplayerPlayerStats> players;
  final bool hasEmpireStats;

  int get totalCities =>
      players.fold(0, (total, player) => total + (player.cityCount ?? 0));

  int get totalUnits =>
      players.fold(0, (total, player) => total + (player.unitCount ?? 0));

  int get totalPopulation =>
      players.fold(0, (total, player) => total + (player.population ?? 0));

  int get totalStoredArtifacts => players.fold(
    0,
    (total, player) => total + (player.storedArtifactCount ?? 0),
  );

  static MultiplayerStatusSheetData from({
    required List<MultiplayerAvatarTileData> tiles,
    GameState? gameState,
  }) {
    final cityCounts = <String, int>{};
    final populations = <String, int>{};
    final unitCounts = <String, int>{};
    final storedArtifactCounts = <String, int>{};
    final scopedStatsPlayerId = gameState == null
        ? null
        : _scopedStatsPlayerId(tiles: tiles, gameState: gameState);

    if (gameState != null) {
      for (final city in gameState.cities) {
        cityCounts.update(
          city.ownerPlayerId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        populations.update(
          city.ownerPlayerId,
          (value) => value + city.population,
          ifAbsent: () => city.population,
        );
      }

      for (final unit in gameState.units) {
        unitCounts.update(
          unit.ownerPlayerId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      final cityOwners = {
        for (final city in gameState.cities) city.id: city.ownerPlayerId,
      };
      for (final artifact in gameState.artifacts) {
        final location = artifact.location;
        if (!location.isStored || location.cityId == null) continue;
        final ownerPlayerId = cityOwners[location.cityId!];
        if (ownerPlayerId == null) continue;
        storedArtifactCounts.update(
          ownerPlayerId,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return MultiplayerStatusSheetData(
      hasEmpireStats: gameState != null,
      players: [
        for (final tile in tiles) ...[
          if (scopedStatsPlayerId != null &&
              tile.player.id != scopedStatsPlayerId)
            MultiplayerPlayerStats.unknown(tile: tile)
          else
            MultiplayerPlayerStats(
              tile: tile,
              cityCount: cityCounts[tile.player.id] ?? 0,
              unitCount: unitCounts[tile.player.id] ?? 0,
              population: populations[tile.player.id] ?? 0,
              storedArtifactCount: storedArtifactCounts[tile.player.id] ?? 0,
            ),
        ],
      ],
    );
  }

  static String? _scopedStatsPlayerId({
    required List<MultiplayerAvatarTileData> tiles,
    required GameState gameState,
  }) {
    if (tiles.length <= 1) return null;
    final fogPlayerIds = gameState.fogOfWar.playerIds.toList();
    if (fogPlayerIds.length != 1) return null;
    return fogPlayerIds.single;
  }
}

class MultiplayerPlayerStats {
  const MultiplayerPlayerStats({
    required this.tile,
    required this.cityCount,
    required this.unitCount,
    required this.population,
    required this.storedArtifactCount,
  });

  const MultiplayerPlayerStats.unknown({required this.tile})
    : cityCount = null,
      unitCount = null,
      population = null,
      storedArtifactCount = null;

  final MultiplayerAvatarTileData tile;
  final int? cityCount;
  final int? unitCount;
  final int? population;
  final int? storedArtifactCount;
}
