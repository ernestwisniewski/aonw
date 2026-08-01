import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/outcome/domination_progress.dart';
import 'package:aonw_core/game/domain/outcome/domination_progress_resolver.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

export 'domination_progress.dart';
export 'domination_progress_resolver.dart';

/// Compatibility facade for callers that still own [DomainState].
final class DominationProgressCalculator {
  const DominationProgressCalculator();

  static const _resolver = DominationProgressResolver();

  DominationProgressSnapshot snapshot({
    required Iterable<String> playerIds,
    required DomainState state,
    required MapTileCatalog mapData,
    required VictoryRules victoryRules,
    Map<String, int>? holdTurnsByPlayerId,
  }) => snapshotForCities(
    playerIds: playerIds,
    cities: state.cities,
    mapData: mapData,
    victoryRules: victoryRules,
    holdTurnsByPlayerId:
        holdTurnsByPlayerId ?? state.dominationHoldTurnsByPlayerId,
  );

  DominationProgressSnapshot snapshotForCities({
    required Iterable<String> playerIds,
    required Iterable<GameCity> cities,
    required MapTileCatalog mapData,
    required VictoryRules victoryRules,
    Map<String, int> holdTurnsByPlayerId = const {},
  }) => _resolver.snapshot(
    playerIds: playerIds,
    cities: cities,
    mapCatalog: mapData,
    victoryRules: victoryRules,
    holdTurnsByPlayerId: holdTurnsByPlayerId,
  );

  Map<String, int> advanceHoldTurns({
    required Iterable<String> playerIds,
    required DomainState state,
    required MapTileCatalog mapData,
    required VictoryRules victoryRules,
    Map<String, int>? previousHoldTurnsByPlayerId,
  }) => advanceHoldTurnsForCities(
    playerIds: playerIds,
    cities: state.cities,
    mapData: mapData,
    victoryRules: victoryRules,
    previousHoldTurnsByPlayerId:
        previousHoldTurnsByPlayerId ?? state.dominationHoldTurnsByPlayerId,
  );

  Map<String, int> advanceHoldTurnsForCities({
    required Iterable<String> playerIds,
    required Iterable<GameCity> cities,
    required MapTileCatalog mapData,
    required VictoryRules victoryRules,
    Map<String, int> previousHoldTurnsByPlayerId = const {},
  }) => _resolver.advanceHoldTurns(
    playerIds: playerIds,
    cities: cities,
    mapCatalog: mapData,
    victoryRules: victoryRules,
    previousHoldTurnsByPlayerId: previousHoldTurnsByPlayerId,
  );

  List<DominationThresholdReachedEvent> thresholdReachedEvents({
    required Iterable<String> playerIds,
    required DomainState state,
    required MapTileCatalog mapData,
    required VictoryRules victoryRules,
    required Map<String, int> previousHoldTurnsByPlayerId,
    required Map<String, int> nextHoldTurnsByPlayerId,
  }) => thresholdReachedEventsForCities(
    playerIds: playerIds,
    cities: state.cities,
    mapData: mapData,
    victoryRules: victoryRules,
    previousHoldTurnsByPlayerId: previousHoldTurnsByPlayerId,
    nextHoldTurnsByPlayerId: nextHoldTurnsByPlayerId,
  );

  List<DominationThresholdReachedEvent> thresholdReachedEventsForCities({
    required Iterable<String> playerIds,
    required Iterable<GameCity> cities,
    required MapTileCatalog mapData,
    required VictoryRules victoryRules,
    required Map<String, int> previousHoldTurnsByPlayerId,
    required Map<String, int> nextHoldTurnsByPlayerId,
  }) => _resolver.thresholdReachedEvents(
    playerIds: playerIds,
    cities: cities,
    mapCatalog: mapData,
    victoryRules: victoryRules,
    previousHoldTurnsByPlayerId: previousHoldTurnsByPlayerId,
    nextHoldTurnsByPlayerId: nextHoldTurnsByPlayerId,
  );
}
