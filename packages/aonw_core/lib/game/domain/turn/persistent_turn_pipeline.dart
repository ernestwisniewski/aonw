import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/runtime.dart';
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
    required MapReadView mapView,
    GameRuleset ruleset = GameRuleset.defaults,
    FogOfWarService fogOfWarService = const FogOfWarService(),
    VictoryRules victoryRules = VictoryRules.standard,
    int? turn,
  }) {
    final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: state,
      playerIds: [playerId],
      mapData: mapView,
      ruleset: ruleset,
      fogOfWarService: fogOfWarService,
      mapObjectives: mapView.objectives,
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
    final ruleset = _rulesetFor(request);
    final combat = PersistentTurnCombatResolver.resolve(
      turn: request.save.turn,
      state: request.state,
      mapTiles: request.mapView.mapTiles,
      ruleset: ruleset,
    );
    return _simultaneousFinalizeAfterCombat(
      request,
      state: combat.state,
      combatEvents: combat.events,
    );
  }

  static PersistentTurnPipelineResult _simultaneousFinalizeAfterCombat(
    PersistentTurnPipelineRequest request, {
    required PersistentGameState state,
    required Iterable<GameEvent> combatEvents,
  }) {
    final mapView = request.mapView;
    final playerIds = request.playerIds;
    final skippedPlayerIds = _skippedPlayerIdsFor(request);
    final savedAt = request.savedAt.toUtc();
    final ruleset = _rulesetFor(request);
    final priorCombatEvents = List<GameEvent>.unmodifiable(combatEvents);
    final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: state,
      playerIds: playerIds,
      mapData: mapView,
      ruleset: ruleset,
      fogOfWarService: request.fogOfWarService,
      priorEvents: priorCombatEvents,
      mapObjectives: mapView.objectives,
      turn: request.save.turn,
    );
    final movement = PersistentTurnMovementProcessor.resetForPlayers(
      state: economy.state,
      playerIds: playerIds,
      mapData: mapView,
      fogOfWarService: request.fogOfWarService,
    );
    final diplomacy = _diplomacyAfterMovement(
      state: movement.state,
      playerIds: playerIds,
      turn: request.save.turn + 1,
    );
    final victory = _victoryProgressAfterMovement(
      request: request,
      state: movement.state,
      playerIds: playerIds,
    );
    return _completeTurn(
      request: request,
      economy: economy,
      movement: movement,
      diplomacy: diplomacy,
      victory: victory,
      combatEvents: priorCombatEvents,
      playerIds: playerIds,
      skippedPlayerIds: skippedPlayerIds,
      savedAt: savedAt,
    );
  }

  static PersistentTurnPipelineResult _completeTurn({
    required PersistentTurnPipelineRequest request,
    required PersistentTurnEconomyResult economy,
    required PersistentTurnMovementResult movement,
    required DiplomacyTurnResolution diplomacy,
    required _TurnVictoryProgress victory,
    required List<GameEvent> combatEvents,
    required List<String> playerIds,
    required List<String> skippedPlayerIds,
    required DateTime savedAt,
  }) {
    final runtimeState = _runtimeStateAfterTurn(
      request: request,
      state: movement.state,
      diplomacy: diplomacy,
      victory: victory,
      playerIds: playerIds,
      skippedPlayerIds: skippedPlayerIds,
      savedAt: savedAt,
    );
    return PersistentTurnPipelineResult(
      save: _saveAfterTurn(request, playerIds: playerIds, savedAt: savedAt),
      state: movement.state.copyWith(runtimeState: runtimeState),
      events: [
        for (final playerId in skippedPlayerIds)
          PlayerTimedOutEvent(turn: request.save.turn, playerId: playerId),
        AllPlayersSubmittedEvent(turn: request.save.turn, playerIds: playerIds),
        ...combatEvents,
        ...economy.events,
        ...diplomacy.events,
        ...victory.dominationEvents,
        for (final playerId in playerIds) TurnEndedEvent(playerId: playerId),
      ],
      movementDelta: PersistentTurnMovementDelta(
        beforeUnits: economy.state.units,
        afterUnits: movement.state.units,
      ),
    );
  }

  static GameRuntimeState _runtimeStateAfterTurn({
    required PersistentTurnPipelineRequest request,
    required PersistentGameState state,
    required DiplomacyTurnResolution diplomacy,
    required _TurnVictoryProgress victory,
    required List<String> playerIds,
    required List<String> skippedPlayerIds,
    required DateTime savedAt,
  }) {
    final previousTimeouts = state.runtimeState.timeoutStreaksByPlayerId;
    final timeoutStreaks = request.trackTimeoutStreaks
        ? _timeoutStreaksAfterTurn(
            previous: previousTimeouts,
            playerIds: playerIds,
            skippedPlayerIds: skippedPlayerIds,
          )
        : previousTimeouts;
    return state.runtimeState.copyWith(
      submittedPlayerIds: const {},
      timeoutStreaksByPlayerId: timeoutStreaks,
      intendedAttacks: const [],
      diplomacy: diplomacy.diplomacy,
      dominationHoldTurnsByPlayerId: victory.dominationHoldTurns,
      culturalVictoryHoldTurnsByPlayerId: victory.culturalHoldTurns,
      turnStartedAt: savedAt,
    );
  }

  static DiplomacyTurnResolution _diplomacyAfterMovement({
    required PersistentGameState state,
    required List<String> playerIds,
    required int turn,
  }) {
    final discovered = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: state.runtimeState.diplomacy,
      fogOfWar: state.fogOfWar,
      units: state.units,
      cities: state.cities,
      playerIds: playerIds,
    );
    return DiplomacyTurnResolver.resolve(
      diplomacy: discovered,
      turn: turn,
      units: state.units,
      cities: state.cities,
    );
  }

  static _TurnVictoryProgress _victoryProgressAfterMovement({
    required PersistentTurnPipelineRequest request,
    required PersistentGameState state,
    required List<String> playerIds,
  }) {
    const domination = DominationProgressCalculator();
    final victoryRules = request.save.matchRules.victory;
    final previousDomination = state.runtimeState.dominationHoldTurnsByPlayerId;
    final dominationHoldTurns = domination.advanceHoldTurns(
      playerIds: playerIds,
      state: state,
      mapData: request.mapView,
      victoryRules: victoryRules,
      previousHoldTurnsByPlayerId: previousDomination,
    );
    final previousCultural =
        state.runtimeState.culturalVictoryHoldTurnsByPlayerId;
    return _TurnVictoryProgress(
      dominationHoldTurns: dominationHoldTurns,
      dominationEvents: domination.thresholdReachedEvents(
        playerIds: playerIds,
        state: state,
        mapData: request.mapView,
        victoryRules: victoryRules,
        previousHoldTurnsByPlayerId: previousDomination,
        nextHoldTurnsByPlayerId: dominationHoldTurns,
      ),
      culturalHoldTurns: victoryRules.culturalEnabled
          ? CulturalVictoryProgressCalculator.advanceHoldTurns(
              playerIds: playerIds,
              state: state,
              previousHoldTurnsByPlayerId: previousCultural,
              requiredArtifactCount: victoryRules.culturalRequiredArtifacts,
            )
          : previousCultural,
    );
  }

  static GameSave _saveAfterTurn(
    PersistentTurnPipelineRequest request, {
    required List<String> playerIds,
    required DateTime savedAt,
  }) {
    return request.preserveNonParticipantPlayerStates
        ? _saveWithNewTurnForPlayers(
            request.save,
            playerIds: playerIds,
            savedAt: savedAt,
          )
        : request.save.withNewTurn().copyWith(savedAt: savedAt);
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

final class _TurnVictoryProgress {
  _TurnVictoryProgress({
    required this.dominationHoldTurns,
    required Iterable<GameEvent> dominationEvents,
    required this.culturalHoldTurns,
  }) : dominationEvents = List.unmodifiable(dominationEvents);

  final Map<String, int> dominationHoldTurns;
  final List<GameEvent> dominationEvents;
  final Map<String, int> culturalHoldTurns;
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
