import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/city/city_founding_reducer.dart';
import 'package:aonw/game/domain/reducer/diplomacy/merchant_trade_route_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw/game/domain/reducer/interaction/interaction_reducer.dart';
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
  ) => MerchantTradeRouteReducer.cancelSelection(state, command);

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
  ) => MerchantTradeRouteReducer.cancelMoveToCitySelection(state, command);

  GameStateTransition cancelResearchSelection(
    GameState state,
    CancelResearchSelectionCommand command,
  ) {
    return GameStateTransition(
      state: InteractionReducer.cancelResearchSelection(
        state,
        command,
        context: context,
      ),
    );
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

  GameStateTransition workerInteraction(GameState state, GameIntent command) =>
      GameStateTransition(
        state: switch (command) {
          StartWorkerActionSelectionCommand() =>
            InteractionReducer.startWorkerActionSelection(
              state,
              command,
              context: context,
            ),
          CancelWorkerActionSelectionCommand() =>
            InteractionReducer.cancelWorkerActionSelection(state, command),
          _ => throw UnsupportedError(
            '${command.runtimeType} is not a worker interaction command',
          ),
        },
      );

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
