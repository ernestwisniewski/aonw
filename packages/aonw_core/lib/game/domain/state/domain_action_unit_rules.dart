import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';

/// Selectively clears canonical action state owned by a unit.
abstract final class DomainActionUnitRules {
  static DomainActionState clearOwnedByUnit(
    DomainActionState actions,
    String unitId,
  ) {
    final clearPendingAction = actions.pendingAction?.ownsUnit(unitId) ?? false;
    final clearCityFoundingDraft = actions.cityFoundingDraft?.unitId == unitId;
    if (!clearPendingAction && !clearCityFoundingDraft) return actions;

    if (clearPendingAction && clearCityFoundingDraft) {
      return actions.copyWith(cityFoundingDraft: null, pendingAction: null);
    }
    if (clearPendingAction) {
      return actions.copyWith(pendingAction: null);
    }
    return actions.copyWith(cityFoundingDraft: null);
  }
}
