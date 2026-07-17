import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact_type.dart';
import 'package:aonw_core/game/domain/city.dart';

final class CulturalVictoryProgress {
  const CulturalVictoryProgress({
    required this.playerId,
    required this.storedArtifactCount,
    required this.holdTurns,
    required this.requiredArtifactCount,
    required this.requiredHoldTurns,
  });

  final String playerId;
  final int storedArtifactCount;
  final int holdTurns;
  final int requiredArtifactCount;
  final int requiredHoldTurns;

  bool get hasFullCollection => storedArtifactCount >= requiredArtifactCount;
  bool get victoryReady => hasFullCollection && holdTurns >= requiredHoldTurns;

  int get remainingHoldTurns {
    final remaining = requiredHoldTurns - holdTurns;
    return remaining < 0 ? 0 : remaining;
  }
}

/// Calculates cultural progress from persistence-free domain collections.
final class CulturalVictoryProgressResolver {
  const CulturalVictoryProgressResolver();

  static const int requiredStoredArtifactCount = 6;
  static const int requiredHoldTurns = 5;

  int storedArtifactCountFor({
    required String playerId,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<GameCity> cities,
  }) {
    final ownedCityIds = {
      for (final city in cities)
        if (city.ownerPlayerId == playerId) city.id,
    };
    final storedTypes = <WorldArtifactType>{};
    for (final artifact in artifacts) {
      final location = artifact.location;
      if (!location.isStored) continue;
      final cityId = location.cityId;
      if (cityId == null || !ownedCityIds.contains(cityId)) continue;
      storedTypes.add(artifact.type);
    }
    return storedTypes.length;
  }

  bool hasFullStoredCollection({
    required String playerId,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<GameCity> cities,
    int requiredArtifactCount = requiredStoredArtifactCount,
  }) {
    return storedArtifactCountFor(
          playerId: playerId,
          artifacts: artifacts,
          cities: cities,
        ) >=
        requiredArtifactCount;
  }

  Map<String, int> advanceHoldTurns({
    required Iterable<String> playerIds,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<GameCity> cities,
    required Map<String, int> previousHoldTurnsByPlayerId,
    int requiredArtifactCount = requiredStoredArtifactCount,
  }) {
    final artifactList = List<WorldArtifact>.unmodifiable(artifacts);
    final cityList = List<GameCity>.unmodifiable(cities);
    final next = <String, int>{};
    for (final playerId in _cleanPlayerIds(playerIds)) {
      if (!hasFullStoredCollection(
        playerId: playerId,
        artifacts: artifactList,
        cities: cityList,
        requiredArtifactCount: requiredArtifactCount,
      )) {
        continue;
      }
      next[playerId] = (previousHoldTurnsByPlayerId[playerId] ?? 0) + 1;
    }
    return Map.unmodifiable(next);
  }

  CulturalVictoryProgress progressForPlayer({
    required String playerId,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<GameCity> cities,
    required Map<String, int> holdTurnsByPlayerId,
    int requiredArtifactCount = requiredStoredArtifactCount,
    int requiredHoldTurns = CulturalVictoryProgressResolver.requiredHoldTurns,
  }) {
    return CulturalVictoryProgress(
      playerId: playerId,
      storedArtifactCount: storedArtifactCountFor(
        playerId: playerId,
        artifacts: artifacts,
        cities: cities,
      ),
      holdTurns: holdTurnsByPlayerId[playerId] ?? 0,
      requiredArtifactCount: requiredArtifactCount,
      requiredHoldTurns: requiredHoldTurns,
    );
  }

  String? winnerCandidate({
    required Iterable<String> playerIds,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<GameCity> cities,
    required Map<String, int> holdTurnsByPlayerId,
    int requiredArtifactCount = requiredStoredArtifactCount,
    int requiredHoldTurns = CulturalVictoryProgressResolver.requiredHoldTurns,
  }) {
    final artifactList = List<WorldArtifact>.unmodifiable(artifacts);
    final cityList = List<GameCity>.unmodifiable(cities);
    final candidates = <MapEntry<String, int>>[];
    for (final playerId in playerIds) {
      if (playerId.isEmpty ||
          !hasFullStoredCollection(
            playerId: playerId,
            artifacts: artifactList,
            cities: cityList,
            requiredArtifactCount: requiredArtifactCount,
          )) {
        continue;
      }
      final holdTurns = holdTurnsByPlayerId[playerId] ?? 0;
      if (holdTurns >= requiredHoldTurns) {
        candidates.add(MapEntry(playerId, holdTurns));
      }
    }
    return _winnerFrom(candidates);
  }
}

Set<String> _cleanPlayerIds(Iterable<String> playerIds) {
  return {
    for (final playerId in playerIds)
      if (playerId.isNotEmpty) playerId,
  };
}

String? _winnerFrom(List<MapEntry<String, int>> candidates) {
  if (candidates.isEmpty) return null;
  candidates.sort((left, right) {
    final hold = right.value.compareTo(left.value);
    if (hold != 0) return hold;
    return left.key.compareTo(right.key);
  });
  if (candidates.length > 1 && candidates[0].value == candidates[1].value) {
    return null;
  }
  return candidates.first.key;
}
