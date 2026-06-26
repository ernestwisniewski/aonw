import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_data.dart';

final class PressureTargetResolution {
  final Set<String> playerIds;
  final ScoreRaceAnalysis? scoreRace;

  PressureTargetResolution({
    required Iterable<String> playerIds,
    required this.scoreRace,
  }) : playerIds = Set.unmodifiable(playerIds);
}

final class PressureTargetResolver {
  final ScoreRaceAnalyzer scoreRaceAnalyzer;

  const PressureTargetResolver({
    this.scoreRaceAnalyzer = const ScoreRaceAnalyzer(),
  });

  PressureTargetResolution resolve({
    required Iterable<Player> players,
    required String playerId,
    required PersistentGameState state,
    required int turn,
    required MatchRules matchRules,
    required MapData mapData,
  }) {
    final diplomacy = state.runtimeState.diplomacy;
    final scoreRace = _scoreRaceFor(
      players: players,
      playerId: playerId,
      state: state,
      turn: turn,
      matchRules: matchRules,
      mapData: mapData,
    );

    return PressureTargetResolution(
      playerIds: {
        ..._humanPressureTargetPlayerIds(
          players,
          playerId: playerId,
          diplomacy: diplomacy,
        ),
        ..._culturalPressureTargetPlayerIds(
          state,
          playerId: playerId,
          matchRules: matchRules,
        ),
        ..._scorePressureTargetPlayerIds(
          scoreRace: scoreRace,
          playerId: playerId,
          diplomacy: diplomacy,
        ),
      },
      scoreRace: scoreRace,
    );
  }

  ScoreRaceAnalysis? _scoreRaceFor({
    required Iterable<Player> players,
    required String playerId,
    required PersistentGameState state,
    required int turn,
    required MatchRules matchRules,
    required MapData mapData,
  }) {
    final victory = matchRules.victory;
    return scoreRaceAnalyzer.analyzeForPlayer(
      playerId: playerId,
      playerIds: players.map((player) => player.id),
      state: state,
      turn: turn,
      turnLimit: victory.turnLimit,
      scoreFallbackEnabled: victory.scoreFallbackEnabled,
      mapData: mapData,
    );
  }

  Set<String> _humanPressureTargetPlayerIds(
    Iterable<Player> players, {
    required String playerId,
    required DiplomacyState diplomacy,
  }) {
    return {
      for (final player in players)
        if (_shouldPressureHumanPlayer(
          player: player,
          playerId: playerId,
          diplomacy: diplomacy,
        ))
          player.id,
    };
  }

  Set<String> _scorePressureTargetPlayerIds({
    required ScoreRaceAnalysis? scoreRace,
    required String playerId,
    required DiplomacyState diplomacy,
  }) {
    final targetIds = scoreRace?.pressureTargetPlayerIds() ?? const {};
    return {
      for (final targetId in targetIds)
        if (_canPressureScoreTarget(
          targetId: targetId,
          playerId: playerId,
          diplomacy: diplomacy,
        ))
          targetId,
    };
  }

  bool _canPressureScoreTarget({
    required String targetId,
    required String playerId,
    required DiplomacyState diplomacy,
  }) {
    if (targetId.isEmpty || targetId == playerId) return false;
    final status = diplomacy.statusBetween(playerId, targetId);
    if (status == DiplomaticRelationStatus.friendly ||
        status == DiplomaticRelationStatus.truce) {
      return false;
    }
    final relationKey = DiplomacyState.relationKey(playerId, targetId);
    if (status == DiplomaticRelationStatus.neutral &&
        relationKey.isNotEmpty &&
        diplomacy.relations.containsKey(relationKey)) {
      return false;
    }
    return true;
  }

  Set<String> _culturalPressureTargetPlayerIds(
    PersistentGameState state, {
    required String playerId,
    required MatchRules matchRules,
  }) {
    if (!matchRules.victory.culturalEnabled) return const {};
    final threshold = _culturalPressureArtifactThreshold(
      matchRules.victory.culturalRequiredArtifacts,
    );
    final cityOwnerById = {
      for (final city in state.cities) city.id: city.ownerPlayerId,
    };
    final typesByPlayerId = <String, Set<WorldArtifactType>>{};
    for (final artifact in state.artifacts) {
      final cityId = artifact.location.cityId;
      if (!artifact.location.isStored || cityId == null) continue;
      final ownerPlayerId = cityOwnerById[cityId];
      if (ownerPlayerId == null || ownerPlayerId == playerId) continue;
      typesByPlayerId.putIfAbsent(ownerPlayerId, () => {}).add(artifact.type);
    }
    return {
      for (final entry in typesByPlayerId.entries)
        if (entry.value.length >= threshold) entry.key,
    };
  }

  int _culturalPressureArtifactThreshold(int requiredArtifactCount) {
    final threshold = requiredArtifactCount - 2;
    if (threshold < 1) return 1;
    return threshold;
  }

  bool _shouldPressureHumanPlayer({
    required Player player,
    required String playerId,
    required DiplomacyState diplomacy,
  }) {
    if (player.id == playerId || player.kind != PlayerKind.human) {
      return false;
    }

    final status = diplomacy.statusBetween(playerId, player.id);
    if (status == DiplomaticRelationStatus.hostile ||
        status == DiplomaticRelationStatus.war) {
      return true;
    }
    if (status == DiplomaticRelationStatus.friendly ||
        status == DiplomaticRelationStatus.truce) {
      return false;
    }

    final relationKey = DiplomacyState.relationKey(playerId, player.id);
    return relationKey.isNotEmpty &&
        !diplomacy.relations.containsKey(relationKey);
  }
}
