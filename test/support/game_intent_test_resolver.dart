import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw_core/game/domain/command.dart';

import 'canonical_command_test_dispatch.dart';

GameStateTransition resolveGameIntent(
  GameStateReducer reducer,
  GameState state,
  GameCommand command, {
  GameCommandContext context = const GameCommandContext(),
}) {
  if (command is! GameIntent) {
    return dispatchCanonicalTestCommand(
      reducer: reducer,
      state: state,
      command: command,
      context: context,
    );
  }
  final resolution = GameIntentResolver(
    reducer: reducer,
    context: context,
  ).resolve(state.interaction, command, state);
  final domainCommand = resolution.domainCommand;
  if (domainCommand != null) {
    return dispatchCanonicalTestCommand(
      reducer: reducer,
      state: state,
      command: domainCommand,
      context: context,
    );
  }
  return GameStateTransition(
    state: resolution.interaction == state.interaction
        ? state
        : state.copyWith(interaction: resolution.interaction),
    uiEffects: resolution.presentationFocus,
  );
}
