import 'package:aonw_core/game/domain/artifact/cultural_victory_progress_resolver.dart';
import 'package:aonw_core/game/domain/artifact/world_artifact.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/match_rules/victory_rules.dart';
import 'package:aonw_core/game/domain/outcome/domination_progress_resolver.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

final class TurnVictoryProgressResult {
  TurnVictoryProgressResult({
    required Map<String, int> dominationHoldTurns,
    required Iterable<DominationThresholdReachedEvent> dominationEvents,
    required Map<String, int> culturalHoldTurns,
  }) : dominationHoldTurns = Map.unmodifiable(dominationHoldTurns),
       dominationEvents = List.unmodifiable(dominationEvents),
       culturalHoldTurns = Map.unmodifiable(culturalHoldTurns);

  final Map<String, int> dominationHoldTurns;
  final List<DominationThresholdReachedEvent> dominationEvents;
  final Map<String, int> culturalHoldTurns;
}

/// Advances post-turn victory holds without depending on a persistence model.
abstract final class TurnVictoryProgressResolver {
  static TurnVictoryProgressResult resolve({
    required Iterable<String> playerIds,
    required Iterable<GameCity> cities,
    required Iterable<WorldArtifact> artifacts,
    required Map<String, int> previousDominationHoldTurnsByPlayerId,
    required Map<String, int> previousCulturalHoldTurnsByPlayerId,
    required MapTileCatalog mapCatalog,
    required VictoryRules victoryRules,
  }) {
    final players = List<String>.unmodifiable(playerIds);
    final cityList = List<GameCity>.unmodifiable(cities);
    final artifactList = List<WorldArtifact>.unmodifiable(artifacts);
    const domination = DominationProgressResolver();
    final dominationHoldTurns = domination.advanceHoldTurns(
      playerIds: players,
      cities: cityList,
      mapCatalog: mapCatalog,
      victoryRules: victoryRules,
      previousHoldTurnsByPlayerId: previousDominationHoldTurnsByPlayerId,
    );
    final dominationEvents = domination.thresholdReachedEvents(
      playerIds: players,
      cities: cityList,
      mapCatalog: mapCatalog,
      victoryRules: victoryRules,
      previousHoldTurnsByPlayerId: previousDominationHoldTurnsByPlayerId,
      nextHoldTurnsByPlayerId: dominationHoldTurns,
    );
    final culturalHoldTurns = victoryRules.culturalEnabled
        ? const CulturalVictoryProgressResolver().advanceHoldTurns(
            playerIds: players,
            artifacts: artifactList,
            cities: cityList,
            previousHoldTurnsByPlayerId: previousCulturalHoldTurnsByPlayerId,
            requiredArtifactCount: victoryRules.culturalRequiredArtifacts,
          )
        : previousCulturalHoldTurnsByPlayerId;
    return TurnVictoryProgressResult(
      dominationHoldTurns: dominationHoldTurns,
      dominationEvents: dominationEvents,
      culturalHoldTurns: culturalHoldTurns,
    );
  }
}
