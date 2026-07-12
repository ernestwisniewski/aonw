import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/turn/turn_reducer.dart';
import 'package:aonw_core/game/domain/command.dart';

abstract final class SubmitTurnReducer {
  static GameStateTransition submit(
    GameState state,
    SubmitTurnCommand command,
    String? actorPlayerId,
  ) {
    if (actorPlayerId != null &&
        actorPlayerId.isNotEmpty &&
        actorPlayerId != command.playerId) {
      return GameStateTransition(state: state);
    }
    return TurnReducer.submitTurn(state, command.playerId);
  }
}
