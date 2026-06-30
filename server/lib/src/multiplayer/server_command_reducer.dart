import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'initial_multiplayer_snapshot_factory.dart';

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

class ServerCommandReducer {
  const ServerCommandReducer({
    MultiplayerMapCatalog mapCatalog = const FileMultiplayerMapCatalog(),
  }) : _mapCatalog = mapCatalog;

  final MultiplayerMapCatalog _mapCatalog;

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
    if (command is! SubmitTurnCommand &&
        command is! EndTurnCommand &&
        state.runtimeState.hasSubmitted(actorPlayerId)) {
      return _reject(snapshot, 'player_already_submitted');
    }

    final mapData = await _mapCatalog.loadAssetMap(save.mapName);
    mapData.mapName ??= save.mapName;
    final mapDefinition = _mapDefinitionFrom(mapData);
    final ruleset = GameRuleset(
      city: CityRulesets.standard,
      technology: TechnologyRulesets.standard,
      paceBalance: save.matchRules.paceBalance,
    );
    final result = _applyCommand(
      save: save,
      state: state,
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
      case FoundCityCommand():
        final result = const PersistentCityFoundingResolver().foundCity(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
          cityRuleset: ruleset.city,
        );
        return _fromPersistentResult(save, result);
      case StartBuildingCommand():
        final result = const PersistentCityProductionResolver().startBuilding(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
          cityRuleset: ruleset.city,
          technologyRuleset: ruleset.technology,
          paceBalance: ruleset.paceBalance,
        );
        return _fromPersistentResult(save, result);
      case StartUnitProductionCommand():
        final result = const PersistentCityProductionResolver()
            .startUnitProduction(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
              cityRuleset: ruleset.city,
              technologyRuleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            );
        return _fromPersistentResult(save, result);
      case StartCityProjectCommand():
        final result = const PersistentCityProductionResolver()
            .startCityProject(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              cityRuleset: ruleset.city,
              paceBalance: ruleset.paceBalance,
            );
        return _fromPersistentResult(save, result);
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

  _CommandApplication _submitTurn({
    required GameSave save,
    required PersistentGameState state,
    required SubmitTurnCommand command,
    required String actorPlayerId,
    required DateTime now,
    required MapData mapData,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    if (command.playerId != actorPlayerId) {
      return _CommandApplication.reject(
        save: save,
        state: state,
        reason: 'turn_player_not_controlled',
      );
    }
    final playerIds = _activePlayerIds(save);
    if (playerIds.isEmpty || !playerIds.contains(command.playerId)) {
      return _CommandApplication.reject(
        save: save,
        state: state,
        reason: 'turn_player_not_active',
      );
    }
    if (state.runtimeState.hasSubmitted(command.playerId)) {
      return _CommandApplication.accept(save: save, state: state);
    }

    final submitted = {
      ...state.runtimeState.submittedPlayerIds,
      command.playerId,
    };
    final submittedState = state.copyWith(
      runtimeState: state.runtimeState.copyWith(submittedPlayerIds: submitted),
    );
    if (!playerIds.every(submitted.contains)) {
      return _CommandApplication.accept(
        save: save
            .withPlayerFinished(command.playerId)
            .copyWith(savedAt: now.toUtc()),
        state: submittedState,
      );
    }

    return _finalizeSimultaneousTurn(
      save: save,
      state: submittedState,
      playerIds: playerIds,
      now: now,
      mapData: mapData,
      mapDefinition: mapDefinition,
      ruleset: ruleset,
    );
  }

  _CommandApplication _finalizeSimultaneousTurn({
    required GameSave save,
    required PersistentGameState state,
    required List<String> playerIds,
    required DateTime now,
    required MapData mapData,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    final combat = PersistentTurnCombatResolver.resolve(
      turn: save.turn,
      state: state,
      mapDefinition: mapDefinition,
      ruleset: ruleset,
    );
    final economy = PersistentTurnEconomyProcessor.advanceForPlayers(
      state: combat.state,
      playerIds: playerIds,
      mapData: mapData,
      ruleset: ruleset,
      priorEvents: combat.events,
      mapObjectives: mapData.objectives,
    );
    final artifactProgress = PersistentArtifactTurnProcessor.advanceForPlayers(
      state: economy.state,
      playerIds: playerIds,
    );
    final movement = PersistentTurnMovementProcessor.resetForPlayers(
      state: artifactProgress.state,
      playerIds: playerIds,
      mapData: mapData,
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
      turn: save.turn + 1,
      units: movement.state.units,
      cities: movement.state.cities,
    );
    const dominationProgressCalculator = DominationProgressCalculator();
    final previousDominationHoldTurns =
        movement.state.runtimeState.dominationHoldTurnsByPlayerId;
    final dominationHoldTurns = dominationProgressCalculator.advanceHoldTurns(
      playerIds: playerIds,
      state: movement.state,
      mapData: mapData,
      victoryRules: save.matchRules.victory,
      previousHoldTurnsByPlayerId: previousDominationHoldTurns,
    );
    final dominationEvents = dominationProgressCalculator
        .thresholdReachedEvents(
          playerIds: playerIds,
          state: movement.state,
          mapData: mapData,
          victoryRules: save.matchRules.victory,
          previousHoldTurnsByPlayerId: previousDominationHoldTurns,
          nextHoldTurnsByPlayerId: dominationHoldTurns,
        );
    final previousCulturalHoldTurns =
        movement.state.runtimeState.culturalVictoryHoldTurnsByPlayerId;
    final culturalHoldTurns = save.matchRules.victory.culturalEnabled
        ? CulturalVictoryProgressCalculator.advanceHoldTurns(
            playerIds: playerIds,
            state: movement.state,
            previousHoldTurnsByPlayerId: previousCulturalHoldTurns,
            requiredArtifactCount:
                save.matchRules.victory.culturalRequiredArtifacts,
          )
        : previousCulturalHoldTurns;
    final runtimeState = movement.state.runtimeState.copyWith(
      submittedPlayerIds: const {},
      intendedAttacks: const [],
      diplomacy: diplomacy.diplomacy,
      dominationHoldTurnsByPlayerId: dominationHoldTurns,
      culturalVictoryHoldTurnsByPlayerId: culturalHoldTurns,
      turnStartedAt: now.toUtc(),
    );
    final nextSave = save.withNewTurn().copyWith(savedAt: now.toUtc());
    final nextState = movement.state.copyWith(runtimeState: runtimeState);
    return _CommandApplication.accept(
      save: nextSave,
      state: nextState,
      events: [
        AllPlayersSubmittedEvent(turn: save.turn, playerIds: playerIds),
        ...combat.events,
        ...economy.events,
        ...diplomacy.events,
        ...dominationEvents,
        for (final playerId in playerIds) TurnEndedEvent(playerId: playerId),
      ],
    );
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

  List<String> _activePlayerIds(GameSave save) {
    final ids = save.players
        .map((player) => player.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isNotEmpty) return ids..sort();
    return save.playerStates.keys.where((id) => id.isNotEmpty).toList()..sort();
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
