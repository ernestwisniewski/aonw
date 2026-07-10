part of 'diplomatic_message_popup_overlay.dart';

abstract final class _DiplomaticPopupEventPolicy {
  static bool isPassivePopupEvent(GameEvent event) {
    return GameEventDescriptor.forEvent(event).passiveDiplomaticPopup;
  }

  static Color accentFor(GameEvent event) {
    return switch (GameEventDescriptor.forEvent(event).diplomaticPopupTone) {
      GameEventDiplomaticPopupTone.positive => GameUiTheme.success,
      GameEventDiplomaticPopupTone.negative => GameUiTheme.danger,
      GameEventDiplomaticPopupTone.neutral => GameUiTheme.info,
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
    final recipientPlayerId = GameEventDescriptor.forEvent(
      notification.event,
    ).diplomaticPopupRecipientPlayerId;
    if (recipientPlayerId?.isNotEmpty == true) return recipientPlayerId!;
    return notification.playerId;
  }
}
