part of 'game_state_reducer.dart';

GameClientState _clearMapInteractionState(
  GameClientState state, {
  bool clearPendingAction = false,
}) {
  return state.copyWith(
    interaction: state.interaction.clearMapState(
      clearPendingAction: clearPendingAction,
    ),
  );
}
