import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact_type.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/state.dart';

class CulturalVictoryProgress {
  final String playerId;
  final int storedArtifactCount;
  final int holdTurns;
  final int requiredArtifactCount;
  final int requiredHoldTurns;

  const CulturalVictoryProgress({
    required this.playerId,
    required this.storedArtifactCount,
    required this.holdTurns,
    required this.requiredArtifactCount,
    required this.requiredHoldTurns,
  });

  bool get hasFullCollection => storedArtifactCount >= requiredArtifactCount;
  bool get victoryReady => hasFullCollection && holdTurns >= requiredHoldTurns;
  int get remainingHoldTurns {
    final remaining = requiredHoldTurns - holdTurns;
    return remaining < 0 ? 0 : remaining;
  }
}

abstract final class CulturalVictoryProgressCalculator {
  static const int requiredStoredArtifactCount = 6;
  static const int requiredHoldTurns = 5;

  static int storedArtifactCountFor({
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

  static bool hasFullStoredCollection({
    required String playerId,
    required PersistentGameState state,
    int requiredArtifactCount = requiredStoredArtifactCount,
  }) {
    return storedArtifactCountFor(
          playerId: playerId,
          artifacts: state.artifacts,
          cities: state.cities,
        ) >=
        requiredArtifactCount;
  }

  static Map<String, int> advanceHoldTurns({
    required Iterable<String> playerIds,
    required PersistentGameState state,
    required Map<String, int> previousHoldTurnsByPlayerId,
    int requiredArtifactCount = requiredStoredArtifactCount,
  }) {
    final next = <String, int>{};
    for (final playerId in {
      for (final id in playerIds)
        if (id.isNotEmpty) id,
    }) {
      if (hasFullStoredCollection(
        playerId: playerId,
        state: state,
        requiredArtifactCount: requiredArtifactCount,
      )) {
        next[playerId] = (previousHoldTurnsByPlayerId[playerId] ?? 0) + 1;
      }
    }
    return Map.unmodifiable(next);
  }

  static CulturalVictoryProgress progressForPlayer({
    required String playerId,
    required PersistentGameState state,
    int requiredArtifactCount = requiredStoredArtifactCount,
    int requiredHoldTurns = CulturalVictoryProgressCalculator.requiredHoldTurns,
  }) {
    return CulturalVictoryProgress(
      playerId: playerId,
      storedArtifactCount: storedArtifactCountFor(
        playerId: playerId,
        artifacts: state.artifacts,
        cities: state.cities,
      ),
      holdTurns:
          state.runtimeState.culturalVictoryHoldTurnsByPlayerId[playerId] ?? 0,
      requiredArtifactCount: requiredArtifactCount,
      requiredHoldTurns: requiredHoldTurns,
    );
  }

  static String? winnerCandidate({
    required Iterable<String> playerIds,
    required PersistentGameState state,
    int requiredArtifactCount = requiredStoredArtifactCount,
    int requiredHoldTurns = CulturalVictoryProgressCalculator.requiredHoldTurns,
  }) {
    final candidates = <MapEntry<String, int>>[];
    for (final playerId in playerIds) {
      if (playerId.isEmpty) continue;
      if (!hasFullStoredCollection(
        playerId: playerId,
        state: state,
        requiredArtifactCount: requiredArtifactCount,
      )) {
        continue;
      }
      final holdTurns =
          state.runtimeState.culturalVictoryHoldTurnsByPlayerId[playerId] ?? 0;
      if (holdTurns >= requiredHoldTurns) {
        candidates.add(MapEntry(playerId, holdTurns));
      }
    }
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
}
