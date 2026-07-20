import 'package:aonw_core/game/domain/match_rules/match_rules.dart';
import 'package:aonw_core/game/domain/outcome/empire_score_calculator.dart';
import 'package:aonw_core/game/domain/outcome/game_outcome.dart';
import 'package:aonw_core/game/domain/outcome/game_outcome_resolver.dart';
import 'package:aonw_core/game/domain/state/domain_state.dart';
import 'package:aonw_core/game/domain/state/match_session_state.dart';
import 'package:aonw_core/game/domain/state/persistent_game_state.dart';
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
    required PersistentGameState state,
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
      dominationHoldTurnsByPlayerId:
          state.runtimeState.dominationHoldTurnsByPlayerId,
      culturalVictoryHoldTurnsByPlayerId:
          state.runtimeState.culturalVictoryHoldTurnsByPlayerId,
      mapObjectiveHoldStatesByObjectiveId:
          state.runtimeState.mapObjectiveHoldStatesByObjectiveId,
      matchRules: matchRules,
      mapData: mapData,
      turn: turn,
    );
  }

  GameOutcome evaluateCanonical({
    required DomainState state,
    required MatchSessionState session,
    MapReadView? mapData,
  }) {
    final activePlayerIds = [
      for (final participant in state.participants)
        if (!session.kickedPlayerIds.contains(participant.id)) participant.id,
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
    required PersistentGameState state,
  }) {
    return _resolver.alivePlayerIds(
      playerIds: playerIds,
      units: state.units,
      cities: state.cities,
    );
  }
}
