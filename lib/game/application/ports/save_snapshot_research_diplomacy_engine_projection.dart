part of 'save_snapshot.dart';

extension SaveSnapshotResearchDiplomacyEngineProjection on SaveSnapshot {
  /// Applies only research and diplomacy engine-owned slices while preserving
  /// the exact raw persistence envelope outside those slices.
  SaveSnapshot withResearchDiplomacyEngineProjection({
    required CanonicalGameSnapshot resultSnapshot,
    required DateTime savedAt,
  }) {
    final domain = resultSnapshot.domain;
    final runtime = _rawState.runtimeState;
    final interaction = resultSnapshot.interaction;
    final projectedRawState = _rawState.copyWith(
      playerGold: _researchDiplomacyIdentityChange(
        playerGold,
        domain.playerGold,
      ),
      research: _researchDiplomacyIdentityChange(research, domain.research),
      runtimeState:
          _researchDiplomacyRuntimeChanged(domain, runtime, interaction)
          ? runtime.copyWith(
              diplomacy: _researchDiplomacyIdentityChange(
                runtime.diplomacy,
                domain.diplomacy,
              ),
              intendedAttacks: _researchDiplomacyIdentityChange(
                runtime.intendedAttacks,
                domain.intendedAttacks,
              ),
              resourceTradeAgreements: _researchDiplomacyIdentityChange(
                runtime.resourceTradeAgreements,
                domain.resourceTradeAgreements,
              ),
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

T? _researchDiplomacyIdentityChange<T>(T current, T next) {
  return identical(current, next) ? null : next;
}

bool _researchDiplomacyRuntimeChanged(
  DomainState domain,
  GameRuntimeState runtime,
  PersistedInteractionState interaction,
) {
  return !identical(domain.diplomacy, runtime.diplomacy) ||
      !identical(domain.intendedAttacks, runtime.intendedAttacks) ||
      !identical(
        domain.resourceTradeAgreements,
        runtime.resourceTradeAgreements,
      ) ||
      runtime.cityFoundingDraft != interaction.cityFoundingDraft ||
      runtime.pendingAction != interaction.pendingAction;
}
