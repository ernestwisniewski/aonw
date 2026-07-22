import 'dart:async';

import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/running_match_snapshot_codec.dart';

part 'server_command_reducer_artifact.dart';
part 'server_command_reducer_auto_explore.dart';
part 'server_command_reducer_city.dart';
part 'server_command_reducer_city_expansion.dart';
part 'server_command_reducer_city_founding.dart';
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
part 'server_command_reducer_snapshot.dart';
part 'server_command_reducer_turns.dart';
part 'server_command_reducer_unit_action.dart';
part 'server_command_reducer_worker.dart';

const defaultMultiplayerTurnTimeout = Duration(seconds: 115);
const _runningMatchSnapshotCodec = RunningMatchSnapshotCodec();

class ServerCommandReducer {
  ServerCommandReducer({
    MultiplayerMapCatalog mapCatalog = const FileMultiplayerMapCatalog(),
    Duration turnTimeout = defaultMultiplayerTurnTimeout,
  }) : _mapCatalog = mapCatalog,
       _turnTimeout = turnTimeout;

  final MultiplayerMapCatalog _mapCatalog;
  final Duration _turnTimeout;
  final Map<String, Future<_LoadedServerMap>> _loadedMaps = {};

  DecodedMatchSnapshot decodeSnapshot({
    required WireMatch match,
    required WireSnapshot snapshot,
  }) => _runningMatchSnapshotCodec.decode(match: match, snapshot: snapshot);

  bool hasTurnTimedOut({
    required DecodedMatchSnapshot decodedSnapshot,
    required DateTime now,
  }) => _turnTimedOut(decodedSnapshot.save, decodedSnapshot.state, now);

  Future<ServerCommandReduction> reduce({
    required WireMatch match,
    required WireSnapshot snapshot,
    required WireCommand wireCommand,
    required String actorPlayerId,
    required DateTime now,
  }) async {
    if (match.state != 'running') {
      return _reject(snapshot, 'match_not_running');
    }

    final decodedSnapshot = decodeSnapshot(match: match, snapshot: snapshot);
    final save = decodedSnapshot.save;
    final state = decodedSnapshot.state;
    final command = GameCommandSerializer.fromJson(wireCommand.command);
    if (wireCommand.turn != null && wireCommand.turn != save.turn) {
      return _reject(snapshot, 'stale_turn');
    }
    if (state.runtimeState.isKicked(actorPlayerId)) {
      return _reject(snapshot, 'player_eliminated');
    }
    if (command is! SubmitTurnCommand &&
        command is! EndTurnCommand &&
        state.runtimeState.hasSubmitted(actorPlayerId)) {
      return _reject(snapshot, 'player_already_submitted');
    }

    final loadedMap = await _loadServerMap(save.mapName);
    final ruleset = GameRuleset.standard().copyWith(
      paceBalance: save.matchRules.paceBalance,
    );
    final result = _applyCommand(
      decodedSnapshot: decodedSnapshot,
      match: match,
      command: command,
      commandTick: wireCommand.tick,
      actorPlayerId: actorPlayerId,
      now: now.toUtc(),
      loadedMap: loadedMap,
      ruleset: ruleset,
    );
    if (!result.accepted) {
      return _reject(snapshot, result.reason ?? 'command_rejected');
    }

    final nextSave = result.save.copyWith(savedAt: now.toUtc());
    return _acceptedReduction(
      match: match,
      decodedSnapshot: decodedSnapshot,
      nextSave: nextSave,
      result: result,
      mapView: loadedMap.mapView,
    );
  }

