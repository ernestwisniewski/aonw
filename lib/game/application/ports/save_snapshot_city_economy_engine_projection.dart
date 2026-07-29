part of 'save_snapshot.dart';

extension SaveSnapshotCityEconomyEngineProjection on SaveSnapshot {
  /// Applies only the slices owned by city, production, worker, artifact, and
  /// resource-trade commands while preserving the raw persistence envelope.
  SaveSnapshot withCityEconomyEngineProjection({
    required CanonicalGameSnapshot resultSnapshot,
    required DateTime savedAt,
  }) {
    final domain = resultSnapshot.domain;
    final runtime = _rawState.runtimeState;
    final interaction = resultSnapshot.interaction;
    final runtimeChanged =
        !identical(
          domain.resourceTradeAgreements,
          runtime.resourceTradeAgreements,
        ) ||
        runtime.cityFoundingDraft != interaction.cityFoundingDraft ||
        runtime.pendingAction != interaction.pendingAction;
    final projectedRawState = _rawState.copyWith(
      playerGold: identical(domain.playerGold, playerGold)
          ? null
          : domain.playerGold,
      units: identical(domain.units, units) ? null : domain.units,
      cities: identical(domain.cities, cities) ? null : domain.cities,
      artifacts: identical(domain.artifacts, artifacts)
          ? null
          : domain.artifacts,
      research: identical(domain.research, research) ? null : domain.research,
      wonderRegistry: identical(domain.wonderRegistry, wonderRegistry)
          ? null
          : domain.wonderRegistry,
      runtimeState: runtimeChanged
          ? runtime.copyWith(
              resourceTradeAgreements: domain.resourceTradeAgreements,
              cityFoundingDraft: interaction.cityFoundingDraft,
              pendingAction: interaction.pendingAction,
            )
          : null,
    );
    final savedAtUtc = savedAt.toUtc();
    return SaveSnapshot._owned(
      save: _ownedSave(save.copyWith(savedAt: savedAtUtc)),
      rawState: projectedRawState,
      eventLogOffset: eventLogOffset,
      canonicalProjection: resultSnapshot.copyWith(
        metadata: resultSnapshot.metadata.copyWith(savedAtUtc: savedAtUtc),
      ),
    );
  }
}
