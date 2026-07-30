import 'dart:async';

import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/application/engine/server_system_command.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/match_lifecycle_state_adapter.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_map_catalog.dart';
import 'package:aonw_server/src/multiplayer/wire_player_domain_mapper.dart';

part 'server_command_reducer_map_cache.dart';
part 'server_command_reducer_outcome.dart';
part 'server_command_reducer_turns.dart';
part 'server_command_reducer_unit_action.dart';

const defaultMultiplayerTurnTimeout = Duration(seconds: 115);
const _matchLifecycleStateAdapter = MatchLifecycleStateAdapter();

DomainCommand? _decodePlayerDomainCommand(Map<String, dynamic> rawCommand) {
  try {
    return GameCommandSerializer.fromJson(rawCommand);
  } on ArgumentError {
    return null;
  }
}

class ServerCommandReducer {
  ServerCommandReducer({
    MultiplayerMapCatalog mapCatalog = const FileMultiplayerMapCatalog(),
    Duration turnTimeout = defaultMultiplayerTurnTimeout,
  }) : _mapCatalog = mapCatalog,
       _turnTimeout = turnTimeout;

  final MultiplayerMapCatalog _mapCatalog;
  final Duration _turnTimeout;
  final Map<String, Future<_LoadedServerMap>> _loadedMaps = {};

  bool hasTurnTimedOut({
    required CanonicalGameSnapshot snapshot,
    required DateTime now,
  }) => _turnTimedOut(snapshot, now);

  Future<ServerCommandReduction> reduce({
    required WireMatch match,
    required CanonicalGameSnapshot snapshot,
    required WireCommand wireCommand,
    required String actorPlayerId,
    required DateTime now,
  }) async {
    if (!_matchLifecycleStateAdapter.isRunningWireMatch(match)) {
      // Outcome construction lives in its part, keeping the reducer focused on
      // command validation and application.
      return _reject('match_not_running');
    }

    final domain = snapshot.domain;
    final session = snapshot.session;
    final command = _decodePlayerDomainCommand(wireCommand.command);
    if (command == null) {
      return _reject('invalid_command_payload');
    }
    if (wireCommand.turn != null && wireCommand.turn != domain.turn) {
      return _reject('stale_turn');
    }
    if (session.isKicked(actorPlayerId)) {
      return _reject('player_eliminated');
    }
    if (command is! SubmitTurnCommand &&
        command is! EndTurnCommand &&
        session.hasSubmitted(actorPlayerId)) {
      return _reject('player_already_submitted');
    }

    final loadedMap = await _loadServerMap(snapshot.metadata.world.name);
    final ruleset = GameRuleset.standard().copyWith(
      paceBalance: domain.matchRules.paceBalance,
    );
    final result = _applyCommand(
      snapshot: snapshot,
      match: match,
      command: command,
      commandTick: wireCommand.tick,
      actorPlayerId: actorPlayerId,
      now: now.toUtc(),
      loadedMap: loadedMap,
      ruleset: ruleset,
    );
    if (!result.accepted) {
      return _reject(result.reason ?? 'command_rejected');
    }

    final nextSnapshot = _withSavedAt(result.snapshot, now.toUtc());
    return _acceptedReduction(
      match: match,
      result: result.withSnapshot(nextSnapshot),
      mapView: loadedMap.mapView,
    );
  }

