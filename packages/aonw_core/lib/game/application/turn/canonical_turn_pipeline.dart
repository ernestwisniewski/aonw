import 'package:aonw_core/game/compatibility.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/turn/domain_turn_combat_resolver.dart';
import 'package:aonw_core/game/domain/turn/persistent_turn_pipeline.dart';
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
  }) : playerIds = List.unmodifiable(playerIds),
       skippedPlayerIds = List.unmodifiable(skippedPlayerIds);

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
    final combat = DomainTurnCombatResolver.resolve(
      state: request.snapshot.domain,
      mapTiles: request.mapView.mapTiles,
      ruleset: request.ruleset.copyWith(
        paceBalance: request.snapshot.domain.matchRules.paceBalance,
      ),
    );
    final legacyInput = _snapshotAdapter.toLegacy(
      request.snapshot.copyWith(domain: combat.state),
    );
    final legacyResult = PersistentTurnPipeline.simultaneousFinalizeAfterCombat(
      PersistentTurnPipelineRequest.simultaneousFinalize(
        save: legacyInput.save,
        state: legacyInput.state,
        playerIds: request.playerIds,
        savedAt: request.savedAt,
        mapView: request.mapView,
        ruleset: request.ruleset,
        fogOfWarService: request.fogOfWarService,
        skippedPlayerIds: request.skippedPlayerIds,
        preserveNonParticipantPlayerStates:
            request.preserveNonParticipantPlayerStates,
        trackTimeoutStreaks: request.trackTimeoutStreaks,
      ),
      combatEvents: combat.events,
    );
    return CanonicalTurnPipelineResult(
      snapshot: _snapshotAdapter.toCanonical(
        save: legacyResult.save,
        state: legacyResult.state,
        eventLogOffset: request.snapshot.eventLogOffset,
      ),
      events: legacyResult.events,
      movementDelta: _neutralMovementDelta(legacyResult.movementDelta),
    );
  }
}

TurnMovementDelta? _neutralMovementDelta(PersistentTurnMovementDelta? source) {
  if (source == null) return null;
  return TurnMovementDelta(
    beforeUnits: source.beforeUnits,
    afterUnits: source.afterUnits,
  );
}
