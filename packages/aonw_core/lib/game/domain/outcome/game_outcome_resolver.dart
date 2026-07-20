import 'package:aonw_core/game/domain/artifact/cultural_victory_progress_resolver.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/match_rules/match_rules.dart';
import 'package:aonw_core/game/domain/objective/map_objective.dart';
import 'package:aonw_core/game/domain/outcome/domination_progress_resolver.dart';
import 'package:aonw_core/game/domain/outcome/empire_score_calculator.dart';
import 'package:aonw_core/game/domain/outcome/game_outcome.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Resolves a match outcome from persistence-free domain collections.
final class GameOutcomeResolver {
  const GameOutcomeResolver({
    this.scoreCalculator = const EmpireScoreCalculator(),
  });

  final EmpireScoreCalculator scoreCalculator;

  GameOutcome resolve({
    required Iterable<String> playerIds,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
    required Iterable<WorldArtifact> artifacts,
    required Iterable<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required Map<String, int> playerGold,
    required Map<String, int> dominationHoldTurnsByPlayerId,
    required Map<String, int> culturalVictoryHoldTurnsByPlayerId,
    required Map<String, MapObjectiveHoldState>
    mapObjectiveHoldStatesByObjectiveId,
    required MatchRules matchRules,
    MapReadView? mapData,
    int? turn,
  }) {
    final players = _cleanPlayerIds(playerIds);
    if (players.length <= 1) return GameOutcome.ongoing;

    final unitList = _stableList(units);
    final cityList = _stableList(cities);
    final alivePlayers = alivePlayerIds(
      playerIds: players,
      units: unitList,
      cities: cityList,
    );

    if (matchRules.victory.conquestEnabled && alivePlayers.length == 1) {
      return GameOutcome.conquest(alivePlayers.single);
    }

    return _resolveNonConquest(
      alivePlayers: alivePlayers,
      scorePlayers: players,
      units: unitList,
      cities: cityList,
      artifacts: _stableList(artifacts),
      fieldImprovements: _stableList(fieldImprovements),
      research: research,
      playerGold: playerGold,
      dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId: culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId: mapObjectiveHoldStatesByObjectiveId,
      matchRules: matchRules,
      mapData: mapData,
      turn: turn,
    );
  }

  GameOutcome _resolveNonConquest({
    required Set<String> alivePlayers,
    required Set<String> scorePlayers,
    required List<GameUnit> units,
    required List<GameCity> cities,
    required List<WorldArtifact> artifacts,
    required List<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required Map<String, int> playerGold,
    required Map<String, int> dominationHoldTurnsByPlayerId,
    required Map<String, int> culturalVictoryHoldTurnsByPlayerId,
    required Map<String, MapObjectiveHoldState>
    mapObjectiveHoldStatesByObjectiveId,
    required MatchRules matchRules,
    required MapReadView? mapData,
    required int? turn,
  }) {
    final dominationOutcome = _dominationOutcome(
      players: alivePlayers,
      cities: cities,
      matchRules: matchRules,
      mapData: mapData,
      dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
    );
    if (dominationOutcome != null) return dominationOutcome;

    final culturalOutcome = _culturalOutcome(
      players: alivePlayers,
      cities: cities,
      artifacts: artifacts,
      matchRules: matchRules,
      culturalVictoryHoldTurnsByPlayerId: culturalVictoryHoldTurnsByPlayerId,
    );
    if (culturalOutcome != null) return culturalOutcome;

    final cappedOutcome = _turnCapOutcome(
      players: scorePlayers,
      cities: cities,
      units: units,
      fieldImprovements: fieldImprovements,
      research: research,
      playerGold: playerGold,
      matchRules: matchRules,
      mapData: mapData,
      mapObjectiveHoldStatesByObjectiveId: mapObjectiveHoldStatesByObjectiveId,
      turn: turn,
    );
    if (cappedOutcome != null) return cappedOutcome;

    return GameOutcome.ongoing;
  }

  Set<String> alivePlayerIds({
    required Iterable<String> playerIds,
    required Iterable<GameUnit> units,
    required Iterable<GameCity> cities,
  }) {
    final players = _cleanPlayerIds(playerIds);
    return {
      for (final unit in units)
        if (players.contains(unit.ownerPlayerId)) unit.ownerPlayerId,
      for (final city in cities)
        if (players.contains(city.ownerPlayerId)) city.ownerPlayerId,
    };
  }

  GameOutcome? _culturalOutcome({
    required Set<String> players,
    required Iterable<GameCity> cities,
    required Iterable<WorldArtifact> artifacts,
    required MatchRules matchRules,
    required Map<String, int> culturalVictoryHoldTurnsByPlayerId,
  }) {
    final rules = matchRules.victory;
    if (!rules.culturalEnabled) return null;
    final winner = const CulturalVictoryProgressResolver().winnerCandidate(
      playerIds: players,
      artifacts: artifacts,
      cities: cities,
      holdTurnsByPlayerId: culturalVictoryHoldTurnsByPlayerId,
      requiredArtifactCount: rules.culturalRequiredArtifacts,
      requiredHoldTurns: rules.culturalHoldTurns,
    );
    if (winner == null) return null;
    return GameOutcome.cultural(winner);
  }

  GameOutcome? _dominationOutcome({
    required Set<String> players,
    required Iterable<GameCity> cities,
    required MatchRules matchRules,
    required MapReadView? mapData,
    required Map<String, int> dominationHoldTurnsByPlayerId,
  }) {
    final rules = matchRules.victory;
    if (!rules.dominationEnabled) return null;

    final winner = mapData == null
        ? _runtimeDominationWinner(
            players: players,
            requiredHoldTurns: rules.dominationHoldTurns,
            holdTurnsByPlayerId: dominationHoldTurnsByPlayerId,
          )
        : const DominationProgressResolver()
              .snapshot(
                playerIds: players,
                cities: cities,
                mapCatalog: mapData,
                victoryRules: rules,
                holdTurnsByPlayerId: dominationHoldTurnsByPlayerId,
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
    required Iterable<GameCity> cities,
    required Iterable<GameUnit> units,
    required Iterable<FieldImprovement> fieldImprovements,
    required ResearchState research,
    required Map<String, int> playerGold,
    required MatchRules matchRules,
    required MapReadView? mapData,
    required Map<String, MapObjectiveHoldState>
    mapObjectiveHoldStatesByObjectiveId,
    required int? turn,
  }) {
    final rules = matchRules.victory;
    final turnLimit = rules.turnLimit;
    if (!rules.scoreFallbackEnabled || turnLimit == null) return null;
    if (turn == null || turn < turnLimit) return null;

    final scores = scoreCalculator.scoresForCollections(
      playerIds: players,
      cities: cities,
      units: units,
      fieldImprovements: fieldImprovements,
      research: research,
      playerGold: playerGold,
      mapObjectives: mapData?.objectives ?? const [],
      mapObjectiveHoldStatesByObjectiveId: mapObjectiveHoldStatesByObjectiveId,
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

Set<String> _cleanPlayerIds(Iterable<String> playerIds) {
  return {
    for (final playerId in playerIds)
      if (playerId.isNotEmpty) playerId,
  };
}

List<T> _stableList<T>(Iterable<T> values) {
  return values is List<T> ? values : List<T>.unmodifiable(values);
}
