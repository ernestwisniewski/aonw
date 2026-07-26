import 'dart:async';

import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';

part 'server_command_reducer_artifact.dart';
part 'server_command_reducer_auto_explore.dart';
part 'server_command_reducer_city.dart';
part 'server_command_reducer_city_expansion.dart';
part 'server_command_reducer_city_founding.dart';
part 'server_command_reducer_combat.dart';
part 'server_command_reducer_detachment.dart';
part 'server_command_reducer_diplomacy.dart';
part 'server_command_reducer_interaction.dart';
part 'server_command_reducer_map_cache.dart';
part 'server_command_reducer_merchant_routing.dart';
part 'server_command_reducer_movement.dart';
part 'server_command_reducer_outcome.dart';
part 'server_command_reducer_production.dart';
part 'server_command_reducer_research.dart';
part 'server_command_reducer_resource_trade.dart';
part 'server_command_reducer_turns.dart';
part 'server_command_reducer_unit_action.dart';
part 'server_command_reducer_worker.dart';

const defaultMultiplayerTurnTimeout = Duration(seconds: 115);

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
    if (match.state != 'running') {
      // Outcome construction lives in its part, keeping the reducer focused on
      // command validation and application.
      return _reject('match_not_running');
    }

    final domain = snapshot.domain;
    final session = snapshot.session;
    final command = GameCommandSerializer.fromJson(wireCommand.command);
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
    if (match.state != 'running') {
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
    final result = _finalizeSimultaneousTurn(
      snapshot: snapshot,
      playerIds: playerIds,
      skippedPlayerIds: skippedPlayerIds,
      now: nowUtc,
      mapView: loadedMap.mapView,
      ruleset: ruleset,
    );

    return _acceptedReduction(
      match: match,
      result: result.withSnapshot(_withSavedAt(result.snapshot, nowUtc)),
      mapView: loadedMap.mapView,
    );
  }

  _CommandApplication _applyCommand({
    required CanonicalGameSnapshot snapshot,
    required WireMatch match,
    required GameCommand command,
    required int commandTick,
    required String actorPlayerId,
    required DateTime now,
    required _LoadedServerMap loadedMap,
    required GameRuleset ruleset,
  }) {
    switch (command) {
      case SubmitTurnCommand():
        return _submitTurn(
          snapshot: snapshot,
          match: match,
          command: command,
          actorPlayerId: actorPlayerId,
          now: now,
          mapView: loadedMap.mapView,
          ruleset: ruleset,
        );
      case EndTurnCommand(:final playerId):
        return _submitTurn(
          snapshot: snapshot,
          match: match,
          command: SubmitTurnCommand(playerId),
          actorPlayerId: actorPlayerId,
          now: now,
          mapView: loadedMap.mapView,
          ruleset: ruleset,
        );
      case MoveUnitCommand():
        return _applyMoveUnit(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
          mapView: loadedMap.mapView,
        );
      case AttackHexCommand():
        return _applyCombatCommand(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
          commandTick: commandTick,
          mapTiles: loadedMap.mapView,
          ruleset: ruleset,
        );
      case CancelUnitActionCommand():
        return _applyCancelUnitAction(snapshot, command, actorPlayerId);
      case SkipUnitTurnCommand():
        return _applySkipUnitTurn(snapshot, command, actorPlayerId);
      case FortifyUnitCommand():
        return _applyFortifyUnit(snapshot, command, actorPlayerId);
      case AutoExploreUnitCommand():
        return _applyAutoExplore(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
          mapView: loadedMap.mapView,
        );
      case AssignMerchantTradeRouteCommand():
        return _applyAssignMerchantRoute(
          snapshot,
          command,
          actorPlayerId,
          loadedMap.mapView,
        );
      case MoveMerchantToCityCommand():
        return _applyMoveMerchantToCity(
          snapshot,
          command,
          actorPlayerId,
          loadedMap.mapView,
        );
      case OpenResourceTradeCommand():
        return _applyOpenResourceTrade(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: loadedMap.mapView,
        );
      case OpenResourceExchangeCommand():
        return _applyOpenResourceExchange(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: loadedMap.mapView,
        );
      case DiplomaticCommand():
        return _applyDiplomacyCommand(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
        );
      case FoundCityCommand():
        return _applyCityFoundingCommand(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: loadedMap.mapView,
        );
      case SetCitySpecializationCommand():
      case StartBuildingCommand() ||
          StartUnitProductionCommand() ||
          StartCityProjectCommand() ||
          StartWonderCommand():
        return _applyProductionCommand(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
          mapView: loadedMap.mapView,
          ruleset: ruleset,
        );
      case RushProductionCommand():
        return _applyProductionCommand(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
          mapView: loadedMap.mapView,
          ruleset: ruleset,
        );
      case SelectTechnologyCommand():
        return _applySelectTechnologyCommand(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: loadedMap.mapView,
          ruleset: ruleset,
        );
      case DetachTroopCommand():
        return _applyDetachTroopCommand(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: loadedMap.mapView,
        );
      case ToggleWorkedHexCommand():
        return _applyToggleWorkedHexCommand(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
          ruleset: ruleset,
        );
      case SelectCityExpansionHexCommand():
        return _applySelectCityExpansionHexCommand(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: loadedMap.mapView,
          ruleset: ruleset,
        );
      case SelectWorkerImprovementCommand():
        return _applySelectWorkerImprovement(
          snapshot,
          command,
          actorPlayerId,
          loadedMap.mapView,
          ruleset,
        );
      case ConfirmWorkerImprovementCommand():
        return _applyConfirmWorkerImprovement(
          snapshot,
          command,
          actorPlayerId,
          loadedMap.mapView,
          ruleset,
        );
      case CancelWorkerJobCommand():
        return _applyCancelWorkerJob(snapshot, command, actorPlayerId);
      case AssignWorkerToHexCommand():
        return _applyAssignWorkerToHex(
          snapshot,
          command,
          actorPlayerId,
          loadedMap.mapView,
        );
      case CancelWorkerAssignmentCommand():
        return _applyCancelWorkerAssignment(snapshot, command, actorPlayerId);
      case StartArtifactExcavationCommand():
        return _applyStartArtifactExcavationCommand(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
        );
      case StoreArtifactInCityCommand():
        return _applyStoreArtifactInCityCommand(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
        );
      case TradeArtifactCommand():
        return _applyTradeArtifactCommand(
          snapshot: snapshot,
          command: command,
          actorPlayerId: actorPlayerId,
        );
      case ResetUnitMovementCommand():
        return _CommandApplication.reject(
          snapshot: snapshot,
          reason: 'server_managed_command',
        );
      case SetActivePlayerCommand() ||
          TileTappedCommand() ||
          CityTappedCommand() ||
          ToggleMoveTargetingCommand() ||
          StartCityFoundingCommand() ||
          CancelCityFoundingCommand() ||
          StartCityWorkedHexSelectionCommand() ||
          CancelCityWorkedHexSelectionCommand() ||
          StartCityExpansionSelectionCommand() ||
          CancelCityExpansionSelectionCommand() ||
          StartWorkerActionSelectionCommand() ||
          CancelWorkerActionSelectionCommand() ||
          StartMerchantTradeRouteSelectionCommand() ||
          CancelMerchantTradeRouteSelectionCommand() ||
          StartMerchantMoveToCitySelectionCommand() ||
          CancelMerchantMoveToCitySelectionCommand() ||
          CancelResearchSelectionCommand() ||
          StartAttackTargetingCommand() ||
          CancelAttackTargetingCommand() ||
          StartCommanderMergeSelectionCommand() ||
          CancelCommanderMergeSelectionCommand() ||
          SelectTileCommand() ||
          SelectUnitCommand() ||
          SelectCityCommand() ||
          FocusNextPendingActionCommand() ||
          FocusTurnStartActionCommand():
        return _CommandApplication.reject(
          snapshot: snapshot,
          reason: 'client_only_command',
        );
    }
  }

  _CommandApplication _applicationFrom({
    required CanonicalGameSnapshot snapshot,
    required bool accepted,
    DomainState? domain,
    MatchSessionState? session,
    GameSnapshotMetadata? metadata,
    PersistedInteractionState? interaction,
    List<GameEvent> events = const [],
    Iterable<MovementCommandExecution> movementExecutions = const [],
    String? reason,
  }) {
    if (!accepted) {
      return _CommandApplication.reject(
        snapshot: snapshot,
        reason: reason ?? 'command_rejected',
      );
    }
    return _CommandApplication.accept(
      snapshot: _snapshotWithChanges(
        snapshot,
        domain: domain,
        session: session,
        metadata: metadata,
        interaction: interaction,
      ),
      events: events,
      movementExecutions: movementExecutions,
    );
  }
}

