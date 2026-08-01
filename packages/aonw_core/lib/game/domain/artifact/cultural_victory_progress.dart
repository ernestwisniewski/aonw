import 'package:aonw_core/game/domain/artifact/cultural_victory_progress_resolver.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/state.dart';

export 'cultural_victory_progress_resolver.dart';

/// Compatibility facade for callers that still own [DomainState].
abstract final class CulturalVictoryProgressCalculator {
  static const int requiredStoredArtifactCount =
      CulturalVictoryProgressResolver.requiredStoredArtifactCount;
  static const int requiredHoldTurns =
      CulturalVictoryProgressResolver.requiredHoldTurns;
  static const _resolver = CulturalVictoryProgressResolver();

  static int storedArtifactCountFor({
    required String playerId,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<GameCity> cities,
  }) => _resolver.storedArtifactCountFor(
    playerId: playerId,
    artifacts: artifacts,
    cities: cities,
  );

  static bool hasFullStoredCollection({
    required String playerId,
    required DomainState state,
    int requiredArtifactCount = requiredStoredArtifactCount,
  }) => hasFullStoredCollectionForArtifacts(
    playerId: playerId,
    artifacts: state.artifacts,
    cities: state.cities,
    requiredArtifactCount: requiredArtifactCount,
  );

  static bool hasFullStoredCollectionForArtifacts({
    required String playerId,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<GameCity> cities,
    int requiredArtifactCount = requiredStoredArtifactCount,
  }) => _resolver.hasFullStoredCollection(
    playerId: playerId,
    artifacts: artifacts,
    cities: cities,
    requiredArtifactCount: requiredArtifactCount,
  );

  static Map<String, int> advanceHoldTurns({
    required Iterable<String> playerIds,
    required DomainState state,
    required Map<String, int> previousHoldTurnsByPlayerId,
    int requiredArtifactCount = requiredStoredArtifactCount,
  }) => advanceHoldTurnsForArtifacts(
    playerIds: playerIds,
    artifacts: state.artifacts,
    cities: state.cities,
    previousHoldTurnsByPlayerId: previousHoldTurnsByPlayerId,
    requiredArtifactCount: requiredArtifactCount,
  );

  static Map<String, int> advanceHoldTurnsForArtifacts({
    required Iterable<String> playerIds,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<GameCity> cities,
    required Map<String, int> previousHoldTurnsByPlayerId,
    int requiredArtifactCount = requiredStoredArtifactCount,
  }) => _resolver.advanceHoldTurns(
    playerIds: playerIds,
    artifacts: artifacts,
    cities: cities,
    previousHoldTurnsByPlayerId: previousHoldTurnsByPlayerId,
    requiredArtifactCount: requiredArtifactCount,
  );

  static CulturalVictoryProgress progressForPlayer({
    required String playerId,
    required DomainState state,
    int requiredArtifactCount = requiredStoredArtifactCount,
    int requiredHoldTurns = CulturalVictoryProgressCalculator.requiredHoldTurns,
  }) => progressForPlayerFromCollections(
    playerId: playerId,
    artifacts: state.artifacts,
    cities: state.cities,
    holdTurnsByPlayerId: state.culturalVictoryHoldTurnsByPlayerId,
    requiredArtifactCount: requiredArtifactCount,
    requiredHoldTurns: requiredHoldTurns,
  );

  static CulturalVictoryProgress progressForPlayerFromCollections({
    required String playerId,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<GameCity> cities,
    required Map<String, int> holdTurnsByPlayerId,
    int requiredArtifactCount = requiredStoredArtifactCount,
    int requiredHoldTurns = CulturalVictoryProgressCalculator.requiredHoldTurns,
  }) => _resolver.progressForPlayer(
    playerId: playerId,
    artifacts: artifacts,
    cities: cities,
    holdTurnsByPlayerId: holdTurnsByPlayerId,
    requiredArtifactCount: requiredArtifactCount,
    requiredHoldTurns: requiredHoldTurns,
  );

  static String? winnerCandidate({
    required Iterable<String> playerIds,
    required DomainState state,
    int requiredArtifactCount = requiredStoredArtifactCount,
    int requiredHoldTurns = CulturalVictoryProgressCalculator.requiredHoldTurns,
  }) => winnerCandidateFromCollections(
    playerIds: playerIds,
    artifacts: state.artifacts,
    cities: state.cities,
    holdTurnsByPlayerId: state.culturalVictoryHoldTurnsByPlayerId,
    requiredArtifactCount: requiredArtifactCount,
    requiredHoldTurns: requiredHoldTurns,
  );

  static String? winnerCandidateFromCollections({
    required Iterable<String> playerIds,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<GameCity> cities,
    required Map<String, int> holdTurnsByPlayerId,
    int requiredArtifactCount = requiredStoredArtifactCount,
    int requiredHoldTurns = CulturalVictoryProgressCalculator.requiredHoldTurns,
  }) => _resolver.winnerCandidate(
    playerIds: playerIds,
    artifacts: artifacts,
    cities: cities,
    holdTurnsByPlayerId: holdTurnsByPlayerId,
    requiredArtifactCount: requiredArtifactCount,
    requiredHoldTurns: requiredHoldTurns,
  );
}
