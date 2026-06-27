import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/artifact/artifact_reducer.dart';
import 'package:aonw/game/domain/reducer/city/city_expansion_reducer.dart';
import 'package:aonw/game/domain/reducer/city/city_founding_reducer.dart';
import 'package:aonw/game/domain/reducer/city/city_production_reducer.dart';
import 'package:aonw/game/domain/reducer/city/city_worked_hex_reducer.dart';
import 'package:aonw/game/domain/reducer/combat/combat_reducer.dart';
import 'package:aonw/game/domain/reducer/diplomacy/merchant_trade_route_reducer.dart';
import 'package:aonw/game/domain/reducer/diplomacy/resource_trade_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw/game/domain/reducer/interaction/interaction_reducer.dart';
import 'package:aonw/game/domain/reducer/research/research_reducer.dart';
import 'package:aonw/game/domain/reducer/turn/turn_reducer.dart';
import 'package:aonw/game/domain/reducer/unit/unit_attachment_reducer.dart';
import 'package:aonw/game/domain/reducer/worker/worker_reducer.dart';
import 'package:aonw_core/game/domain/command.dart';

extension ReducerEnvironmentDispatch on ReducerEnvironment {
  GameStateTransition startMerchantTradeRouteSelection(
    GameState state,
    StartMerchantTradeRouteSelectionCommand command,
  ) {
    return MerchantTradeRouteReducer.startSelection(
      state,
      command,
      mapData,
      context: context,
    );
  }

  GameStateTransition cancelMerchantTradeRouteSelection(
    GameState state,
    CancelMerchantTradeRouteSelectionCommand command,
  ) {
    return MerchantTradeRouteReducer.cancelSelection(state, command);
  }

  GameStateTransition assignMerchantTradeRoute(
    GameState state,
    AssignMerchantTradeRouteCommand command,
  ) {
    return MerchantTradeRouteReducer.assignRoute(
      state,
      command,
      mapData,
      context: context,
    );
  }

  GameStateTransition startMerchantMoveToCitySelection(
    GameState state,
    StartMerchantMoveToCitySelectionCommand command,
  ) {
    return MerchantTradeRouteReducer.startMoveToCitySelection(
      state,
      command,
      mapData,
      context: context,
    );
  }

  GameStateTransition cancelMerchantMoveToCitySelection(
    GameState state,
    CancelMerchantMoveToCitySelectionCommand command,
  ) {
    return MerchantTradeRouteReducer.cancelMoveToCitySelection(state, command);
  }

  GameStateTransition moveMerchantToCity(
    GameState state,
    MoveMerchantToCityCommand command,
  ) {
    return MerchantTradeRouteReducer.moveToCity(
      state,
      command,
      mapData,
      context: context,
    );
  }

  GameStateTransition startArtifactExcavation(
    GameState state,
    StartArtifactExcavationCommand command,
  ) {
    return ArtifactReducer.startExcavation(state, command, context: context);
  }

  GameStateTransition storeArtifactInCity(
    GameState state,
    StoreArtifactInCityCommand command,
  ) {
    return ArtifactReducer.storeInCity(state, command, context: context);
  }

  GameStateTransition tradeArtifact(
    GameState state,
    TradeArtifactCommand command,
  ) {
    return ArtifactReducer.tradeArtifact(state, command, context: context);
  }

  GameStateTransition openResourceTrade(
    GameState state,
    OpenResourceTradeCommand command,
  ) {
    return ResourceTradeReducer.openTrade(
      state,
      command,
      mapData,
      context: context,
    );
  }

  GameStateTransition openResourceExchange(
    GameState state,
    OpenResourceExchangeCommand command,
  ) {
    return ResourceTradeReducer.openExchange(
      state,
      command,
      mapData,
      context: context,
    );
  }

  GameStateTransition foundCity(GameState state, FoundCityCommand command) {
    return CityFoundingReducer.confirmCityFounding(
      state,
      mapData,
      command: command,
      context: context,
      fogOfWarService: fogOfWarService,
      cityRuleset: cityRuleset,
    );
  }

  GameStateTransition startBuilding(
    GameState state,
    StartBuildingCommand command,
  ) {
    return CityProductionReducer.startBuilding(
      state,
      command,
      mapData,
      context: context,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );
  }

  GameStateTransition startUnitProduction(
    GameState state,
    StartUnitProductionCommand command,
  ) {
    return CityProductionReducer.startUnitProduction(
      state,
      command,
      mapData,
      context: context,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );
  }

  GameStateTransition startCityProject(
    GameState state,
    StartCityProjectCommand command,
  ) {
    return CityProductionReducer.startCityProject(
      state,
      command,
      mapData,
      context: context,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );
  }

  GameStateTransition setCitySpecialization(
    GameState state,
    SetCitySpecializationCommand command,
  ) {
    return CityProductionReducer.setCitySpecialization(
      state,
      command,
      mapData,
      context: context,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );
  }

  GameStateTransition rushProduction(
    GameState state,
    RushProductionCommand command,
  ) {
    return CityProductionReducer.rushProduction(
      state,
      command,
      mapData,
      context: context,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );
  }

  GameStateTransition selectTechnology(
    GameState state,
    SelectTechnologyCommand command,
  ) {
    return ResearchReducer.selectTechnology(
      state,
      command,
      context: context,
      mapData: mapData,
      ruleset: technologyRuleset,
    );
  }

  GameStateTransition cancelResearchSelection(
    GameState state,
    CancelResearchSelectionCommand command,
  ) {
    return GameStateTransition(
      state: ResearchReducer.cancelResearchSelection(
        state,
        command,
        context: context,
      ),
    );
  }

