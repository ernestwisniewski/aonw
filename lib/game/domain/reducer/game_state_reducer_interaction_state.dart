part of 'game_state_reducer.dart';

GameState _clearMapInteractionState(
  GameState state, {
  bool clearPendingAction = false,
}) {
  var next = state.copyWith(moveCommandActive: false);
  next = next.copyWith(movePreview: null);
  next = next.copyWith(cityFoundingDraft: null);
  if (clearPendingAction) {
    next = next.copyWith(pendingAction: null);
  }
  return next;
}