  Future<ServerCommandReduction> reduceTimedOutTurn({
    required WireMatch match,
    required WireSnapshot snapshot,
    required DecodedMatchSnapshot decodedSnapshot,
    required String actorPlayerId,
    required DateTime now,
  }) async {
    if (match.state != 'running') {
      return _reject(snapshot, 'match_not_running');
    }

    final save = decodedSnapshot.save;
    final state = decodedSnapshot.state;
    final nowUtc = now.toUtc();
    if (!_turnTimedOut(save, state, nowUtc)) {
      return _reject(snapshot, 'turn_not_timed_out');
    }
    if (state.runtimeState.isKicked(actorPlayerId)) {
      return _reject(snapshot, 'player_eliminated');
    }

    final playerIds = _turnPlayerIds(save, state);
    if (playerIds.isEmpty || !playerIds.contains(actorPlayerId)) {
      return _reject(snapshot, 'turn_player_not_active');
    }

    final loadedMap = await _loadServerMap(save.mapName);
    final ruleset = GameRuleset.standard().copyWith(
      paceBalance: save.matchRules.paceBalance,
    );
    final submittedPlayerIds = state.runtimeState.submittedPlayerIds;
    final skippedPlayerIds = playerIds
        .where((playerId) => !submittedPlayerIds.contains(playerId))
        .toList();
    final result = _finalizeSimultaneousTurn(
      decodedSnapshot: decodedSnapshot,
      playerIds: playerIds,
      skippedPlayerIds: skippedPlayerIds,
      now: nowUtc,
      mapView: loadedMap.mapView,
      ruleset: ruleset,
    );

    final nextSave = result.save.copyWith(savedAt: nowUtc);
    return _acceptedReduction(
      match: match,
      decodedSnapshot: decodedSnapshot,
      nextSave: nextSave,
      result: result,
      mapView: loadedMap.mapView,
    );
  }

