part of 'economy_simulation.dart';

final class _EconomySimulationCommandApplier {
  const _EconomySimulationCommandApplier();

  _ApplyCommandResult apply({
    required int turn,
    required int tick,
    required PersistentGameState state,
    required GameCommand command,
    required String actorPlayerId,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    switch (command) {
      case FoundCityCommand():
        final result = const PersistentCityFoundingResolver().foundCity(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
          cityRuleset: ruleset.city,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
          reason: result.reason,
        );
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
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
          reason: result.reason,
        );
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
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
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
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case StartCityProjectCommand():
        final result = const PersistentCityProductionResolver()
            .startCityProject(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              cityRuleset: ruleset.city,
              paceBalance: ruleset.paceBalance,
            );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case SetCitySpecializationCommand():
        final result = const PersistentCityProductionResolver()
            .setCitySpecialization(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case MoveUnitCommand():
        final result = const PersistentMoveUnitResolver().resolve(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
          reason: result.reason,
        );
      case AssignMerchantTradeRouteCommand():
        final result = const PersistentMerchantTradeRouteResolver().assignRoute(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapData: _EconomySimulationSetup.mapDataFromDefinition(mapDefinition),
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
          reason: result.reason,
        );
      case MoveMerchantToCityCommand():
        final result = const PersistentMerchantTradeRouteResolver().moveToCity(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapData: _EconomySimulationSetup.mapDataFromDefinition(mapDefinition),
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
          reason: result.reason,
        );
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
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case AssignWorkerToHexCommand():
        final result = const PersistentWorkerCommandResolver()
            .assignWorkerToHex(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
              mapDefinition: mapDefinition,
            );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case CancelWorkerJobCommand():
        final result = const PersistentWorkerCommandResolver().cancelWorkerJob(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case CancelWorkerAssignmentCommand():
        final result = const PersistentWorkerCommandResolver()
            .cancelWorkerAssignment(
              state: state,
              command: command,
              actorPlayerId: actorPlayerId,
            );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case SkipUnitTurnCommand():
        final result = const PersistentUnitActionResolver().skipUnitTurn(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case FortifyUnitCommand():
        final result = const PersistentUnitActionResolver().fortifyUnit(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case AutoExploreUnitCommand():
        final result = const PersistentUnitActionResolver().autoExploreUnit(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case CancelUnitActionCommand():
        final result = const PersistentUnitActionResolver().cancelUnitAction(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case DetachTroopCommand():
        final result = const PersistentUnitDetachmentResolver().detachTroop(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
        );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
        );
      case AttackHexCommand():
        return _applyAttackCommand(
          turn: turn,
          tick: tick,
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapDefinition: mapDefinition,
          ruleset: ruleset,
        );
      case TileTappedCommand() ||
          CityTappedCommand() ||
          RushProductionCommand() ||
          EndTurnCommand() ||
          SubmitTurnCommand() ||
          ResetUnitMovementCommand() ||
          SetActivePlayerCommand() ||
          ToggleMoveTargetingCommand() ||
          StartCityFoundingCommand() ||
          CancelCityFoundingCommand() ||
          StartCityWorkedHexSelectionCommand() ||
          CancelCityWorkedHexSelectionCommand() ||
          ToggleWorkedHexCommand() ||
          StartCityExpansionSelectionCommand() ||
          CancelCityExpansionSelectionCommand() ||
          SelectCityExpansionHexCommand() ||
          StartWorkerActionSelectionCommand() ||
          StartMerchantTradeRouteSelectionCommand() ||
          CancelMerchantTradeRouteSelectionCommand() ||
          StartMerchantMoveToCitySelectionCommand() ||
          CancelMerchantMoveToCitySelectionCommand() ||
          ConfirmWorkerImprovementCommand() ||
          CancelWorkerActionSelectionCommand() ||
          CancelResearchSelectionCommand() ||
          SendDiplomaticProposalCommand() ||
          RespondDiplomaticProposalCommand() ||
          SendDiplomaticMessageCommand() ||
          RespondDiplomaticMessageCommand() ||
          DeclareWarCommand() ||
          StartArtifactExcavationCommand() ||
          StoreArtifactInCityCommand() ||
          TradeArtifactCommand() ||
          OpenResourceTradeCommand() ||
          OpenResourceExchangeCommand() ||
          StartAttackTargetingCommand() ||
          CancelAttackTargetingCommand() ||
          StartCommanderMergeSelectionCommand() ||
          CancelCommanderMergeSelectionCommand() ||
          SelectTileCommand() ||
          SelectUnitCommand() ||
          SelectCityCommand() ||
          FocusNextPendingActionCommand() ||
          FocusTurnStartActionCommand():
        return _ApplyCommandResult(
          accepted: false,
          state: state,
          reason: 'unsupported_command_for_simulation',
        );
    }
  }

  _ApplyCommandResult _applyAttackCommand({
    required int turn,
    required int tick,
    required PersistentGameState state,
    required AttackHexCommand command,
    required String actorPlayerId,
    required MapDefinition mapDefinition,
    required GameRuleset ruleset,
  }) {
    final withIntent = state.copyWith(
      runtimeState: state.runtimeState.copyWith(
        intendedAttacks: [
          IntendedAttack(
            attackerUnitId: command.attackerUnitId,
            defenderCol: command.defenderCol,
            defenderRow: command.defenderRow,
            declaredAtTick: tick,
            declaringPlayerId: actorPlayerId,
          ),
        ],
      ),
    );
    final result = PersistentTurnCombatResolver.resolve(
      turn: turn,
      state: withIntent,
      mapDefinition: mapDefinition,
      ruleset: ruleset,
    );
    final nextState = result.state.copyWith(
      runtimeState: result.state.runtimeState.copyWith(
        intendedAttacks: const [],
      ),
    );
    return _ApplyCommandResult(
      accepted: result.events.isNotEmpty,
      state: nextState,
      events: result.events,
      reason: result.events.isEmpty ? 'attack_not_resolved' : null,
    );
  }
}

class _ApplyCommandResult {
  const _ApplyCommandResult({
    required this.accepted,
    required this.state,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final PersistentGameState state;
  final List<GameEvent> events;
  final String? reason;
}
