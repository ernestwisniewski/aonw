import 'package:aonw_core/game/domain/runtime.dart';

/// Keeps client interaction cleanup separate from canonical research state.
abstract final class ResearchSelectionPendingActionPolicy {
  static PendingPlayerAction? afterAcceptedSelection({
    required PendingPlayerAction? pendingAction,
    required String playerId,
  }) {
    if (pendingAction is PendingResearchSelection &&
        pendingAction.ownerPlayerId == playerId) {
      return null;
    }
    return pendingAction;
  }
}
