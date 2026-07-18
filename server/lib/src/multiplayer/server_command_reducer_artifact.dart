part of 'server_command_reducer.dart';

extension _ServerCommandReducerArtifact on ServerCommandReducer {
  _CommandApplication _applyStartArtifactExcavationCommand({
    required GameSave save,
    required PersistentGameState state,
    required StartArtifactExcavationCommand command,
    required String actorPlayerId,
  }) {
    final result = ArtifactCommandResolver.startExcavation(
      units: state.units,
      artifacts: state.artifacts,
      command: command,
      actorPlayerId: actorPlayerId,
    );
    return _applyArtifactUnitResult(save, state, result);
  }

  _CommandApplication _applyStoreArtifactInCityCommand({
    required GameSave save,
    required PersistentGameState state,
    required StoreArtifactInCityCommand command,
    required String actorPlayerId,
  }) {
    final result = ArtifactCommandResolver.storeInCity(
      units: state.units,
      cities: state.cities,
      artifacts: state.artifacts,
      command: command,
      actorPlayerId: actorPlayerId,
    );
    return _applyArtifactUnitResult(save, state, result);
  }

  _CommandApplication _applyTradeArtifactCommand({
    required GameSave save,
    required PersistentGameState state,
    required TradeArtifactCommand command,
    required String actorPlayerId,
  }) {
    final result = ArtifactCommandResolver.tradeArtifact(
      cities: state.cities,
      artifacts: state.artifacts,
      playerGold: state.playerGold,
      diplomacy: state.runtimeState.diplomacy,
      command: command,
      actorPlayerId: actorPlayerId,
    );
    if (!result.accepted) {
      return _applicationFrom(
        save: save,
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return _applicationFrom(
      save: save,
      accepted: true,
      state: state.copyWith(
        artifacts: result.artifacts,
        playerGold: result.playerGold,
      ),
    );
  }

  _CommandApplication _applyArtifactUnitResult(
    GameSave save,
    PersistentGameState state,
    ArtifactUnitCommandResult result,
  ) {
    if (!result.accepted) {
      return _applicationFrom(
        save: save,
        accepted: false,
        state: state,
        reason: result.reason,
      );
    }
    return _applicationFrom(
      save: save,
      accepted: true,
      state: state.copyWith(units: result.units, artifacts: result.artifacts),
    );
  }
}
