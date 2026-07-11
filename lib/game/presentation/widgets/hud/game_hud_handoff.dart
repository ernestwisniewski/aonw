part of 'game_hud.dart';

extension _GameHudHandoffHelpers on _GameHudState {
  String _handoffPreparationKey(
    HandoffData handoff, {
    required bool clearPending,
    required String? entrySaveId,
  }) {
    final saveId = entrySaveId ?? widget.gameSave?.id ?? widget.session.saveId;
    return [
      saveId,
      handoff.playerId,
      handoff.turnNumber,
      handoff.freshTurn,
      clearPending,
    ].join('|');
  }
}