  Future<ServerCommandReduction> reduceTimedOutTurn({
    required WireMatch match,
    required CanonicalGameSnapshot snapshot,
    required String actorPlayerId,
    required DateTime now,
  }) async {
    if (!_matchLifecycleStateAdapter.isRunningWireMatch(match)) {
      return _reject('match_not_running');
    }

    final nowUtc = now.toUtc();
    if (!_turnTimedOut(snapshot, nowUtc)) {
      return _reject('turn_not_timed_out');
    }
    if (snapshot.session.isKicked(actorPlayerId)) {
      return _reject('player_eliminated');
    }

    final playerIds = _turnPlayerIds(snapshot);
    if (playerIds.isEmpty || !playerIds.contains(actorPlayerId)) {
      return _reject('turn_player_not_active');
    }

    final loadedMap = await _loadServerMap(snapshot.metadata.world.name);
    final ruleset = GameRuleset.standard().copyWith(
      paceBalance: snapshot.domain.matchRules.paceBalance,
    );
    final submittedPlayerIds = snapshot.session.submittedPlayerIds;
    final skippedPlayerIds = playerIds
        .where((playerId) => !submittedPlayerIds.contains(playerId))
        .toList();
    final engineResult = const GameEngine().applySystem(
      snapshot: snapshot,
      command: FinalizeTimedOutTurn(
        playerIds: playerIds,
        skippedPlayerIds: skippedPlayerIds,
      ),
      context: GameEngineContext(
        actorPlayerId: actorPlayerId,
        mapView: loadedMap.mapView,
        ruleset: ruleset,
        commandTick: snapshot.eventLogOffset,
        savedAt: nowUtc,
        preserveNonParticipantTurnStates: true,
        trackTimeoutStreaks: true,
      ),
    );
    final result = _commandApplicationFromEngine(snapshot, engineResult);

    return _acceptedReduction(
      match: match,
      result: result.withSnapshot(_withSavedAt(result.snapshot, nowUtc)),
      mapView: loadedMap.mapView,
    );
  }

  _CommandApplication _applyCommand({
    required CanonicalGameSnapshot snapshot,
    required WireMatch match,
    required DomainCommand command,
    required int commandTick,
    required String actorPlayerId,
    required DateTime now,
    required _LoadedServerMap loadedMap,
    required GameRuleset ruleset,
  }) {
    switch (command) {
      case SubmitTurnCommand(:final playerId):
      case EndTurnCommand(:final playerId):
        return _applyTurnCommand(
          snapshot: snapshot,
          match: match,
          command: _submitTurnCommand(command, playerId),
          actorPlayerId: actorPlayerId,
          commandTick: commandTick,
          now: now,
          mapView: loadedMap.mapView,
          ruleset: ruleset,
        );
      case MoveUnitCommand():
      case CancelUnitActionCommand():
      case AutoExploreUnitCommand():
      case AssignMerchantTradeRouteCommand():
      case MoveMerchantToCityCommand():
      case DetachTroopCommand():
      case SkipUnitTurnCommand():
      case FortifyUnitCommand():
      case AttackHexCommand():
      case FoundCityCommand():
      case ToggleWorkedHexCommand():
      case SelectCityExpansionHexCommand():
      case StartBuildingCommand():
      case StartUnitProductionCommand():
      case StartCityProjectCommand():
      case StartWonderCommand():
      case SetCitySpecializationCommand():
      case RushProductionCommand():
      case SelectWorkerImprovementCommand():
      case ConfirmWorkerImprovementCommand():
      case CancelWorkerJobCommand():
      case AssignWorkerToHexCommand():
      case CancelWorkerAssignmentCommand():
      case StartArtifactExcavationCommand():
      case StoreArtifactInCityCommand():
      case TradeArtifactCommand():
      case OpenResourceTradeCommand():
      case OpenResourceExchangeCommand():
      case DiplomaticCommand():
      case SelectTechnologyCommand():
        return _applyDomainCommandEngine(
          snapshot,
          command,
          actorPlayerId,
          commandTick,
          loadedMap.mapView,
          ruleset,
        );
    }
  }

