part of 'activity_log_dialog.dart';

Future<void> showTurnTimelinePopup(
  BuildContext context, {
  required List<GameEventNotification> entries,
  required GameSave gameSave,
  GameClientState? currentState,
  String? activePlayerId,
  ValueChanged<GameEventNotification>? onEntrySelected,
  ValueListenable<GamepadInputSnapshot>? gamepadInputListenable,
}) {
  return showGameModal<void>(
    context: context,
    size: GameModalSize.wide,
    builder: (dialogContext) => TurnTimelinePopup(
      entries: entries,
      gameSave: gameSave,
      currentTurn: gameSave.turn,
      currentState: currentState,
      activePlayerId: activePlayerId,
      onEntrySelected: onEntrySelected,
      gamepadInputListenable: gamepadInputListenable,
      onClose: () => Navigator.of(dialogContext).maybePop(),
    ),
  );
}

extension _TurnTimelinePopupGamepad on _TurnTimelinePopupState {
  void _scrollHistory(GamepadMapDirection direction) {
    if (!_historyScrollController.hasClients) return;
    final delta = switch (direction) {
      GamepadMapDirection.up => -92.0,
      GamepadMapDirection.down => 92.0,
      _ => 0.0,
    };
    if (delta == 0) return;
    final position = _historyScrollController.position;
    final next = math.max(
      position.minScrollExtent,
      math.min(position.maxScrollExtent, position.pixels + delta),
    );
    if (next == position.pixels) return;
    unawaited(
      _historyScrollController.animateTo(
        next,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
