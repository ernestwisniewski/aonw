import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_founding_reducer.dart';
import 'package:aonw/game/domain/reducer/combat/combat_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment_dispatch.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment_interaction_dispatch.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';

part 'game_state_reducer_active_player.dart';
part 'game_state_reducer_interaction_state.dart';
part 'game_state_reducer_taps.dart';

class GameStateReducer {
  final MapData mapData;
  final GameRuleset ruleset;

  const GameStateReducer({
    required this.mapData,
    this.ruleset = GameRuleset.defaults,
  });

  GameStateTransition reduce(
    GameState state,
    GameCommand command, {
    GameCommandContext context = const GameCommandContext(),
  }) {
    return reduceWithEnvironment(
      state,
      command,
      ReducerEnvironment(mapData: mapData, ruleset: ruleset, context: context),
    );
  }

  GameStateTransition reduceWithEnvironment(
    GameState state,
    GameCommand command,
    ReducerEnvironment environment,
  ) {
    return switch (command) {
      SetActivePlayerCommand() => _ActivePlayerReducer.handleSetActivePlayer(
        state,
        command,
        environment,
      ),
      TileTappedCommand() => _GameStateTapReducer.handleTileTapped(
        state,
        command,
        environment,
      ),
      CityTappedCommand() => _GameStateTapReducer.handleCityTapped(
        state,
        command,
        environment,
      ),
      MoveUnitCommand() => MovementReducer.moveUnitWithEnvironment(
        state,
        command,
        environment,
      ),
      CancelUnitActionCommand() =>
        MovementReducer.cancelUnitActionWithEnvironment(
          state,
          command,
          environment,
        ),
      SkipUnitTurnCommand() => MovementReducer.skipUnitTurnWithEnvironment(
        state,
        command,
        environment,
      ),
      FortifyUnitCommand() => MovementReducer.fortifyUnitWithEnvironment(
        state,
        command,
        environment,
      ),
      AutoExploreUnitCommand() =>
        MovementReducer.autoExploreUnitWithEnvironment(
          state,
          command,
          environment,
        ),
      StartMerchantTradeRouteSelectionCommand() =>
        environment.startMerchantTradeRouteSelection(state, command),
      CancelMerchantTradeRouteSelectionCommand() =>
        environment.cancelMerchantTradeRouteSelection(state, command),
      AssignMerchantTradeRouteCommand() => environment.assignMerchantTradeRoute(
        state,
        command,
      ),
      StartMerchantMoveToCitySelectionCommand() =>
        environment.startMerchantMoveToCitySelection(state, command),
      CancelMerchantMoveToCitySelectionCommand() =>
        environment.cancelMerchantMoveToCitySelection(state, command),
      MoveMerchantToCityCommand() => environment.moveMerchantToCity(
        state,
        command,
      ),
      StartArtifactExcavationCommand() => environment.startArtifactExcavation(
        state,
        command,
      ),
      StoreArtifactInCityCommand() => environment.storeArtifactInCity(
        state,
        command,
      ),
      TradeArtifactCommand() => environment.tradeArtifact(state, command),
      OpenResourceTradeCommand() => environment.openResourceTrade(
        state,
        command,
      ),
      OpenResourceExchangeCommand() => environment.openResourceExchange(
        state,
        command,
      ),
      FoundCityCommand() => environment.foundCity(state, command),
      StartBuildingCommand() => environment.startBuilding(state, command),
      StartUnitProductionCommand() => environment.startUnitProduction(
        state,
        command,
      ),
      StartCityProjectCommand() => environment.startCityProject(state, command),
      SetCitySpecializationCommand() => environment.setCitySpecialization(
        state,
        command,
      ),
      RushProductionCommand() => environment.rushProduction(state, command),
      SelectTechnologyCommand() => environment.selectTechnology(state, command),
      CancelResearchSelectionCommand() => environment.cancelResearchSelection(
        state,
        command,
      ),
      DetachTroopCommand() => environment.detachTroop(state, command),
      EndTurnCommand() => environment.endTurn(state, command),
      SubmitTurnCommand() => environment.submitTurn(state, command),
      ResetUnitMovementCommand(:final playerId) =>
        MovementReducer.resetUnitMovementForNewTurnWithEnvironment(
          state,
          environment,
          playerId: playerId,
        ),
      ToggleMoveTargetingCommand() => GameStateTransition(
        state: MovementReducer.toggleMoveTargetingWithEnvironment(
          state,
          environment,
        ),
      ),
      StartCityFoundingCommand() => environment.startCityFounding(state),
      CancelCityFoundingCommand() => environment.cancelCityFounding(state),
      StartCityWorkedHexSelectionCommand() =>
        environment.startCityWorkedHexSelection(state, command),
      CancelCityWorkedHexSelectionCommand() =>
        environment.cancelCityWorkedHexSelection(state, command),
      ToggleWorkedHexCommand() => environment.toggleWorkedHex(state, command),
      StartCityExpansionSelectionCommand() =>
        environment.startCityExpansionSelection(state, command),
      CancelCityExpansionSelectionCommand() =>
        environment.cancelCityExpansionSelection(state, command),
      SelectCityExpansionHexCommand() => environment.selectCityExpansionHex(
        state,
        command,
      ),
      StartWorkerActionSelectionCommand() =>
        environment.startWorkerActionSelection(state, command),
      SelectWorkerImprovementCommand() => environment.selectWorkerImprovement(
        state,
        command,
      ),
      ConfirmWorkerImprovementCommand() => environment.confirmWorkerImprovement(
        state,
        command,
      ),
      CancelWorkerActionSelectionCommand() =>
        environment.cancelWorkerActionSelection(state, command),
      CancelWorkerJobCommand() => environment.cancelWorkerJob(state, command),
      AssignWorkerToHexCommand() => environment.assignWorkerToHex(
        state,
        command,
      ),
      CancelWorkerAssignmentCommand() => environment.cancelWorkerAssignment(
        state,
        command,
      ),
      StartAttackTargetingCommand() => environment.startAttackTargeting(
        state,
        command,
      ),
      CancelAttackTargetingCommand() => environment.cancelAttackTargeting(
        state,
        command,
      ),
      AttackHexCommand() => environment.attackHex(state, command),
      StartCommanderMergeSelectionCommand() =>
        environment.startCommanderMergeSelection(state, command),
      CancelCommanderMergeSelectionCommand() =>
        environment.cancelCommanderMergeSelection(state, command),
      SelectTileCommand() => environment.selectTile(state, command),
      SelectUnitCommand() => _GameStateTapReducer.handleUnitSelected(
        state,
        command,
        environment,
      ),
      SelectCityCommand() => environment.selectCity(state, command),
      FocusNextPendingActionCommand() => environment.focusNextPendingAction(
        state,
        command,
      ),
      FocusTurnStartActionCommand() => environment.focusTurnStartAction(
        state,
        command,
      ),
      SendDiplomaticProposalCommand() => environment.sendDiplomaticProposal(
        state,
        command,
      ),
      RespondDiplomaticProposalCommand() =>
        environment.respondDiplomaticProposal(state, command),
      DeclareWarCommand() => environment.declareWar(state, command),
      SendGoldGiftCommand() => environment.sendGoldGift(state, command),
      SendDiplomaticMessageCommand() => environment.sendDiplomaticMessage(
        state,
        command,
      ),
      RespondDiplomaticMessageCommand() => environment.respondDiplomaticMessage(
        state,
        command,
      ),
    };
  }
}
