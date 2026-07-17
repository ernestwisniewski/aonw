import 'package:aonw_core/game/application/turn/canonical_turn_suffix.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/turn/domain_turn_combat_resolver.dart';
import 'package:aonw_core/game/domain/turn/persistent_turn_economy_processor.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Canonical input for simultaneous turn finalization.
final class CanonicalTurnPipelineRequest {
  CanonicalTurnPipelineRequest.simultaneousFinalize({
    required this.snapshot,
    required Iterable<String> playerIds,
    required this.savedAt,
    required this.mapView,
    this.ruleset = GameRuleset.defaults,
    this.fogOfWarService = const FogOfWarService(),
    Iterable<String> skippedPlayerIds = const [],
    this.preserveNonParticipantPlayerStates = false,
    this.trackTimeoutStreaks = false,
  }) : playerIds = List.unmodifiable(_orderedDistinctPlayerIds(playerIds)),
       skippedPlayerIds = List.unmodifiable(
         _orderedDistinctPlayerIds(skippedPlayerIds),
       );

  final CanonicalGameSnapshot snapshot;
  final List<String> playerIds;
  final DateTime savedAt;
  final MapReadView mapView;
  final GameRuleset ruleset;
  final FogOfWarService fogOfWarService;
  final List<String> skippedPlayerIds;
  final bool preserveNonParticipantPlayerStates;
  final bool trackTimeoutStreaks;
}

/// Renderer-neutral unit movement produced while finalizing a turn.
final class TurnMovementDelta {
  TurnMovementDelta({
    required Iterable<GameUnit> beforeUnits,
    required Iterable<GameUnit> afterUnits,
  }) : beforeUnits = List.unmodifiable(beforeUnits),
       afterUnits = List.unmodifiable(afterUnits);

  final List<GameUnit> beforeUnits;
  final List<GameUnit> afterUnits;
}

/// Canonical output of simultaneous turn finalization.
final class CanonicalTurnPipelineResult {
  CanonicalTurnPipelineResult({
    required this.snapshot,
    Iterable<GameEvent> events = const [],
    this.movementDelta,
  }) : events = List.unmodifiable(events);

  final CanonicalGameSnapshot snapshot;
  final List<GameEvent> events;
  final TurnMovementDelta? movementDelta;
}

/// Canonical application facade over the temporary persistent turn kernel.
abstract final class CanonicalTurnPipeline {
  static const _snapshotAdapter = LegacyGameSnapshotAdapter();

  static CanonicalTurnPipelineResult simultaneousFinalize(
    CanonicalTurnPipelineRequest request,
  ) {
    final ruleset = request.ruleset.copyWith(
      paceBalance: request.snapshot.domain.matchRules.paceBalance,
    );
    final combat = DomainTurnCombatResolver.resolve(
      state: request.snapshot.domain,
      mapTiles: request.mapView.mapTiles,
      ruleset: ruleset,
    );
    final legacyInput = _snapshotAdapter.toLegacy(
      request.snapshot.copyWith(domain: combat.state),
    );
    final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: legacyInput.state,
      playerIds: request.playerIds,
      mapData: request.mapView,
      ruleset: ruleset,
      fogOfWarService: request.fogOfWarService,
      priorEvents: combat.events,
      mapObjectives: request.mapView.objectives,
      turn: request.snapshot.domain.turn,
    );
    final postEconomySnapshot = _snapshotAdapter.toCanonical(
      save: legacyInput.save,
      state: economy.state,
      eventLogOffset: request.snapshot.eventLogOffset,
    );
    final suffix = CanonicalTurnSuffix.finalizeAfterEconomy(
      CanonicalTurnSuffixRequest(
        snapshot: postEconomySnapshot,
        playerIds: request.playerIds,
        skippedPlayerIds: request.skippedPlayerIds,
        savedAt: request.savedAt,
        mapView: request.mapView,
        combatEvents: combat.events,
        economyEvents: economy.events,
        fogOfWarService: request.fogOfWarService,
        preserveNonParticipantPlayerStates:
            request.preserveNonParticipantPlayerStates,
        trackTimeoutStreaks: request.trackTimeoutStreaks,
      ),
    );
    return CanonicalTurnPipelineResult(
      snapshot: suffix.snapshot,
      events: suffix.events,
      movementDelta: TurnMovementDelta(
        beforeUnits: suffix.beforeMovementUnits,
        afterUnits: suffix.afterMovementUnits,
      ),
    );
  }
}

List<String> _orderedDistinctPlayerIds(Iterable<String> playerIds) {
  final seen = <String>{};
  return [
    for (final playerId in playerIds)
      if (playerId.isNotEmpty && seen.add(playerId)) playerId,
  ];
}
