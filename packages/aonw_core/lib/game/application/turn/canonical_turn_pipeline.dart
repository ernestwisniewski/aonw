import 'package:aonw_core/game/application/turn/canonical_turn_suffix.dart';
import 'package:aonw_core/game/domain/artifact/cultural_victory_progress_resolver.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/turn/domain_turn_combat_resolver.dart';
import 'package:aonw_core/game/domain/turn/domain_turn_economy_processor.dart';
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
       ) {
    _validateParticipantScope(snapshot, this.playerIds);
    _validateSkippedScope(this.playerIds, this.skippedPlayerIds);
  }

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
    Iterable<MovementCommandExecution> executions = const [],
  }) : beforeUnits = List.unmodifiable(beforeUnits),
       afterUnits = List.unmodifiable(afterUnits),
       executions = List.unmodifiable(executions);

  final List<GameUnit> beforeUnits;
  final List<GameUnit> afterUnits;
  final List<MovementCommandExecution> executions;
}

/// Canonical output of simultaneous turn finalization.
final class CanonicalTurnPipelineResult {
  CanonicalTurnPipelineResult({
    required this.snapshot,
    Iterable<GameEvent> events = const [],
    required this.movementDelta,
  }) : events = List.unmodifiable(events);

  final CanonicalGameSnapshot snapshot;
  final List<GameEvent> events;
  final TurnMovementDelta movementDelta;
}

/// Canonical application facade for simultaneous turn finalization.
abstract final class CanonicalTurnPipeline {
  static CanonicalTurnPipelineResult sequentialEnd({
    required CanonicalGameSnapshot snapshot,
    required String playerId,
    required DateTime savedAt,
    required MapReadView mapView,
    GameRuleset ruleset = GameRuleset.defaults,
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    final effectiveRuleset = ruleset.copyWith(
      paceBalance: snapshot.domain.matchRules.paceBalance,
    );
    final economy = DomainTurnEconomyProcessor.advanceForPlayers(
      state: snapshot.domain,
      playerIds: [playerId],
      mapData: mapView,
      ruleset: effectiveRuleset,
      fogOfWarService: fogOfWarService,
      mapObjectives: mapView.objectives,
    );
    final culturalHoldTurns = snapshot.domain.matchRules.victory.culturalEnabled
        ? const CulturalVictoryProgressResolver().advanceHoldTurns(
            playerIds: [playerId],
            artifacts: economy.state.artifacts,
            cities: economy.state.cities,
            previousHoldTurnsByPlayerId:
                economy.state.culturalVictoryHoldTurnsByPlayerId,
            requiredArtifactCount:
                snapshot.domain.matchRules.victory.culturalRequiredArtifacts,
          )
        : economy.state.culturalVictoryHoldTurnsByPlayerId;
    final nextDomain = economy.state.copyWith(
      culturalVictoryHoldTurnsByPlayerId: culturalHoldTurns,
      turnStatesByPlayerId: {
        ...snapshot.domain.turnStatesByPlayerId,
        playerId: PlayerTurnState.finished,
      },
    );
    final savedAtUtc = savedAt.toUtc();
    return CanonicalTurnPipelineResult(
      snapshot: snapshot.copyWith(
        domain: nextDomain,
        metadata: snapshot.metadata.copyWith(savedAtUtc: savedAtUtc),
      ),
      events: [
        ...economy.events,
        TurnEndedEvent(playerId: playerId),
      ],
      movementDelta: TurnMovementDelta(
        beforeUnits: snapshot.domain.units,
        afterUnits: nextDomain.units,
      ),
    );
  }

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
    final economy = DomainTurnEconomyProcessor.advanceForPlayers(
      state: combat.state,
      playerIds: request.playerIds,
      mapData: request.mapView,
      ruleset: ruleset,
      fogOfWarService: request.fogOfWarService,
      priorEvents: combat.events,
      mapObjectives: request.mapView.objectives,
    );
    final suffix = CanonicalTurnSuffix.finalizeAfterEconomy(
      CanonicalTurnSuffixRequest(
        snapshot: request.snapshot.copyWith(domain: economy.state),
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
        ruleset: ruleset,
      ),
    );
    return CanonicalTurnPipelineResult(
      snapshot: suffix.snapshot,
      events: suffix.events,
      movementDelta: TurnMovementDelta(
        beforeUnits: suffix.beforeMovementUnits,
        afterUnits: suffix.afterMovementUnits,
        executions: suffix.movementExecutions,
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

void _validateParticipantScope(
  CanonicalGameSnapshot snapshot,
  Iterable<String> playerIds,
) {
  final participantIds = {
    for (final participant in snapshot.domain.participants) participant.id,
  };
  final unknownPlayerIds =
      playerIds.where((playerId) => !participantIds.contains(playerId)).toList()
        ..sort();
  if (unknownPlayerIds.isEmpty) return;
  throw ArgumentError.value(
    unknownPlayerIds,
    'playerIds',
    'Turn players must belong to domain participants',
  );
}

void _validateSkippedScope(
  Iterable<String> playerIds,
  Iterable<String> skippedPlayerIds,
) {
  final advancingPlayerIds = playerIds.toSet();
  final unknownSkippedPlayerIds =
      skippedPlayerIds
          .where((playerId) => !advancingPlayerIds.contains(playerId))
          .toList()
        ..sort();
  if (unknownSkippedPlayerIds.isEmpty) return;
  throw ArgumentError.value(
    unknownSkippedPlayerIds,
    'skippedPlayerIds',
    'Skipped players must belong to the finalized player scope',
  );
}