  GameStateTransition detachTroop(GameState state, DetachTroopCommand command) {
    return UnitAttachmentReducer.detachTroop(
      state,
      command,
      mapData,
      context: context,
      fogOfWarService: fogOfWarService,
    );
  }

  GameStateTransition endTurn(GameState state, EndTurnCommand command) {
    return TurnReducer.advanceCitiesForPlayer(
      state,
      command.playerId,
      mapData,
      fogOfWarService: fogOfWarService,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  GameStateTransition submitTurn(GameState state, SubmitTurnCommand command) {
    return TurnReducer.submitTurn(state, command.playerId);
  }

  GameStateTransition startCityFounding(GameState state) {
    return GameStateTransition(
      state: CityFoundingReducer.startCityFounding(
        state,
        mapData,
        context: context,
        cityRuleset: cityRuleset,
      ),
    );
  }

  GameStateTransition cancelCityFounding(GameState state) {
    return GameStateTransition(
      state: CityFoundingReducer.cancelCityFounding(state),
    );
  }

  GameStateTransition startCityWorkedHexSelection(
    GameState state,
    StartCityWorkedHexSelectionCommand command,
  ) {
    return GameStateTransition(
      state: InteractionReducer.startCityWorkedHexSelection(
        state,
        command,
        context: context,
      ),
    );
  }

  GameStateTransition cancelCityWorkedHexSelection(
    GameState state,
    CancelCityWorkedHexSelectionCommand command,
  ) {
    return GameStateTransition(
      state: InteractionReducer.cancelCityWorkedHexSelection(state, command),
    );
  }

  GameStateTransition toggleWorkedHex(
    GameState state,
    ToggleWorkedHexCommand command,
  ) {
    return CityWorkedHexReducer.toggleWorkedHex(
      state,
      command,
      mapData,
      context: context,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );
  }

  GameStateTransition startCityExpansionSelection(
    GameState state,
    StartCityExpansionSelectionCommand command,
  ) {
    return GameStateTransition(
      state: InteractionReducer.startCityExpansionSelection(
        state,
        command,
        context: context,
      ),
    );
  }

  GameStateTransition cancelCityExpansionSelection(
    GameState state,
    CancelCityExpansionSelectionCommand command,
  ) {
    return GameStateTransition(
      state: InteractionReducer.cancelCityExpansionSelection(state, command),
    );
  }

  GameStateTransition selectCityExpansionHex(
    GameState state,
    SelectCityExpansionHexCommand command,
  ) {
    return CityExpansionReducer.selectExpansionHex(
      state,
      command,
      mapData,
      context: context,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
    );
  }

  GameStateTransition startWorkerActionSelection(
    GameState state,
    StartWorkerActionSelectionCommand command,
  ) {
    return GameStateTransition(
      state: InteractionReducer.startWorkerActionSelection(
        state,
        command,
        context: context,
      ),
    );
  }

  GameStateTransition selectWorkerImprovement(
    GameState state,
    SelectWorkerImprovementCommand command,
  ) {
    return WorkerReducer.selectWorkerImprovement(
      state,
      command,
      mapData,
      context: context,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  GameStateTransition confirmWorkerImprovement(
    GameState state,
    ConfirmWorkerImprovementCommand command,
  ) {
    return WorkerReducer.confirmWorkerImprovement(
      state,
      command,
      mapData,
      context: context,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      paceBalance: paceBalance,
    );
  }

  GameStateTransition cancelWorkerActionSelection(
    GameState state,
    CancelWorkerActionSelectionCommand command,
  ) {
    return GameStateTransition(
      state: InteractionReducer.cancelWorkerActionSelection(state, command),
    );
  }

  GameStateTransition cancelWorkerJob(
    GameState state,
    CancelWorkerJobCommand command,
  ) {
    return WorkerReducer.cancelWorkerJob(
      state,
      command,
      mapData,
      context: context,
    );
  }

  GameStateTransition assignWorkerToHex(
    GameState state,
    AssignWorkerToHexCommand command,
  ) {
    return WorkerReducer.assignWorkerToHex(
      state,
      command,
      mapData,
      context: context,
    );
  }

  GameStateTransition cancelWorkerAssignment(
    GameState state,
    CancelWorkerAssignmentCommand command,
  ) {
    return WorkerReducer.cancelWorkerAssignment(
      state,
      command,
      mapData,
      context: context,
    );
  }

  GameStateTransition startAttackTargeting(
    GameState state,
    StartAttackTargetingCommand command,
  ) {
    return GameStateTransition(
      state: InteractionReducer.startAttackTargeting(
        state,
        command,
        context: context,
      ),
    );
  }

  GameStateTransition cancelAttackTargeting(
    GameState state,
    CancelAttackTargetingCommand command,
  ) {
    return GameStateTransition(
      state: InteractionReducer.cancelAttackTargeting(state, command),
    );
  }

  GameStateTransition attackHex(GameState state, AttackHexCommand command) {
    return CombatReducer.attackHexWithEnvironment(state, command, this);
  }

  GameStateTransition startCommanderMergeSelection(
    GameState state,
    StartCommanderMergeSelectionCommand command,
  ) {
    return GameStateTransition(
      state: InteractionReducer.startCommanderMergeSelection(
        state,
        command,
        context: context,
      ),
    );
  }

  GameStateTransition cancelCommanderMergeSelection(
    GameState state,
    CancelCommanderMergeSelectionCommand command,
  ) {
    return GameStateTransition(
      state: InteractionReducer.cancelCommanderMergeSelection(state, command),
    );
  }
}
