import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';

/// Selectively clears persisted interaction state owned by a unit.
abstract final class PersistedInteractionUnitRules {
  static DomainActionState clearOwnedByUnit(
    DomainActionState interaction,
    String unitId,
  ) {
    final clearPendingAction =
        interaction.pendingAction?.ownsUnit(unitId) ?? false;
    final clearCityFoundingDraft =
        interaction.cityFoundingDraft?.unitId == unitId;
    if (!clearPendingAction && !clearCityFoundingDraft) return interaction;

    if (clearPendingAction && clearCityFoundingDraft) {
      return interaction.copyWith(cityFoundingDraft: null, pendingAction: null);
    }
    if (clearPendingAction) {
      return interaction.copyWith(pendingAction: null);
    }
    return interaction.copyWith(cityFoundingDraft: null);
  }
}
