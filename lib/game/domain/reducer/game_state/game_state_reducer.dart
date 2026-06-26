import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/artifact/artifact_reducer.dart';
import 'package:aonw/game/domain/reducer/city/city_expansion_reducer.dart';
import 'package:aonw/game/domain/reducer/city/city_founding_reducer.dart';
import 'package:aonw/game/domain/reducer/city/city_production_reducer.dart';
import 'package:aonw/game/domain/reducer/city/city_worked_hex_reducer.dart';
import 'package:aonw/game/domain/reducer/combat/combat_reducer.dart';
import 'package:aonw/game/domain/reducer/diplomacy/diplomacy_reducer.dart';
import 'package:aonw/game/domain/reducer/diplomacy/merchant_trade_route_reducer.dart';
import 'package:aonw/game/domain/reducer/diplomacy/resource_trade_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_player_ids.dart';
import 'package:aonw/game/domain/reducer/interaction/interaction_reducer.dart';
import 'package:aonw/game/domain/reducer/interaction/selection_reducer.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw/game/domain/reducer/research/research_reducer.dart';
import 'package:aonw/game/domain/reducer/turn/turn_reducer.dart';
import 'package:aonw/game/domain/reducer/unit/unit_attachment_reducer.dart';
import 'package:aonw/game/domain/reducer/worker/worker_reducer.dart';
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
    final mapData = environment.mapData;
    final ruleset = environment.ruleset;
    final context = environment.context;

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
        MerchantTradeRouteReducer.startSelection(
          state,
          command,
          mapData,
          context: context,
        ),
      CancelMerchantTradeRouteSelectionCommand() =>
        MerchantTradeRouteReducer.cancelSelection(state, command),
      AssignMerchantTradeRouteCommand() =>
        MerchantTradeRouteReducer.assignRoute(
          state,
          command,
          mapData,
          context: context,
        ),
      StartMerchantMoveToCitySelectionCommand() =>
        MerchantTradeRouteReducer.startMoveToCitySelection(
          state,
          command,
          mapData,
          context: context,
        ),
      CancelMerchantMoveToCitySelectionCommand() =>
        MerchantTradeRouteReducer.cancelMoveToCitySelection(state, command),
      MoveMerchantToCityCommand() => MerchantTradeRouteReducer.moveToCity(
        state,
        command,
        mapData,
        context: context,
      ),
      StartArtifactExcavationCommand() => ArtifactReducer.startExcavation(
        state,
        command,
        context: context,
      ),
      StoreArtifactInCityCommand() => ArtifactReducer.storeInCity(
        state,
        command,
        context: context,
      ),
      TradeArtifactCommand() => ArtifactReducer.tradeArtifact(
        state,
        command,
        context: context,
      ),
      OpenResourceTradeCommand() => ResourceTradeReducer.openTrade(
        state,
        command,
        mapData,
        context: context,
      ),
      OpenResourceExchangeCommand() => ResourceTradeReducer.openExchange(
        state,
        command,
        mapData,
        context: context,
      ),
      FoundCityCommand() => CityFoundingReducer.confirmCityFounding(
        state,
        mapData,
        command: command,
        context: context,
        cityRuleset: ruleset.city,
      ),
      StartBuildingCommand() => CityProductionReducer.startBuilding(
        state,
        command,
        mapData,
        context: context,
        cityRuleset: ruleset.city,
        technologyRuleset: ruleset.technology,
      ),
      StartUnitProductionCommand() => CityProductionReducer.startUnitProduction(
        state,
        command,
        mapData,
        context: context,
        cityRuleset: ruleset.city,
        technologyRuleset: ruleset.technology,
      ),
      StartCityProjectCommand() => CityProductionReducer.startCityProject(
        state,
        command,
        mapData,
        context: context,
        cityRuleset: ruleset.city,
        technologyRuleset: ruleset.technology,
      ),
      SetCitySpecializationCommand() =>
        CityProductionReducer.setCitySpecialization(
          state,
          command,
          mapData,
          context: context,
          cityRuleset: ruleset.city,
          technologyRuleset: ruleset.technology,
        ),
      RushProductionCommand() => CityProductionReducer.rushProduction(
        state,
        command,
        mapData,
        context: context,
        cityRuleset: ruleset.city,
        technologyRuleset: ruleset.technology,
      ),
      SelectTechnologyCommand() => ResearchReducer.selectTechnology(
        state,
        command,
        context: context,
        mapData: mapData,
        ruleset: ruleset.technology,
      ),
      CancelResearchSelectionCommand() => GameStateTransition(
        state: ResearchReducer.cancelResearchSelection(
          state,
          command,
          context: context,
        ),
      ),
      DetachTroopCommand() => UnitAttachmentReducer.detachTroop(
        state,
        command,
        mapData,
        context: context,
      ),
      EndTurnCommand(:final playerId) => TurnReducer.advanceCitiesForPlayer(
        state,
        playerId,
        mapData,
        cityRuleset: ruleset.city,
        technologyRuleset: ruleset.technology,
        paceBalance: context.paceBalance,
      ),
      SubmitTurnCommand(:final playerId) => TurnReducer.submitTurn(
        state,
        playerId,
      ),
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
      StartCityFoundingCommand() => GameStateTransition(
        state: CityFoundingReducer.startCityFounding(
          state,
          mapData,
          context: context,
          cityRuleset: ruleset.city,
        ),
      ),
      CancelCityFoundingCommand() => GameStateTransition(
        state: CityFoundingReducer.cancelCityFounding(state),
      ),
      StartCityWorkedHexSelectionCommand() => GameStateTransition(
        state: InteractionReducer.startCityWorkedHexSelection(
          state,
          command,
          context: context,
        ),
      ),
      CancelCityWorkedHexSelectionCommand() => GameStateTransition(
        state: InteractionReducer.cancelCityWorkedHexSelection(state, command),
      ),
      ToggleWorkedHexCommand() => CityWorkedHexReducer.toggleWorkedHex(
        state,
        command,
        mapData,
        context: context,
        cityRuleset: ruleset.city,
        technologyRuleset: ruleset.technology,
      ),
      StartCityExpansionSelectionCommand() => GameStateTransition(
        state: InteractionReducer.startCityExpansionSelection(
          state,
          command,
          context: context,
        ),
      ),
      CancelCityExpansionSelectionCommand() => GameStateTransition(
        state: InteractionReducer.cancelCityExpansionSelection(state, command),
      ),
      SelectCityExpansionHexCommand() =>
        CityExpansionReducer.selectExpansionHex(
          state,
          command,
          mapData,
          context: context,
          cityRuleset: ruleset.city,
          technologyRuleset: ruleset.technology,
        ),
      StartWorkerActionSelectionCommand() => GameStateTransition(
        state: InteractionReducer.startWorkerActionSelection(
          state,
          command,
          context: context,
        ),
      ),
      SelectWorkerImprovementCommand() => WorkerReducer.selectWorkerImprovement(
        state,
        command,
        mapData,
        context: context,
        cityRuleset: ruleset.city,
        technologyRuleset: ruleset.technology,
        paceBalance: context.paceBalance,
      ),
      ConfirmWorkerImprovementCommand() =>
        WorkerReducer.confirmWorkerImprovement(
          state,
          command,
          mapData,
          context: context,
          cityRuleset: ruleset.city,
          technologyRuleset: ruleset.technology,
          paceBalance: context.paceBalance,
        ),
      CancelWorkerActionSelectionCommand() => GameStateTransition(
        state: InteractionReducer.cancelWorkerActionSelection(state, command),
      ),
      CancelWorkerJobCommand() => WorkerReducer.cancelWorkerJob(
        state,
        command,
        mapData,
        context: context,
      ),
      AssignWorkerToHexCommand() => WorkerReducer.assignWorkerToHex(
        state,
        command,
        mapData,
        context: context,
      ),
      CancelWorkerAssignmentCommand() => WorkerReducer.cancelWorkerAssignment(
        state,
        command,
        mapData,
        context: context,
      ),
      StartAttackTargetingCommand() => GameStateTransition(
        state: InteractionReducer.startAttackTargeting(
          state,
          command,
          context: context,
        ),
      ),
      CancelAttackTargetingCommand() => GameStateTransition(
        state: InteractionReducer.cancelAttackTargeting(state, command),
      ),
      AttackHexCommand() => CombatReducer.attackHexWithEnvironment(
        state,
        command,
        environment,
      ),
      StartCommanderMergeSelectionCommand() => GameStateTransition(
        state: InteractionReducer.startCommanderMergeSelection(
          state,
          command,
          context: context,
        ),
      ),
      CancelCommanderMergeSelectionCommand() => GameStateTransition(
        state: InteractionReducer.cancelCommanderMergeSelection(state, command),
      ),
      SelectTileCommand() => GameStateTransition(
        state: SelectionReducer.selectTile(state, command, mapData),
      ),
      SelectUnitCommand() => _GameStateTapReducer.handleUnitSelected(
        state,
        command,
        environment,
      ),
      SelectCityCommand() => GameStateTransition(
        state: SelectionReducer.selectCity(
          state,
          command,
          mapData,
          cityRuleset: ruleset.city,
          technologyRuleset: ruleset.technology,
          paceBalance: context.paceBalance,
        ),
      ),
      FocusNextPendingActionCommand(
        :final playerId,
        :final preferredObjectiveAdvice,
        :final actionIndex,
      ) =>
        TurnReducer.focusNextPendingAction(
          state,
          playerId,
          mapData,
          cityRuleset: ruleset.city,
          technologyRuleset: ruleset.technology,
          paceBalance: context.paceBalance,
          preferredObjectiveAdvice: preferredObjectiveAdvice,
          actionIndex: actionIndex,
        ),
      FocusTurnStartActionCommand(:final playerId) =>
        TurnReducer.focusTurnStartAction(
          state,
          playerId,
          mapData,
          cityRuleset: ruleset.city,
          technologyRuleset: ruleset.technology,
          paceBalance: context.paceBalance,
        ),
      SendDiplomaticProposalCommand() => DiplomacyReducer.sendProposal(
        state,
        command,
        context: context,
      ),
      RespondDiplomaticProposalCommand() => DiplomacyReducer.respondProposal(
        state,
        command,
        context: context,
      ),
      DeclareWarCommand() => DiplomacyReducer.declareWar(
        state,
        command,
        context: context,
      ),
      SendDiplomaticMessageCommand() => DiplomacyReducer.sendMessage(
        state,
        command,
        context: context,
      ),
      RespondDiplomaticMessageCommand() => DiplomacyReducer.respondMessage(
        state,
        command,
        context: context,
      ),
    };
  }
}
