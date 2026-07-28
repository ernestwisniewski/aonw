import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/turn/phases/advance_turn_phase.dart';

extension AdvanceTurnSnapshot on AdvanceTurnPhase {
  SaveSnapshot advanceSnapshot(
    SaveSnapshot snapshot, {
    required String playerId,
    DateTime? savedAt,
  }) {
    if (!snapshot.session.turnStatesByPlayerId.containsKey(playerId)) {
      return snapshot;
    }
    return snapshot
        .withPlayerFinished(playerId)
        .withSavedAt(savedAt ?? snapshot.metadata.savedAtUtc);
  }
}
