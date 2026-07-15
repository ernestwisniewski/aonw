import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/turn/persistent_turn_combat_resolver.dart';
import 'package:aonw_core/game/domain/turn/persistent_turn_economy_processor.dart';
import 'package:aonw_core/game/domain/turn/persistent_turn_movement_processor.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class PersistentTurnMovementDelta {
  PersistentTurnMovementDelta({
    required Iterable<GameUnit> beforeUnits,
    required Iterable<GameUnit> afterUnits,
  }) : beforeUnits = List.unmodifiable(beforeUnits),
       afterUnits = List.unmodifiable(afterUnits);

  final List<GameUnit> beforeUnits;
  final List<GameUnit> afterUnits;
}

final class PersistentTurnPipelineRequest {
  PersistentTurnPipelineRequest.simultaneousFinalize({
    required this.save,
    required this.state,
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

  final GameSave save;
  final PersistentGameState state;
  final List<String> playerIds;
  final DateTime savedAt;
  final MapReadView mapView;
  final GameRuleset ruleset;
  final FogOfWarService fogOfWarService;
  final List<String> skippedPlayerIds;
  final bool preserveNonParticipantPlayerStates;
  final bool trackTimeoutStreaks;
}

final class PersistentTurnPipelineResult {
  PersistentTurnPipelineResult({
    required this.save,
    required this.state,
    Iterable<GameEvent> events = const [],
    this.movementDelta,
  }) : events = List.unmodifiable(events);

  final GameSave save;
  final PersistentGameState state;
  final List<GameEvent> events;
  final PersistentTurnMovementDelta? movementDelta;
}

final class PersistentPlayerTurnResult {
  PersistentPlayerTurnResult({
    required this.state,
    Iterable<GameEvent> events = const [],
  }) : events = List.unmodifiable(events);

  final PersistentGameState state;
  final List<GameEvent> events;
}

abstract final class PersistentTurnPipeline {
  static PersistentPlayerTurnResult advancePlayer({
    required PersistentGameState state,
    required String playerId,
    required MapReadView mapData,
    GameRuleset ruleset = GameRuleset.defaults,
    FogOfWarService fogOfWarService = const FogOfWarService(),
    VictoryRules victoryRules = VictoryRules.standard,
    int? turn,
  }) {
    final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: state,
      playerIds: [playerId],
      mapData: mapData,
      ruleset: ruleset,
      fogOfWarService: fogOfWarService,
      mapObjectives: mapData.objectives,
      turn: turn,
    );
    final previousCulturalHoldTurns =
        economy.state.runtimeState.culturalVictoryHoldTurnsByPlayerId;
    final culturalHoldTurns = victoryRules.culturalEnabled
        ? CulturalVictoryProgressCalculator.advanceHoldTurns(
            playerIds: [playerId],
            state: economy.state,
            previousHoldTurnsByPlayerId: previousCulturalHoldTurns,
            requiredArtifactCount: victoryRules.culturalRequiredArtifacts,
          )
        : previousCulturalHoldTurns;

    return PersistentPlayerTurnResult(
      state: economy.state.copyWith(
        runtimeState: economy.state.runtimeState.copyWith(
          culturalVictoryHoldTurnsByPlayerId: culturalHoldTurns,
        ),
      ),
      events: [
        ...economy.events,
        TurnEndedEvent(playerId: playerId),
      ],
    );
  }

  static PersistentTurnPipelineResult simultaneousFinalize(
    PersistentTurnPipelineRequest request,
  ) {
    final mapView = request.mapView;
    final playerIds = request.playerIds;
    final skippedPlayerIds = _skippedPlayerIdsFor(request);
    final savedAt = request.savedAt.toUtc();
    final ruleset = _rulesetFor(request);
    final combat = PersistentTurnCombatResolver.resolve(
      turn: request.save.turn,
      state: request.state,
      mapTiles: mapView.mapTiles,
      ruleset: ruleset,
    );
    final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: combat.state,
      playerIds: playerIds,
      mapData: mapView,
      ruleset: ruleset,
      fogOfWarService: request.fogOfWarService,
      priorEvents: combat.events,
      mapObjectives: mapView.objectives,
      turn: request.save.turn,
    );
    final movement = PersistentTurnMovementProcessor.resetForPlayers(
      state: economy.state,
      playerIds: playerIds,
      mapData: mapView,
      fogOfWarService: request.fogOfWarService,
    );
    final discoveredDiplomacy = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: movement.state.runtimeState.diplomacy,
      fogOfWar: movement.state.fogOfWar,
      units: movement.state.units,
      cities: movement.state.cities,
      playerIds: playerIds,
    );
    final diplomacy = DiplomacyTurnResolver.resolve(
      diplomacy: discoveredDiplomacy,
      turn: request.save.turn + 1,
      units: movement.state.units,
      cities: movement.state.cities,
    );
    const dominationProgressCalculator = DominationProgressCalculator();
    final previousDominationHoldTurns =
        movement.state.runtimeState.dominationHoldTurnsByPlayerId;
    final dominationHoldTurns = dominationProgressCalculator.advanceHoldTurns(
      playerIds: playerIds,
      state: movement.state,
      mapData: mapView,
      victoryRules: request.save.matchRules.victory,
      previousHoldTurnsByPlayerId: previousDominationHoldTurns,
    );
    final dominationEvents = dominationProgressCalculator
        .thresholdReachedEvents(
          playerIds: playerIds,
          state: movement.state,
          mapData: mapView,
          victoryRules: request.save.matchRules.victory,
          previousHoldTurnsByPlayerId: previousDominationHoldTurns,
          nextHoldTurnsByPlayerId: dominationHoldTurns,
        );
    final previousCulturalHoldTurns =
        movement.state.runtimeState.culturalVictoryHoldTurnsByPlayerId;
    final culturalHoldTurns = request.save.matchRules.victory.culturalEnabled
        ? CulturalVictoryProgressCalculator.advanceHoldTurns(
            playerIds: playerIds,
            state: movement.state,
            previousHoldTurnsByPlayerId: previousCulturalHoldTurns,
            requiredArtifactCount:
                request.save.matchRules.victory.culturalRequiredArtifacts,
          )
        : previousCulturalHoldTurns;
    final timeoutStreaks = request.trackTimeoutStreaks
        ? _timeoutStreaksAfterTurn(
            previous: movement.state.runtimeState.timeoutStreaksByPlayerId,
            playerIds: playerIds,
            skippedPlayerIds: skippedPlayerIds,
          )
        : movement.state.runtimeState.timeoutStreaksByPlayerId;
    final runtimeState = movement.state.runtimeState.copyWith(
      submittedPlayerIds: const {},
      timeoutStreaksByPlayerId: timeoutStreaks,
      intendedAttacks: const [],
      diplomacy: diplomacy.diplomacy,
      dominationHoldTurnsByPlayerId: dominationHoldTurns,
      culturalVictoryHoldTurnsByPlayerId: culturalHoldTurns,
      turnStartedAt: savedAt,
    );
    final save = request.preserveNonParticipantPlayerStates
        ? _saveWithNewTurnForPlayers(
            request.save,
            playerIds: playerIds,
            savedAt: savedAt,
          )
        : request.save.withNewTurn().copyWith(savedAt: savedAt);

