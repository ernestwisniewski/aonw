part of 'game_state_reducer.dart';

GameState _clearMapInteractionState(
  GameState state, {
  bool clearPendingAction = false,
}) {
  return state.copyWith(
    interaction: state.interaction.clearMapState(
      clearPendingAction: clearPendingAction,
    ),
  );
}
