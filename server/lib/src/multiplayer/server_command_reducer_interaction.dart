part of 'server_command_reducer.dart';

PersistedInteractionState _persistedInteraction(PersistentGameState state) {
  return PersistedInteractionState(
    cityFoundingDraft: state.runtimeState.cityFoundingDraft,
    pendingAction: state.runtimeState.pendingAction,
  );
}

GameRuntimeState _runtimeStateWithInteraction(
  GameRuntimeState runtimeState,
  PersistedInteractionState interaction,
) {
  if (runtimeState.cityFoundingDraft == interaction.cityFoundingDraft &&
      runtimeState.pendingAction == interaction.pendingAction) {
    return runtimeState;
  }
  return runtimeState.copyWith(
    cityFoundingDraft: interaction.cityFoundingDraft,
    pendingAction: interaction.pendingAction,
  );
}
