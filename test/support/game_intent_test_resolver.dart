import 'package:aonw/game/application/services/queued_movement_effect_builder.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';

import 'canonical_command_test_dispatch.dart';

GameStateTransition resolveGameIntent(
  GameStateReducer reducer,
  GameState state,
  Object command, {
  GameCommandContext context = const GameCommandContext(),
}) {
  return dispatchCanonicalTestCommand(
    reducer: reducer,
    state: state,
    command: command,
    context: context,
  );
}

GameStateTransition resolveWithEffects(
  GameStateReducer reducer,
  GameState state,
  Object command, {
  GameCommandContext context = const GameCommandContext(),
}) {
  final transition = resolveGameIntent(
    reducer,
    state,
    command,
    context: context,
  );
  return GameStateTransition(
    state: transition.state,
    events: transition.events,
    uiEffects: [
      ...transition.uiEffects,
      ...QueuedMovementEffectBuilder.fromUnitDelta(
        beforeUnits: state.units,
        afterUnits: transition.state.units,
        inferDirectMoves: true,
      ),
    ],
  );
}
