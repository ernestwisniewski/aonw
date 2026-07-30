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
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';

part 'game_state_reducer_active_player.dart';
part 'game_state_reducer_interaction_state.dart';
part 'game_state_reducer_taps.dart';

class GameStateReducer {
  final MapReadView mapData;
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
      StartMerchantTradeRouteSelectionCommand() =>
        environment.startMerchantTradeRouteSelection(state, command),
      CancelMerchantTradeRouteSelectionCommand() =>
        environment.cancelMerchantTradeRouteSelection(state, command),
      StartMerchantMoveToCitySelectionCommand() =>
        environment.startMerchantMoveToCitySelection(state, command),
      CancelMerchantMoveToCitySelectionCommand() =>
        environment.cancelMerchantMoveToCitySelection(state, command),
      CancelResearchSelectionCommand() => environment.cancelResearchSelection(
        state,
        command,
      ),
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
      StartCityExpansionSelectionCommand() =>
        environment.startCityExpansionSelection(state, command),
      CancelCityExpansionSelectionCommand() =>
        environment.cancelCityExpansionSelection(state, command),
      WorkerInteractionCommand() => environment.workerInteraction(
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
      _ => throw UnsupportedError(
        '${command.runtimeType} is not handled by the legacy reducer',
      ),
    };
  }
}
