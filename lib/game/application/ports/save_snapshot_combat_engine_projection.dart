part of 'save_snapshot.dart';

extension SaveSnapshotCombatEngineProjection on SaveSnapshot {
  /// Applies the reviewed combat-family slices without materializing
  /// canonical roster or session defaults into the raw persistence envelope.
  SaveSnapshot withCombatEngineProjection({
    required CanonicalGameSnapshot resultSnapshot,
    required DateTime savedAt,
  }) {
    final domain = resultSnapshot.domain;
    final runtime = _rawState.runtimeState;
    final interaction = resultSnapshot.interaction;
    final runtimeChanged = [
      !identical(domain.intendedAttacks, runtime.intendedAttacks),
      !identical(domain.diplomacy, runtime.diplomacy),
      !identical(
        domain.resourceTradeAgreements,
        runtime.resourceTradeAgreements,
      ),
      runtime.cityFoundingDraft != interaction.cityFoundingDraft,
      runtime.pendingAction != interaction.pendingAction,
    ].contains(true);
    final projectedRawState = _rawState.copyWith(
      units: identical(domain.units, units) ? null : domain.units,
      cities: identical(domain.cities, cities) ? null : domain.cities,
      artifacts: identical(domain.artifacts, artifacts)
          ? null
          : domain.artifacts,
      fogOfWar: identical(domain.fogOfWar, fogOfWar) ? null : domain.fogOfWar,
      runtimeState: runtimeChanged
          ? runtime.copyWith(
              intendedAttacks: domain.intendedAttacks,
              diplomacy: domain.diplomacy,
              resourceTradeAgreements: domain.resourceTradeAgreements,
              cityFoundingDraft: interaction.cityFoundingDraft,
              pendingAction: interaction.pendingAction,
            )
          : null,
    );
    return SaveSnapshot._owned(
      save: _ownedSave(save.copyWith(savedAt: savedAt.toUtc())),
      rawState: projectedRawState,
      eventLogOffset: eventLogOffset,
      canonicalProjection: resultSnapshot.copyWith(
        metadata: resultSnapshot.metadata.copyWith(savedAtUtc: savedAt.toUtc()),
      ),
    );
  }
}