  _CommandApplication _applyCommand({
    required DecodedMatchSnapshot decodedSnapshot,
    required WireMatch match,
    required GameCommand command,
    required int commandTick,
    required String actorPlayerId,
    required DateTime now,
    required _LoadedServerMap loadedMap,
    required GameRuleset ruleset,
  }) {
    final save = decodedSnapshot.save;
    final state = decodedSnapshot.state;
    switch (command) {
      case SubmitTurnCommand():
        return _submitTurn(
          decodedSnapshot: decodedSnapshot,
          match: match,
          command: command,
          actorPlayerId: actorPlayerId,
          now: now,
          mapView: loadedMap.mapView,
          ruleset: ruleset,
        );
      case EndTurnCommand(:final playerId):
        return _submitTurn(
          decodedSnapshot: decodedSnapshot,
          match: match,
          command: SubmitTurnCommand(playerId),
          actorPlayerId: actorPlayerId,
          now: now,
          mapView: loadedMap.mapView,
          ruleset: ruleset,
        );
      case MoveUnitCommand():
        return _applyMoveUnit(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapView: loadedMap.mapView,
        );
      case AttackHexCommand():
        final result = const PersistentCombatCommandResolver().resolve(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          turn: save.turn,
          commandTick: commandTick,
          mapTiles: loadedMap.mapView,
          ruleset: ruleset,
        );
        return _fromPersistentCombatResult(save, result);
      case CancelUnitActionCommand():
        return _applyCancelUnitAction(save, state, command, actorPlayerId);
      case SkipUnitTurnCommand():
        return _applySkipUnitTurn(save, state, command, actorPlayerId);
      case FortifyUnitCommand():
        return _applyFortifyUnit(save, state, command, actorPlayerId);
      case AutoExploreUnitCommand():
        return _applyAutoExplore(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapView: loadedMap.mapView,
        );
      case AssignMerchantTradeRouteCommand():
        return _applyAssignMerchantRoute(
          save,
          state,
          command,
          actorPlayerId,
          loadedMap.mapView,
        );
      case MoveMerchantToCityCommand():
        return _applyMoveMerchantToCity(
          save,
          state,
          command,
          actorPlayerId,
          loadedMap.mapView,
        );
      case OpenResourceTradeCommand():
        return _applyOpenResourceTrade(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: loadedMap.mapView,
        );
      case OpenResourceExchangeCommand():
        return _applyOpenResourceExchange(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: loadedMap.mapView,
        );
      case DiplomaticCommand():
        return _applyDiplomacyCommand(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
      case FoundCityCommand():
        return _applyCityFoundingCommand(
          save: save,
          state: state,
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
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapView: loadedMap.mapView,
          ruleset: ruleset,
        );
      case RushProductionCommand():
        return _applyProductionCommand(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapView: loadedMap.mapView,
          ruleset: ruleset,
        );
      case SelectTechnologyCommand():
        return _applySelectTechnologyCommand(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: loadedMap.mapView,
          ruleset: ruleset,
        );
      case DetachTroopCommand():
        return _applyDetachTroopCommand(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: loadedMap.mapView,
        );
      case ToggleWorkedHexCommand():
        return _applyToggleWorkedHexCommand(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          ruleset: ruleset,
        );
      case SelectCityExpansionHexCommand():
        return _applySelectCityExpansionHexCommand(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: loadedMap.mapView,
          ruleset: ruleset,
        );
      case SelectWorkerImprovementCommand():
        return _applySelectWorkerImprovement(
          save,
          state,
          command,
          actorPlayerId,
          loadedMap.mapView,
          ruleset,
        );
      case ConfirmWorkerImprovementCommand():
        return _applyConfirmWorkerImprovement(
          save,
          state,
          command,
          actorPlayerId,
          loadedMap.mapView,
          ruleset,
        );
      case CancelWorkerJobCommand():
        return _applyCancelWorkerJob(save, state, command, actorPlayerId);
      case AssignWorkerToHexCommand():
        return _applyAssignWorkerToHex(
          save,
          state,
          command,
          actorPlayerId,
          loadedMap.mapView,
        );
      case CancelWorkerAssignmentCommand():
        return _applyCancelWorkerAssignment(
          save,
          state,
          command,
          actorPlayerId,
        );
      case StartArtifactExcavationCommand():
        return _applyStartArtifactExcavationCommand(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
      case StoreArtifactInCityCommand():
        return _applyStoreArtifactInCityCommand(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
      case TradeArtifactCommand():
        return _applyTradeArtifactCommand(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
      case ResetUnitMovementCommand():
        return _CommandApplication.reject(
          save: save,
          state: state,
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
          save: save,
          state: state,
          reason: 'client_only_command',
        );
    }
  }

  _CommandApplication _fromPersistentCombatResult(
    GameSave save,
    PersistentCombatCommandResult result,
  ) {
    return _applicationFrom(
      save: save,
      accepted: result.accepted,
      state: result.state,
      events: result.events,
      reason: result.reason,
    );
  }

  _CommandApplication _applicationFrom({
    required GameSave save,
    required bool accepted,
    required PersistentGameState state,
    List<GameEvent> events = const [],
    String? reason,
  }) {
    if (!accepted) {
      return _CommandApplication.reject(
        save: save,
        state: state,
        reason: reason ?? 'command_rejected',
      );
    }
    return _CommandApplication.accept(save: save, state: state, events: events);
  }

  ServerCommandReduction _reject(WireSnapshot snapshot, String reason) {
    return ServerCommandReduction(
      accepted: false,
      snapshot: snapshot,
      reason: reason,
    );
  }
}

class _CommandApplication {
  const _CommandApplication({
    required this.accepted,
    required this.save,
    required this.state,
    this.events = const [],
    this.canonicalSnapshot,
    this.reason,
  });

  final bool accepted;
  final GameSave save;
  final PersistentGameState state;
  final List<GameEvent> events;
  final CanonicalGameSnapshot? canonicalSnapshot;
  final String? reason;

  factory _CommandApplication.accept({
    required GameSave save,
    required PersistentGameState state,
    List<GameEvent> events = const [],
    CanonicalGameSnapshot? canonicalSnapshot,
  }) {
    return _CommandApplication(
      accepted: true,
      save: save,
      state: state,
      events: events,
      canonicalSnapshot: canonicalSnapshot,
    );
  }

  factory _CommandApplication.reject({
    required GameSave save,
    required PersistentGameState state,
    required String reason,
  }) {
    return _CommandApplication(
      accepted: false,
      save: save,
      state: state,
      reason: reason,
    );
  }
}
