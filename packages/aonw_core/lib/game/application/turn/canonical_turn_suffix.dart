import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/movement/movement_command_execution.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/turn/domain_turn_movement_processor.dart';
import 'package:aonw_core/game/domain/turn/turn_victory_progress_resolver.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class CanonicalTurnSuffixRequest {
  CanonicalTurnSuffixRequest({
    required this.snapshot,
    required Iterable<String> playerIds,
    required Iterable<String> skippedPlayerIds,
    required this.savedAt,
    required this.mapView,
    required Iterable<GameEvent> combatEvents,
    required Iterable<GameEvent> economyEvents,
    required this.fogOfWarService,
    required this.preserveNonParticipantPlayerStates,
    required this.trackTimeoutStreaks,
  }) : playerIds = List.unmodifiable(playerIds),
       skippedPlayerIds = List.unmodifiable(skippedPlayerIds),
       combatEvents = List.unmodifiable(combatEvents),
       economyEvents = List.unmodifiable(economyEvents);

  final CanonicalGameSnapshot snapshot;
  final List<String> playerIds;
  final List<String> skippedPlayerIds;
  final DateTime savedAt;
  final MapReadView mapView;
  final List<GameEvent> combatEvents;
  final List<GameEvent> economyEvents;
  final FogOfWarService fogOfWarService;
  final bool preserveNonParticipantPlayerStates;
  final bool trackTimeoutStreaks;
}

final class CanonicalTurnSuffixResult {
  CanonicalTurnSuffixResult({
    required this.snapshot,
    required Iterable<GameEvent> events,
    required Iterable<GameUnit> beforeMovementUnits,
    required Iterable<GameUnit> afterMovementUnits,
    required Iterable<MovementCommandExecution> movementExecutions,
  }) : events = List.unmodifiable(events),
       beforeMovementUnits = List.unmodifiable(beforeMovementUnits),
       afterMovementUnits = List.unmodifiable(afterMovementUnits),
       movementExecutions = List.unmodifiable(movementExecutions);

  final CanonicalGameSnapshot snapshot;
  final List<GameEvent> events;
  final List<GameUnit> beforeMovementUnits;
  final List<GameUnit> afterMovementUnits;
  final List<MovementCommandExecution> movementExecutions;
}

/// Canonical movement and turn finalization after the legacy economy island.
abstract final class CanonicalTurnSuffix {
  static CanonicalTurnSuffixResult finalizeAfterEconomy(
    CanonicalTurnSuffixRequest request,
  ) {
    final beforeMovementUnits = request.snapshot.domain.units;
    final movement = DomainTurnMovementProcessor.resetForPlayers(
      state: request.snapshot.domain,
      interaction: request.snapshot.interaction,
      playerIds: request.playerIds,
      mapData: request.mapView,
      fogOfWarService: request.fogOfWarService,
    );
    final diplomacy = _diplomacyAfterMovement(
      state: movement.state,
      playerIds: request.playerIds,
    );
    final victory = TurnVictoryProgressResolver.resolve(
      playerIds: request.playerIds,
      cities: movement.state.cities,
      artifacts: movement.state.artifacts,
      previousDominationHoldTurnsByPlayerId:
          movement.state.dominationHoldTurnsByPlayerId,
      previousCulturalHoldTurnsByPlayerId:
          movement.state.culturalVictoryHoldTurnsByPlayerId,
      mapCatalog: request.mapView,
      victoryRules: movement.state.matchRules.victory,
    );
    final skippedPlayerIds = _skippedPlayerIdsFor(request);
    final savedAt = request.savedAt.toUtc();
    return CanonicalTurnSuffixResult(
      snapshot: _snapshotAfterTurn(
        request: request,
        state: movement.state,
        interaction: movement.interaction,
        diplomacy: diplomacy,
        victory: victory,
        skippedPlayerIds: skippedPlayerIds,
        savedAt: savedAt,
      ),
      events: _eventsAfterTurn(
        request: request,
        diplomacy: diplomacy,
        victory: victory,
        skippedPlayerIds: skippedPlayerIds,
        movementEvents: movement.events,
      ),
      beforeMovementUnits: beforeMovementUnits,
      afterMovementUnits: movement.state.units,
      movementExecutions: movement.executions,
    );
  }