class _CommandApplication {
  _CommandApplication({
    required this.accepted,
    required this.snapshot,
    this.events = const [],
    Iterable<MovementCommandExecution> movementExecutions = const [],
    this.reason,
  }) : movementExecutions = _ownedList(movementExecutions);

  final bool accepted;
  final CanonicalGameSnapshot snapshot;
  final List<GameEvent> events;
  final List<MovementCommandExecution> movementExecutions;
  final String? reason;

  factory _CommandApplication.accept({
    required CanonicalGameSnapshot snapshot,
    List<GameEvent> events = const [],
    Iterable<MovementCommandExecution> movementExecutions = const [],
  }) => _CommandApplication(
    accepted: true,
    snapshot: snapshot,
    events: events,
    movementExecutions: movementExecutions,
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

CanonicalGameSnapshot _snapshotWithChanges(
  CanonicalGameSnapshot snapshot, {
  DomainState? domain,
  MatchSessionState? session,
  GameSnapshotMetadata? metadata,
  PersistedInteractionState? interaction,
}) {
  if (domain == null &&
      session == null &&
      metadata == null &&
      interaction == null) {
    return snapshot;
  }
  return snapshot.copyWith(
    domain: domain,
    session: session,
    metadata: metadata,
    interaction: interaction,
  );
}