  _CommandApplication _applyTurnCommand({
    required CanonicalGameSnapshot snapshot,
    required WireMatch match,
    required SubmitTurnCommand command,
    required String actorPlayerId,
    required int commandTick,
    required DateTime now,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    final playerIds = _turnPlayerIds(snapshot);
    final timedOut = _turnTimedOut(snapshot, now);
    if (timedOut && snapshot.session.hasSubmitted(command.playerId)) {
      return _commandApplicationFromEngine(
        snapshot,
        const GameEngine().applySystem(
          snapshot: snapshot,
          command: FinalizeTimedOutTurn(
            playerIds: playerIds,
            skippedPlayerIds: [
              for (final id in playerIds)
                if (!snapshot.session.hasSubmitted(id)) id,
            ],
          ),
          context: GameEngineContext(
            actorPlayerId: actorPlayerId,
            mapView: mapView,
            ruleset: ruleset,
            commandTick: commandTick,
            savedAt: now,
            preserveNonParticipantTurnStates: true,
            trackTimeoutStreaks: true,
          ),
        ),
      );
    }
    final requiredPlayerIds = timedOut
        ? [command.playerId]
        : _requiredTurnSubmissionPlayerIds(match: match, playerIds: playerIds);
    return _applyDomainCommandEngine(
      snapshot,
      command,
      actorPlayerId,
      commandTick,
      mapView,
      ruleset,
      turnPlayerIds: playerIds,
      requiredTurnSubmissionPlayerIds: requiredPlayerIds,
      savedAt: now,
      preserveNonParticipantTurnStates: true,
      trackTimeoutStreaks: true,
    );
  }
}

SubmitTurnCommand _submitTurnCommand(DomainCommand command, String playerId) {
  return command is SubmitTurnCommand ? command : SubmitTurnCommand(playerId);
}

_CommandApplication _commandApplicationFromEngine(
  CanonicalGameSnapshot snapshot,
  GameEngineResult result,
) {
  return switch (result) {
    GameEngineAccepted() => _CommandApplication.accept(
      snapshot: result.snapshot,
      events: result.events,
      movementExecutions: result.movementDelta.executions,
      combatAnimations: result.combatAnimations,
    ),
    final GameEngineRejected rejected => _CommandApplication.reject(
      snapshot: snapshot,
      reason: rejected.reason,
    ),
  };
}

class _CommandApplication {
  _CommandApplication({
    required this.accepted,
    required this.snapshot,
    this.events = const [],
    Iterable<MovementCommandExecution> movementExecutions = const [],
    Iterable<CombatAnimationFact> combatAnimations = const [],
    this.reason,
  }) : movementExecutions = _ownedList(movementExecutions),
       combatAnimations = _ownedList(combatAnimations);

  final bool accepted;
  final CanonicalGameSnapshot snapshot;
  final List<GameEvent> events;
  final List<MovementCommandExecution> movementExecutions;
  final List<CombatAnimationFact> combatAnimations;
  final String? reason;

  factory _CommandApplication.accept({
    required CanonicalGameSnapshot snapshot,
    List<GameEvent> events = const [],
    Iterable<MovementCommandExecution> movementExecutions = const [],
    Iterable<CombatAnimationFact> combatAnimations = const [],
  }) => _CommandApplication(
    accepted: true,
    snapshot: snapshot,
    events: events,
    movementExecutions: movementExecutions,
    combatAnimations: combatAnimations,
  );

  factory _CommandApplication.reject({
    required CanonicalGameSnapshot snapshot,
    required String reason,
  }) =>
      _CommandApplication(accepted: false, snapshot: snapshot, reason: reason);

  _CommandApplication withSnapshot(CanonicalGameSnapshot nextSnapshot) {
    if (identical(nextSnapshot, snapshot)) return this;
    return _CommandApplication(
      accepted: accepted,
      snapshot: nextSnapshot,
      events: events,
      movementExecutions: movementExecutions,
      combatAnimations: combatAnimations,
      reason: reason,
    );
  }
}

CanonicalGameSnapshot _withSavedAt(
  CanonicalGameSnapshot snapshot,
  DateTime savedAtUtc,
) {
  if (snapshot.metadata.savedAtUtc == savedAtUtc) return snapshot;
  return snapshot.copyWith(
    metadata: snapshot.metadata.copyWith(savedAtUtc: savedAtUtc),
  );
}