    return PersistentTurnPipelineResult(
      save: save,
      state: movement.state.copyWith(runtimeState: runtimeState),
      events: [
        for (final playerId in skippedPlayerIds)
          PlayerTimedOutEvent(turn: request.save.turn, playerId: playerId),
        AllPlayersSubmittedEvent(turn: request.save.turn, playerIds: playerIds),
        ...combat.events,
        ...economy.events,
        ...diplomacy.events,
        ...dominationEvents,
        for (final playerId in playerIds) TurnEndedEvent(playerId: playerId),
      ],
      movementDelta: PersistentTurnMovementDelta(
        beforeUnits: economy.state.units,
        afterUnits: movement.state.units,
      ),
    );
  }

  static List<String> _skippedPlayerIdsFor(
    PersistentTurnPipelineRequest request,
  ) {
    final playerSet = request.playerIds.toSet();
    return [
      for (final playerId in request.skippedPlayerIds)
        if (playerSet.contains(playerId)) playerId,
    ];
  }

  static GameRuleset _rulesetFor(PersistentTurnPipelineRequest request) {
    return request.ruleset.copyWith(
      paceBalance: request.save.matchRules.paceBalance,
    );
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

  static GameSave _saveWithNewTurnForPlayers(
    GameSave save, {
    required List<String> playerIds,
    required DateTime savedAt,
  }) {
    final activePlayerIds = playerIds.toSet();
    final playerStates = {
      for (final entry in save.playerStates.entries)
        entry.key: activePlayerIds.contains(entry.key)
            ? PlayerTurnState.active
            : PlayerTurnState.finished,
    };
    return save.copyWith(
      turn: save.turn + 1,
      playerStates: playerStates,
      savedAt: savedAt,
    );
  }
}

List<String> _orderedDistinctPlayerIds(Iterable<String> playerIds) {
  final seen = <String>{};
  final ordered = <String>[];
  for (final playerId in playerIds) {
    if (playerId.isEmpty || !seen.add(playerId)) continue;
    ordered.add(playerId);
  }
  return ordered;
}
