part of 'server_command_reducer.dart';

extension _ServerCommandReducerArtifact on ServerCommandReducer {
  _CommandApplication _applyStartArtifactExcavationCommand({
    required CanonicalGameSnapshot snapshot,
    required StartArtifactExcavationCommand command,
    required String actorPlayerId,
  }) {
    final domain = snapshot.domain;
    final result = ArtifactCommandResolver.startExcavation(
      units: domain.units,
      artifacts: domain.artifacts,
      command: command,
      actorPlayerId: actorPlayerId,
    );
    return _applyArtifactUnitResult(snapshot, result);
  }

  _CommandApplication _applyStoreArtifactInCityCommand({
    required CanonicalGameSnapshot snapshot,
    required StoreArtifactInCityCommand command,
    required String actorPlayerId,
  }) {
    final domain = snapshot.domain;
    final result = ArtifactCommandResolver.storeInCity(
      units: domain.units,
      cities: domain.cities,
      artifacts: domain.artifacts,
      command: command,
      actorPlayerId: actorPlayerId,
    );
    return _applyArtifactUnitResult(snapshot, result);
  }

  _CommandApplication _applyTradeArtifactCommand({
    required CanonicalGameSnapshot snapshot,
    required TradeArtifactCommand command,
    required String actorPlayerId,
  }) {
    final domain = snapshot.domain;
    final result = ArtifactCommandResolver.tradeArtifact(
      cities: domain.cities,
      artifacts: domain.artifacts,
      playerGold: domain.playerGold,
      diplomacy: domain.diplomacy,
      command: command,
      actorPlayerId: actorPlayerId,
    );
    if (!result.accepted) {
      return _applicationFrom(
        snapshot: snapshot,
        accepted: false,
        reason: result.reason,
      );
    }
    final artifactsChanged = !identical(result.artifacts, domain.artifacts);
    final playerGoldChanged = !identical(result.playerGold, domain.playerGold);
    return _applicationFrom(
      snapshot: snapshot,
      accepted: true,
      domain: artifactsChanged || playerGoldChanged
          ? domain.copyWith(
              artifacts: artifactsChanged ? result.artifacts : null,
              playerGold: playerGoldChanged ? result.playerGold : null,
            )
          : null,
    );
  }

  _CommandApplication _applyArtifactUnitResult(
    CanonicalGameSnapshot snapshot,
    ArtifactUnitCommandResult result,
  ) {
    if (!result.accepted) {
      return _applicationFrom(
        snapshot: snapshot,
        accepted: false,
        reason: result.reason,
      );
    }
    final domain = snapshot.domain;
    final unitsChanged = !identical(result.units, domain.units);
    final artifactsChanged = !identical(result.artifacts, domain.artifacts);
    return _applicationFrom(
      snapshot: snapshot,
      accepted: true,
      domain: unitsChanged || artifactsChanged
          ? domain.copyWith(
              units: unitsChanged ? result.units : null,
              artifacts: artifactsChanged ? result.artifacts : null,
            )
          : null,
    );
  }
}
