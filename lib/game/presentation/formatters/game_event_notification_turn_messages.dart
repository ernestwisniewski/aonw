part of 'game_event_notification_message.dart';

GameEventNotificationMessage _dominationThresholdMessage({
  required AppLocalizations l10n,
  required _GameEventPlayerRoster? roster,
  required GameClientState state,
  required String playerId,
  required double controlPercent,
  required double requiredControlPercent,
  required int holdTurns,
  required int requiredHoldTurns,
}) {
  final playerName = _playerName(l10n, roster, playerId);
  final isSelf =
      state.activePlayerId.isNotEmpty && state.activePlayerId == playerId;
  final control = percent(controlPercent, false, false);
  final required = percent(requiredControlPercent, false, false);
  final remaining = (requiredHoldTurns - holdTurns).clamp(0, requiredHoldTurns);
  return GameEventNotificationMessage(
    title: isSelf
        ? l10n.eventDominationStartedTitle
        : l10n.eventDominationRivalAboveTitle,
    body: l10n.eventDominationBody(playerName, control, required),
    details: [
      l10n.eventDominationHoldProgressDetail(holdTurns, requiredHoldTurns),
      if (remaining == 0)
        l10n.eventDominationReadyDetail
      else if (isSelf)
        l10n.eventDominationKeepHoldingDetail(_turnsLabel(l10n, remaining))
      else
        l10n.eventDominationInterruptDetail(_turnsLabel(l10n, remaining)),
    ],
    thumbnail: IconEventNotificationThumbnail(
      isSelf
          ? EventNotificationIconThumbnailKind.success
          : EventNotificationIconThumbnailKind.warning,
    ),
  );
}

String _turnsLabel(AppLocalizations l10n, int count) {
  return l10n.eventTurnCountLabel(count);
}
