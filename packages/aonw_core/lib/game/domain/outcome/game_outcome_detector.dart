import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/outcome/domination_progress_calculator.dart';
import 'package:aonw_core/game/domain/outcome/empire_score_calculator.dart';
import 'package:aonw_core/game/domain/outcome/game_outcome.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class GameOutcomeDetector {
  final EmpireScoreCalculator scoreCalculator;

  const GameOutcomeDetector({
    this.scoreCalculator = const EmpireScoreCalculator(),
  });

  GameOutcome evaluate({
    required Iterable<String> playerIds,
    required PersistentGameState state,
    MatchRules matchRules = MatchRules.standard,
    MapData? mapData,
    int? turn,
  }) {
    final players = {
      for (final id in playerIds)
        if (id.isNotEmpty) id,
    };
    if (players.length <= 1) return GameOutcome.ongoing;

    final alivePlayers = <String>{
      for (final unit in state.units)
        if (players.contains(unit.ownerPlayerId)) unit.ownerPlayerId,
      for (final city in state.cities)
        if (players.contains(city.ownerPlayerId)) city.ownerPlayerId,
    };

    if (matchRules.victory.conquestEnabled && alivePlayers.length == 1) {
      return GameOutcome.conquest(alivePlayers.single);
    }

    final dominationOutcome = _dominationOutcome(
      players: alivePlayers,
      state: state,
      matchRules: matchRules,
      mapData: mapData,
    );
    if (dominationOutcome != null) return dominationOutcome;

    final culturalOutcome = _culturalOutcome(
      players: alivePlayers,
      state: state,
      matchRules: matchRules,
    );
    if (culturalOutcome != null) return culturalOutcome;

    final cappedOutcome = _turnCapOutcome(
      players: players,
      state: state,
      matchRules: matchRules,
      mapData: mapData,
      turn: turn,
    );
    if (cappedOutcome != null) return cappedOutcome;

    return GameOutcome.ongoing;
  }

  GameOutcome? _culturalOutcome({
    required Set<String> players,
    required PersistentGameState state,
    required MatchRules matchRules,
  }) {
    final rules = matchRules.victory;
    if (!rules.culturalEnabled) return null;
    final winner = CulturalVictoryProgressCalculator.winnerCandidate(
      playerIds: players,
      state: state,
      requiredArtifactCount: rules.culturalRequiredArtifacts,
      requiredHoldTurns: rules.culturalHoldTurns,
    );
    if (winner == null) return null;
    return GameOutcome.cultural(winner);
  }

  GameOutcome? _dominationOutcome({
    required Set<String> players,
    required PersistentGameState state,
    required MatchRules matchRules,
    required MapData? mapData,
  }) {
    final rules = matchRules.victory;
    if (!rules.dominationEnabled) return null;

    final winner = mapData == null
        ? _runtimeDominationWinner(
            players: players,
            requiredHoldTurns: rules.dominationHoldTurns,
            holdTurnsByPlayerId:
                state.runtimeState.dominationHoldTurnsByPlayerId,
          )
        : const DominationProgressCalculator()
              .snapshot(
                playerIds: players,
                state: state,
                mapData: mapData,
                victoryRules: rules,
              )
              .winnerCandidate()
              ?.playerId;
    if (winner == null) return null;
    return GameOutcome.domination(winner);
  }

  String? _runtimeDominationWinner({
    required Set<String> players,
    required int requiredHoldTurns,
    required Map<String, int> holdTurnsByPlayerId,
  }) {
    final candidates = [
      for (final playerId in players)
        if ((holdTurnsByPlayerId[playerId] ?? 0) >= requiredHoldTurns)
          MapEntry(playerId, holdTurnsByPlayerId[playerId] ?? 0),
    ];
    if (candidates.isEmpty) return null;
    candidates.sort((left, right) {
      final holdCompare = right.value.compareTo(left.value);
      if (holdCompare != 0) return holdCompare;
      return left.key.compareTo(right.key);
    });
    if (candidates.length > 1 && candidates[0].value == candidates[1].value) {
      return null;
    }
    return candidates.first.key;
  }

  GameOutcome? _turnCapOutcome({
    required Set<String> players,
    required PersistentGameState state,
    required MatchRules matchRules,
    required MapData? mapData,
    required int? turn,
  }) {
    final rules = matchRules.victory;
    final turnLimit = rules.turnLimit;
    if (!rules.scoreFallbackEnabled || turnLimit == null) return null;
    if (turn == null || turn < turnLimit) return null;

    final scores = scoreCalculator.scoresFor(
      playerIds: players,
      state: state,
      mapObjectives: mapData?.objectives ?? const [],
    );
    if (scores.isEmpty) {
      return GameOutcome.draw(scoreByPlayerId: scores);
    }

    final sortedEntries = scores.entries.toList()
      ..sort((left, right) {
        final scoreCompare = right.value.compareTo(left.value);
        if (scoreCompare != 0) return scoreCompare;
        return left.key.compareTo(right.key);
      });
    final topScore = sortedEntries.first.value;
    final topPlayers = [
      for (final entry in sortedEntries)
        if (entry.value == topScore) entry.key,
    ];
    if (topPlayers.length != 1) {
      return GameOutcome.draw(scoreByPlayerId: scores);
    }
    return GameOutcome.score(
      winnerPlayerId: topPlayers.single,
      scoreByPlayerId: scores,
    );
  }
}
