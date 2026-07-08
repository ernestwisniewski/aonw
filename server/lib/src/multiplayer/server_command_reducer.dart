import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'initial_multiplayer_snapshot_factory.dart';

part 'server_command_reducer_production.dart';
part 'server_command_reducer_turns.dart';

class ServerCommandReduction {
  const ServerCommandReduction({
    required this.accepted,
    required this.snapshot,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final WireSnapshot snapshot;
  final List<GameEvent> events;
  final String? reason;
}

const defaultMultiplayerTurnTimeout = Duration(seconds: 115);

class ServerCommandReducer {
  const ServerCommandReducer({
    MultiplayerMapCatalog mapCatalog = const FileMultiplayerMapCatalog(),
    Duration turnTimeout = defaultMultiplayerTurnTimeout,
  }) : _mapCatalog = mapCatalog,
       _turnTimeout = turnTimeout;

  final MultiplayerMapCatalog _mapCatalog;
  final Duration _turnTimeout;

  bool hasTurnTimedOut({
    required WireSnapshot snapshot,
    required DateTime now,
  }) {
    final save = GameSave.fromJson(snapshot.save);
    final state = PersistentGameState.fromJson(snapshot.state);
    return _turnTimedOut(save, state, now);
  }

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

    final save = GameSave.fromJson(snapshot.save);
    final state = PersistentGameState.fromJson(snapshot.state);
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

    final mapData = await _mapCatalog.loadAssetMap(save.mapName);
    mapData.mapName ??= save.mapName;
    final mapDefinition = _mapDefinitionFrom(mapData);
    final ruleset = GameRuleset.standard().copyWith(
      paceBalance: save.matchRules.paceBalance,
    );
    final result = _applyCommand(
      save: save,
      state: state,
      match: match,
      command: command,
      actorPlayerId: actorPlayerId,
      now: now.toUtc(),
      mapData: mapData,
      mapDefinition: mapDefinition,
      ruleset: ruleset,
    );
    if (!result.accepted) {
      return _reject(snapshot, result.reason ?? 'command_rejected');
    }

    final nextSave = result.save.copyWith(savedAt: now.toUtc());
    final nextSnapshot = WireSnapshot(
      matchId: snapshot.matchId,
      offset: snapshot.offset,
      save: nextSave.toJson(),
      state: result.state.toJson(),
    );
    return ServerCommandReduction(
      accepted: true,
      snapshot: nextSnapshot,
      events: result.events,
    );
  }

  _CommandApplication _applyCommand({
    required GameSave save,
    required PersistentGameState state,
    required WireMatch match,
    required GameCommand command,
    required String actorPlayerId,
    required DateTime now,
    required MapData mapData,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    switch (command) {
      case SubmitTurnCommand():
        return _submitTurn(
          save: save,
          state: state,
          match: match,
          command: command,
          actorPlayerId: actorPlayerId,
          now: now,
          mapData: mapData,
          mapDefinition: mapDefinition,
          ruleset: ruleset,
        );
      case EndTurnCommand(:final playerId):
        return _submitTurn(
          save: save,
          state: state,
          match: match,
          command: SubmitTurnCommand(playerId),
          actorPlayerId: actorPlayerId,
          now: now,
          mapData: mapData,
          mapDefinition: mapDefinition,
          ruleset: ruleset,
        );
      case MoveUnitCommand():
        final result = const PersistentMoveUnitResolver().resolve(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
        );
        return _fromPersistentResult(save, result);
      case CancelUnitActionCommand():
        final result = const PersistentUnitActionResolver().cancelUnitAction(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _fromPersistentResult(save, result);
      case SkipUnitTurnCommand():
        final result = const PersistentUnitActionResolver().skipUnitTurn(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _fromPersistentResult(save, result);
      case FortifyUnitCommand():
        final result = const PersistentUnitActionResolver().fortifyUnit(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _fromPersistentResult(save, result);
      case AutoExploreUnitCommand():
        final result = const PersistentUnitActionResolver().autoExploreUnit(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
        );
        return _fromPersistentResult(save, result);
      case AssignMerchantTradeRouteCommand():
        final result = const PersistentMerchantTradeRouteResolver().assignRoute(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapData: mapData,
        );
        return _fromPersistentResult(save, result);
      case MoveMerchantToCityCommand():
        final result = const PersistentMerchantTradeRouteResolver().moveToCity(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapData: mapData,
        );
        return _fromPersistentResult(save, result);
      case OpenResourceTradeCommand(:final playerId):
        if (playerId != actorPlayerId) {
          return _CommandApplication.reject(
            save: save,
            state: state,
            reason: 'resource_trade_player_not_controlled',
          );
        }
        final result = const PersistentResourceTradeResolver()
            .openGoldForResourceTrade(
              state: state,
              importerPlayerId: command.playerId,
              exporterPlayerId: command.targetPlayerId,
              resource: command.resource,
              goldPerTurn: command.goldPerTurn,
              durationTurns: command.durationTurns,
              mapData: mapData,
              agreementId: command.agreementId,
            );
        return _fromPersistentResult(save, result);
      case OpenResourceExchangeCommand(:final playerId):
        if (playerId != actorPlayerId) {
          return _CommandApplication.reject(
            save: save,
            state: state,
            reason: 'resource_trade_player_not_controlled',
          );
        }
        final result = const PersistentResourceTradeResolver()
            .openResourceForResourceTrade(
              state: state,
              playerId: command.playerId,
              targetPlayerId: command.targetPlayerId,
              offeredResource: command.offeredResource,
              requestedResource: command.requestedResource,
              durationTurns: command.durationTurns,
              mapData: mapData,
              agreementId: command.agreementId,
            );
        return _fromPersistentResult(save, result);
      case DiplomaticCommand():
        final result = const DiplomacyCommandRouter().route(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          turn: save.turn,
        );
        return _fromPersistentResult(save, result);
      case FoundCityCommand():
        final result = const PersistentCityFoundingResolver().foundCity(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
          cityRuleset: ruleset.city,
        );
        return _fromPersistentResult(save, result);
      case StartBuildingCommand() ||
          StartUnitProductionCommand() ||
          StartCityProjectCommand() ||
          StartWonderCommand():
        return _applyProductionCommand(
          save: save,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
          ruleset: ruleset,
        );
      case SetCitySpecializationCommand():
        final result = const PersistentCityProductionResolver()
            .setCitySpecialization(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            );
        return _fromPersistentResult(save, result);
      case RushProductionCommand():
        final result = const PersistentCityProductionResolver().rushProduction(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
          cityRuleset: ruleset.city,
          technologyRuleset: ruleset.technology,
          wonderRuleset: ruleset.wonders,
          paceBalance: ruleset.paceBalance,
        );
        return _fromPersistentResult(save, result);
      case SelectTechnologyCommand():
        final result = const PersistentResearchCommandResolver()
            .selectTechnology(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              ruleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            );
        return _fromPersistentResult(save, result);
      case DetachTroopCommand():
        final result = const PersistentUnitDetachmentResolver().detachTroop(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
        );
        return _fromPersistentResult(save, result);
      case ToggleWorkedHexCommand():
        final result = const PersistentCityWorkedHexResolver().toggleWorkedHex(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          cityRuleset: ruleset.city,
        );
        return _fromPersistentResult(save, result);
      case SelectCityExpansionHexCommand():
        final result = const PersistentCityExpansionResolver()
            .selectExpansionHex(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
            );
        return _fromPersistentResult(save, result);
      case SelectWorkerImprovementCommand():
        final result = const PersistentWorkerCommandResolver()
            .selectWorkerImprovement(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            );
        return _fromPersistentResult(save, result);
      case ConfirmWorkerImprovementCommand():
        final result = const PersistentWorkerCommandResolver()
            .confirmWorkerImprovement(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            );
        return _fromPersistentResult(save, result);
      case CancelWorkerJobCommand():
        final result = const PersistentWorkerCommandResolver().cancelWorkerJob(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _fromPersistentResult(save, result);
      case AssignWorkerToHexCommand():
        final result = const PersistentWorkerCommandResolver()
            .assignWorkerToHex(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
            );
        return _fromPersistentResult(save, result);
      case CancelWorkerAssignmentCommand():
        final result = const PersistentWorkerCommandResolver()
            .cancelWorkerAssignment(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            );
        return _fromPersistentResult(save, result);
      case StartArtifactExcavationCommand():
        final result = const PersistentArtifactCommandResolver()
            .startExcavation(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            );
        return _fromPersistentResult(save, result);
      case StoreArtifactInCityCommand():
        final result = const PersistentArtifactCommandResolver().storeInCity(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _fromPersistentResult(save, result);
      case TradeArtifactCommand():
        final result = const PersistentArtifactCommandResolver().tradeArtifact(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _fromPersistentResult(save, result);
      default:
        return _CommandApplication.reject(
          save: save,
          state: state,
          reason: 'unsupported_server_command',
        );
    }
  }

  _CommandApplication _fromPersistentResult(GameSave save, Object result) {
    return switch (result) {
      PersistentMoveUnitResult(
        :final accepted,
        :final state,
        :final events,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          events: events,
          reason: reason,
        ),
      PersistentCityFoundingResult(
        :final accepted,
        :final state,
        :final events,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          events: events,
          reason: reason,
        ),
      PersistentCityProductionResult(
        :final accepted,
        :final state,
        :final events,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          events: events,
          reason: reason,
        ),
      PersistentUnitActionResult(
        :final accepted,
        :final state,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          reason: reason,
        ),
      PersistentMerchantTradeRouteResult(
        :final accepted,
        :final state,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          reason: reason,
        ),
      PersistentResourceTradeResult(
        :final accepted,
        :final state,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          reason: reason,
        ),
      PersistentDiplomacyResult(
        :final accepted,
        :final state,
        :final events,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          events: events,
          reason: reason,
        ),
      PersistentResearchCommandResult(
        :final accepted,
        :final state,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          reason: reason,
        ),
      PersistentUnitDetachmentResult(
        :final accepted,
        :final state,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          reason: reason,
        ),
      PersistentCityWorkedHexResult(
        :final accepted,
        :final state,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          reason: reason,
        ),
      PersistentCityExpansionResult(
        :final accepted,
        :final state,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          reason: reason,
        ),
      PersistentWorkerCommandResult(
        :final accepted,
        :final state,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          reason: reason,
        ),
      PersistentArtifactCommandResult(
        :final accepted,
        :final state,
        :final reason,
      ) =>
        _applicationFrom(
          save: save,
          accepted: accepted,
          state: state,
          reason: reason,
        ),
      _ => throw StateError('Unsupported persistent result: $result'),
    };
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

  MapDefinition _mapDefinitionFrom(MapData mapData) {
    return MapDefinition(
      cols: mapData.cols,
      rows: mapData.rows,
      mapName: mapData.mapName,
      defaultZoom: mapData.defaultZoom,
      tiles: [
        for (final tile in mapData.tiles)
          MapTileDefinition(
            col: tile.col,
            row: tile.row,
            terrains: tile.terrains,
            resources: tile.resources,
            height: tile.height,
          ),
      ],
    );
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
    this.reason,
  });

  final bool accepted;
  final GameSave save;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;

  factory _CommandApplication.accept({
    required GameSave save,
    required PersistentGameState state,
    List<GameEvent> events = const [],
  }) {
    return _CommandApplication(
      accepted: true,
      save: save,
      state: state,
      events: events,
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