  static DiplomacyTurnResolution _diplomacyAfterMovement({
    required DomainState state,
    required List<String> playerIds,
  }) {
    final discovered = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: state.diplomacy,
      fogOfWar: state.fogOfWar,
      units: state.units,
      cities: state.cities,
      playerIds: playerIds,
    );
    return DiplomacyTurnResolver.resolve(
      diplomacy: discovered,
      turn: state.turn + 1,
      units: state.units,
      cities: state.cities,
    );
  }

  static CanonicalGameSnapshot _snapshotAfterTurn({
    required CanonicalTurnSuffixRequest request,
    required DomainState state,
    required PersistedInteractionState interaction,
    required DiplomacyTurnResolution diplomacy,
    required TurnVictoryProgressResult victory,
    required List<String> skippedPlayerIds,
    required DateTime savedAt,
  }) {
    return request.snapshot.copyWith(
      domain: state.copyWith(
        turn: state.turn + 1,
        intendedAttacks: const [],
        diplomacy: diplomacy.diplomacy,
        dominationHoldTurnsByPlayerId: victory.dominationHoldTurns,
        culturalVictoryHoldTurnsByPlayerId: victory.culturalHoldTurns,
      ),
      session: _sessionAfterTurn(
        request: request,
        skippedPlayerIds: skippedPlayerIds,
        savedAt: savedAt,
      ),
      metadata: request.snapshot.metadata.copyWith(savedAtUtc: savedAt),
      interaction: interaction,
    );
  }

  static MatchSessionState _sessionAfterTurn({
    required CanonicalTurnSuffixRequest request,
    required List<String> skippedPlayerIds,
    required DateTime savedAt,
  }) {
    final session = request.snapshot.session;
    return session.copyWith(
      turnStatesByPlayerId: _turnStatesAfterTurn(request),
      submittedPlayerIds: const {},
      timeoutStreaksByPlayerId: request.trackTimeoutStreaks
          ? _timeoutStreaksAfterTurn(
              previous: session.timeoutStreaksByPlayerId,
              playerIds: request.playerIds,
              skippedPlayerIds: skippedPlayerIds,
            )
          : session.timeoutStreaksByPlayerId,
      turnStartedAt: savedAt,
    );
  }

  static Map<String, PlayerTurnState> _turnStatesAfterTurn(
    CanonicalTurnSuffixRequest request,
  ) {
    final activePlayerIds = request.playerIds.toSet();
    return {
      for (final entry in request.snapshot.session.turnStatesByPlayerId.entries)
        entry.key:
            request.preserveNonParticipantPlayerStates &&
                !activePlayerIds.contains(entry.key)
            ? PlayerTurnState.finished
            : PlayerTurnState.active,
    };
  }

  static List<GameEvent> _eventsAfterTurn({
    required CanonicalTurnSuffixRequest request,
    required DiplomacyTurnResolution diplomacy,
    required TurnVictoryProgressResult victory,
    required List<String> skippedPlayerIds,
    required Iterable<GameEvent> movementEvents,
  }) {
    final turn = request.snapshot.domain.turn;
    return [
      for (final playerId in skippedPlayerIds)
        PlayerTimedOutEvent(turn: turn, playerId: playerId),
      AllPlayersSubmittedEvent(turn: turn, playerIds: request.playerIds),
      ...request.combatEvents,
      ...request.economyEvents,
      ...movementEvents,
      ...diplomacy.events,
      ...victory.dominationEvents,
      for (final playerId in request.playerIds)
        TurnEndedEvent(playerId: playerId),
    ];
  }

  static List<String> _skippedPlayerIdsFor(CanonicalTurnSuffixRequest request) {
    final playerSet = request.playerIds.toSet();
    return [
      for (final playerId in request.skippedPlayerIds)
        if (playerSet.contains(playerId)) playerId,
    ];
  }

  static Map<String, int> _timeoutStreaksAfterTurn({
    required Map<String, int> previous,
    required List<String> playerIds,
    required List<String> skippedPlayerIds,
  }) {
    final skipped = skippedPlayerIds.toSet();
    return {
      for (final playerId in playerIds)
        if (skipped.contains(playerId)) playerId: (previous[playerId] ?? 0) + 1,
    };
  }
}
