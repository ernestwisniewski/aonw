import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/match_rules/match_rules.dart';
import 'package:aonw_core/game/domain/objective/map_objective.dart';
import 'package:aonw_core/game/domain/outcome/empire_score_calculator.dart';
import 'package:aonw_core/game/domain/outcome/game_outcome.dart';
import 'package:aonw_core/game/domain/outcome/game_outcome_resolver.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Compatibility facade for callers that still own legacy or aggregate state.
class GameOutcomeDetector {
  const GameOutcomeDetector({
    this.scoreCalculator = const EmpireScoreCalculator(),
  });

  final EmpireScoreCalculator scoreCalculator;

  GameOutcomeResolver get _resolver =>
      GameOutcomeResolver(scoreCalculator: scoreCalculator);

  GameOutcome evaluate({
    required Iterable<String> playerIds,
    required DomainState state,
    MatchRules matchRules = MatchRules.standard,
    MapReadView? mapData,
    int? turn,
  }) {
    return _resolver.resolve(
      playerIds: playerIds,
      units: state.units,
      cities: state.cities,
      artifacts: state.artifacts,
      fieldImprovements: state.fieldImprovements,
      research: state.research,
      playerGold: state.playerGold,
      dominationHoldTurnsByPlayerId: state.dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId:
          state.culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId:
          state.mapObjectiveHoldStatesByObjectiveId,
      matchRules: matchRules,
      mapData: mapData,
      turn: turn,
    );
  }

  GameOutcome evaluateCollections({
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
    MatchRules matchRules = MatchRules.standard,
    MapReadView? mapData,
    int? turn,
  }) => _resolver.resolve(
    playerIds: playerIds,
    units: units,
    cities: cities,
    artifacts: artifacts,
    fieldImprovements: fieldImprovements,
    research: research,
    playerGold: playerGold,
    dominationHoldTurnsByPlayerId: dominationHoldTurnsByPlayerId,
    culturalVictoryHoldTurnsByPlayerId: culturalVictoryHoldTurnsByPlayerId,
    mapObjectiveHoldStatesByObjectiveId: mapObjectiveHoldStatesByObjectiveId,
    matchRules: matchRules,
    mapData: mapData,
    turn: turn,
  );

  GameOutcome evaluateCanonical({
    required DomainState state,
    MapReadView? mapData,
  }) {
    final activePlayerIds = [
      for (final participant in state.participants)
        if (!state.kickedPlayerIds.contains(participant.id)) participant.id,
    ];
    return _resolver.resolve(
      playerIds: activePlayerIds,
      units: state.units,
      cities: state.cities,
      artifacts: state.artifacts,
      fieldImprovements: state.fieldImprovements,
      research: state.research,
      playerGold: state.playerGold,
      dominationHoldTurnsByPlayerId: state.dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId:
          state.culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId:
          state.mapObjectiveHoldStatesByObjectiveId,
      matchRules: state.matchRules,
      mapData: mapData,
      turn: state.turn,
    );
  }

  Set<String> alivePlayerIds({
    required Iterable<String> playerIds,
    required DomainState state,
  }) {
    return _resolver.alivePlayerIds(
      playerIds: playerIds,
      units: state.units,
      cities: state.cities,
    );
  }
}
