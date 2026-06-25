part of 'diplomatic_message_popup_overlay.dart';

final class _DiplomaticPopupNotificationRouter {
  const _DiplomaticPopupNotificationRouter({
    required this.inbox,
    required this.isMessageMinimized,
    required this.isProposalMinimized,
  });

  final _DiplomaticPopupInbox inbox;
  final bool Function(String messageId) isMessageMinimized;
  final bool Function(String proposalId) isProposalMinimized;

  void route(GameEventNotification notification) {
    if (!inbox.markNotificationSeen(notification.id)) return;
    switch (notification.event) {
      case final DiplomaticMessageSentEvent event:
        _routeMessageNotification(notification, event);
      case final DiplomaticProposalSentEvent event:
        _routeProposalNotification(notification, event);
      case final GameEvent event:
        _queuePassiveDiplomacyEvent(notification, event);
    }
  }

  void _routeMessageNotification(
    GameEventNotification notification,
    DiplomaticMessageSentEvent event,
  ) {
    if (!_isDirectRecipient(notification, event.toPlayerId)) {
      _queuePassiveDiplomacyEvent(notification, event);
      return;
    }
    inbox
      ..rememberMessage(notification.state.diplomacy.messages[event.messageId])
      ..queueMessage(
        event.messageId,
        minimized: isMessageMinimized(event.messageId),
      );
  }

  void _routeProposalNotification(
    GameEventNotification notification,
    DiplomaticProposalSentEvent event,
  ) {
    if (!_isDirectRecipient(notification, event.toPlayerId)) {
      _queuePassiveDiplomacyEvent(notification, event);
      return;
    }
    inbox
      ..rememberProposal(
        notification.state.diplomacy.pendingProposals[event.proposalId],
      )
      ..queueProposal(
        event.proposalId,
        minimized: isProposalMinimized(event.proposalId),
      );
  }

  bool _isDirectRecipient(
    GameEventNotification notification,
    String recipientPlayerId,
  ) {
    return recipientPlayerId == notification.playerId;
  }

  void _queuePassiveDiplomacyEvent(
    GameEventNotification notification,
    GameEvent event,
  ) {
    if (_DiplomaticPopupEventPolicy.isPassivePopupEvent(event)) {
      inbox.queueDiplomacyEvent(notification);
    }
  }
}
