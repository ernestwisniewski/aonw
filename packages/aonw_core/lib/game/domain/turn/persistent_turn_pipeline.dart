import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/turn/persistent_turn_combat_resolver.dart';
import 'package:aonw_core/game/domain/turn/persistent_turn_economy_processor.dart';
import 'package:aonw_core/game/domain/turn/persistent_turn_movement_processor.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

enum PersistentTurnPipelineMode { playerEndTurn, simultaneousFinalize }

final class PersistentTurnMovementDelta {
  PersistentTurnMovementDelta({
    required Iterable<GameUnit> beforeUnits,
    required Iterable<GameUnit> afterUnits,
  }) : beforeUnits = List.unmodifiable(beforeUnits),
       afterUnits = List.unmodifiable(afterUnits);

  final List<GameUnit> beforeUnits;
  final List<GameUnit> afterUnits;

  bool get changed {
    if (beforeUnits.length != afterUnits.length) return true;
    for (var i = 0; i < beforeUnits.length; i++) {
      if (beforeUnits[i] != afterUnits[i]) return true;
    }
    return false;
  }
}

final class PersistentTurnPipelineRequest {
  PersistentTurnPipelineRequest.playerEndTurn({
    required this.save,
    required this.state,
    required String playerId,
    required this.savedAt,
    required this.mapData,
    this.mapDefinition,
    this.ruleset = GameRuleset.defaults,
    this.fogOfWarService = const FogOfWarService(),
    this.syncRulesetPaceWithSave = true,
  }) : mode = PersistentTurnPipelineMode.playerEndTurn,
       playerIds = List.unmodifiable([playerId]),
       skippedPlayerIds = const [],
       preserveNonParticipantPlayerStates = false,
       trackTimeoutStreaks = false;

  PersistentTurnPipelineRequest.simultaneousFinalize({
    required this.save,
    required this.state,
    required Iterable<String> playerIds,
    required this.savedAt,
    required this.mapData,
    this.mapDefinition,
    this.ruleset = GameRuleset.defaults,
    this.fogOfWarService = const FogOfWarService(),
    Iterable<String> skippedPlayerIds = const [],
    this.preserveNonParticipantPlayerStates = false,
    this.trackTimeoutStreaks = false,
    this.syncRulesetPaceWithSave = true,
  }) : mode = PersistentTurnPipelineMode.simultaneousFinalize,
       playerIds = List.unmodifiable(_orderedDistinctPlayerIds(playerIds)),
       skippedPlayerIds = List.unmodifiable(
         _orderedDistinctPlayerIds(skippedPlayerIds),
       );

  final PersistentTurnPipelineMode mode;
  final GameSave save;
  final PersistentGameState state;
  final List<String> playerIds;
  final DateTime savedAt;
  final MapData mapData;
  final MapDefinition? mapDefinition;
  final GameRuleset ruleset;
  final FogOfWarService fogOfWarService;
  final List<String> skippedPlayerIds;
  final bool preserveNonParticipantPlayerStates;
  final bool trackTimeoutStreaks;
  final bool syncRulesetPaceWithSave;
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

abstract final class PersistentTurnPipeline {
  static PersistentTurnPipelineResult run(
    PersistentTurnPipelineRequest request,
  ) {
    return switch (request.mode) {
      PersistentTurnPipelineMode.playerEndTurn => _playerEndTurn(request),
      PersistentTurnPipelineMode.simultaneousFinalize => _simultaneousFinalize(
        request,
      ),
    };
  }

  static PersistentTurnPipelineResult _playerEndTurn(
    PersistentTurnPipelineRequest request,
  ) {
    if (request.playerIds.length != 1) {
      throw ArgumentError.value(
        request.playerIds,
        'PersistentTurnPipelineRequest.playerIds',
        'playerEndTurn requires exactly one player id',
      );
    }

    final playerId = request.playerIds.single;
    final savedAt = request.savedAt.toUtc();
    final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: request.state,
      playerIds: [playerId],
      mapData: request.mapData,
      ruleset: _rulesetFor(request),
      fogOfWarService: request.fogOfWarService,
      turn: request.save.turn,
    );
    final previousCulturalHoldTurns =
        economy.state.runtimeState.culturalVictoryHoldTurnsByPlayerId;
    final culturalHoldTurns = request.save.matchRules.victory.culturalEnabled
        ? CulturalVictoryProgressCalculator.advanceHoldTurns(
            playerIds: [playerId],
            state: economy.state,
            previousHoldTurnsByPlayerId: previousCulturalHoldTurns,
            requiredArtifactCount:
                request.save.matchRules.victory.culturalRequiredArtifacts,
          )
        : previousCulturalHoldTurns;
    final runtimeState = economy.state.runtimeState.copyWith(
      culturalVictoryHoldTurnsByPlayerId: culturalHoldTurns,
    );
    final state = economy.state.copyWith(runtimeState: runtimeState);
    final save = request.save
        .withPlayerFinished(playerId)
        .copyWith(savedAt: savedAt);

    return PersistentTurnPipelineResult(
      save: save,
      state: state,
      events: [
        ...economy.events,
        TurnEndedEvent(playerId: playerId),
      ],
    );
  }

  static PersistentTurnPipelineResult _simultaneousFinalize(
    PersistentTurnPipelineRequest request,
  ) {
    final playerIds = request.playerIds;
    final skippedPlayerIds = _skippedPlayerIdsFor(request);
    final savedAt = request.savedAt.toUtc();
    final ruleset = _rulesetFor(request);
    final combat = PersistentTurnCombatResolver.resolve(
      turn: request.save.turn,
      state: request.state,
      mapDefinition: request.mapDefinition,
      ruleset: ruleset,
    );
    final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: combat.state,
      playerIds: playerIds,
      mapData: request.mapData,
      ruleset: ruleset,
      fogOfWarService: request.fogOfWarService,
      priorEvents: combat.events,
      mapObjectives: request.mapData.objectives,
      turn: request.save.turn,
    );
    final movement = PersistentTurnMovementProcessor.resetForPlayers(
      state: economy.state,
      playerIds: playerIds,
      mapData: request.mapData,
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
      mapData: request.mapData,
      victoryRules: request.save.matchRules.victory,
      previousHoldTurnsByPlayerId: previousDominationHoldTurns,
    );
    final dominationEvents = dominationProgressCalculator
        .thresholdReachedEvents(
          playerIds: playerIds,
          state: movement.state,
          mapData: request.mapData,
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

  static GameRuleset _rulesetFor(PersistentTurnPipelineRequest request) {
    if (!request.syncRulesetPaceWithSave) return request.ruleset;
    return request.ruleset.copyWith(
      paceBalance: request.save.matchRules.paceBalance,
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
