part of 'diplomatic_message_popup_overlay.dart';

abstract final class _DiplomaticPopupEventPolicy {
  static bool isPassivePopupEvent(GameEvent event) {
    return switch (event) {
      DiplomaticMessageSentEvent() || DiplomaticProposalSentEvent() => false,
      DiplomaticProposalRespondedEvent() ||
      DiplomaticProposalExpiredEvent() ||
      DiplomaticRelationChangedEvent() ||
      DiplomaticMessageRespondedEvent() ||
      DiplomaticPromiseBrokenEvent() => true,
      DiplomaticScoreChangedEvent() => false,
      _ => false,
    };
  }

  static Color accentFor(GameEvent event) {
    return switch (event) {
      DiplomaticProposalExpiredEvent() ||
      DiplomaticPromiseBrokenEvent() => GameUiTheme.danger,
      DiplomaticProposalRespondedEvent(:final accepted) =>
        accepted ? GameUiTheme.success : GameUiTheme.danger,
      DiplomaticMessageRespondedEvent(:final relationDelta) =>
        relationDelta >= 0 ? GameUiTheme.success : GameUiTheme.danger,
      DiplomaticRelationChangedEvent(:final newStatus) =>
        newStatus == DiplomaticRelationStatus.war
            ? GameUiTheme.danger
            : GameUiTheme.info,
      _ => GameUiTheme.info,
    };
  }

  static String activePlayerIdFromNotifications(
    Iterable<GameEventNotification> notifications,
  ) {
    for (final notification in notifications) {
      final playerId = _recipientPlayerId(notification);
      if (playerId.isNotEmpty) return playerId;
    }
    return '';
  }

  static String _recipientPlayerId(GameEventNotification notification) {
    final event = notification.event;
    if (event is DiplomaticMessageSentEvent && event.toPlayerId.isNotEmpty) {
      return event.toPlayerId;
    }
    if (event is DiplomaticProposalSentEvent && event.toPlayerId.isNotEmpty) {
      return event.toPlayerId;
    }
    return notification.playerId;
  }
}
