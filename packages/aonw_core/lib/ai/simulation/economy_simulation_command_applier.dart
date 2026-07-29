part of 'economy_simulation.dart';

final class _EconomySimulationCommandApplier {
  _EconomySimulationCommandApplier(this.mapView, this.engineSnapshot);

  final MapReadView mapView;
  CanonicalGameSnapshot engineSnapshot;
  MapTileLookup get mapTiles => mapView;

  _ApplyCommandResult apply({
    required int turn,
    required int tick,
    required PersistentGameState state,
    required GameCommand command,
    required String actorPlayerId,
    required GameRuleset ruleset,
  }) {
    switch (command) {
      case FoundCityCommand():
        final result = const PersistentCityFoundingResolver().foundCity(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapTiles: mapView,
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
              mapTiles: mapView,
              ruleset: ruleset.technology,
              paceBalance: ruleset.paceBalance,
            );
        return _ApplyCommandResult(
          accepted: result.accepted,
          state: result.state,
          reason: result.reason,
        );
      case StartBuildingCommand() ||
          StartUnitProductionCommand() ||
          StartCityProjectCommand() ||
          StartWonderCommand():
        return _applyProductionCommand(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          ruleset: ruleset,
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
        return _applyMoveUnit(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
        );
      case AssignMerchantTradeRouteCommand():
        final result = const PersistentMerchantTradeRouteResolver().assignRoute(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
          mapData: mapView,
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
          mapData: mapView,
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
              mapTiles: mapView,
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
              mapTiles: mapView,
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
      case FortifyUnitCommand():
        return _applyEngineUnitAction(
          tick: tick,
          state: state,
          command: command as DomainCommand,
          actorPlayerId: actorPlayerId,
          ruleset: ruleset,
        );
      case AutoExploreUnitCommand():
        return _applyAutoExplore(
          state: state,
          command: command,
          actorPlayerId: actorPlayerId,
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
          mapTiles: mapView,
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
          mapTiles: mapTiles,
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
          SendGoldGiftCommand() ||
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

  _ApplyCommandResult _applyEngineUnitAction({
    required int tick,
    required PersistentGameState state,
    required DomainCommand command,
    required String actorPlayerId,
    required GameRuleset ruleset,
  }) {
    final result = const SimulationGameEngineAdapter().apply(
      snapshot: engineSnapshot,
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      commandTick: tick,
      mapView: mapView,
      ruleset: ruleset,
    );
    engineSnapshot = result.snapshot;
    return _ApplyCommandResult(
      accepted: result.accepted,
      state: result.state,
      reason: result.reason,
    );
  }

  _ApplyCommandResult _applyMoveUnit({
    required PersistentGameState state,
    required MoveUnitCommand command,
    required String actorPlayerId,
  }) {
    final result = const PersistentMoveUnitResolver().resolve(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      mapData: mapView,
      visibilityMode: MovementCommandVisibilityMode.unrestrictedPathing,
    );
    return _ApplyCommandResult(
      accepted: result.accepted,
      state: result.state,
      reason: result.reason,
    );
  }

  _ApplyCommandResult _applyAutoExplore({
    required PersistentGameState state,
    required AutoExploreUnitCommand command,
    required String actorPlayerId,
  }) {
    final result = const PersistentAutoExploreCommandResolver().resolve(
      state: state,
      command: command,
      actorPlayerId: actorPlayerId,
      mapData: mapView,
      phase: AutoExploreCommandPhase.direct,
    );
    return _ApplyCommandResult(
      accepted: result.accepted,
      state: result.state,
      events: result.events,
      reason: result.reason,
    );
  }

  _ApplyCommandResult _applyAttackCommand({
    required int turn,
    required int tick,
    required PersistentGameState state,
    required AttackHexCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
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
      mapTiles: mapTiles,
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

_EconomySimulationCommandApplier _economySimulationCommandApplierForSetup({
  required EconomySimulationConfig config,
  required PersistentGameState state,
  required MapReadView mapView,
}) {
  return _EconomySimulationCommandApplier(
    mapView,
    _EconomySimulationSetup.engineSnapshot(
      config: config,
      state: state,
      mapView: mapView,
    ),
  );
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
