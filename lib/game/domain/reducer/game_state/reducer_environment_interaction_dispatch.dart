import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/reducer_environment.dart';
import 'package:aonw/game/domain/reducer/interaction/selection_reducer.dart';
import 'package:aonw/game/domain/reducer/turn/turn_reducer.dart';
import 'package:aonw_core/game/domain/command.dart';

extension ReducerEnvironmentInteractionDispatch on ReducerEnvironment {
  GameStateTransition selectTile(GameState state, SelectTileCommand command) {
    return GameStateTransition(
      state: SelectionReducer.selectTile(state, command, mapData),
    );
  }

  GameStateTransition selectUnit(GameState state, SelectUnitCommand command) {
    return GameStateTransition(
      state: SelectionReducer.selectUnit(state, command, mapData),
    );
  }

  GameStateTransition selectCity(GameState state, SelectCityCommand command) {
    return GameStateTransition(
      state: SelectionReducer.selectCity(
        state,
        command,
        mapData,
        ruleset: ruleset,
        paceBalance: paceBalance,
      ),
    );
  }

  GameStateTransition handleSelectionTileTapped(
    GameState state,
    TileTappedCommand command,
  ) {
    return SelectionReducer.handleTileTapped(
      state,
      command,
      mapData,
      ruleset: ruleset,
      paceBalance: paceBalance,
    );
  }

  GameStateTransition handleSelectionCityTapped(
    GameState state,
    GameCity city,
  ) {
    return GameStateTransition(
      state: SelectionReducer.handleCityTapped(
        state,
        city,
        mapData,
        ruleset: ruleset,
        paceBalance: paceBalance,
      ),
    );
  }

  GameStateTransition focusNextPendingAction(
    GameState state,
    FocusNextPendingActionCommand command,
  ) {
    return TurnReducer.focusNextPendingAction(
      state,
      command.playerId,
      mapData,
      ruleset: ruleset,
      paceBalance: paceBalance,
      preferredObjectiveAdvice: command.preferredObjectiveAdvice,
      actionIndex: command.actionIndex,
      actionStep: command.actionStep,
    );
  }

  GameStateTransition focusTurnStartAction(
    GameState state,
    FocusTurnStartActionCommand command,
  ) {
    return TurnReducer.focusTurnStartAction(
      state,
      command.playerId,
      mapData,
      ruleset: ruleset,
      paceBalance: paceBalance,
    );
  }
}
