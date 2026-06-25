part of 'diplomatic_message_popup_overlay.dart';

final class _DiplomaticPopupInbox {
  final Queue<String> _pendingMessageIds = Queue();
  final Queue<String> _pendingProposalIds = Queue();
  final Queue<GameEventNotification> _pendingDiplomacyEvents = Queue();
  final Map<String, DiplomaticMessage> _notificationMessages = {};
  final Map<String, DiplomaticProposal> _notificationProposals = {};
  final Set<int> _seenNotificationIds = {};
  final Set<String> _seenMessageIds = {};
  final Set<String> _seenProposalIds = {};

  bool get hasPendingPopup =>
      pendingProposalCount > 0 ||
      pendingMessageCount > 0 ||
      pendingDiplomacyEventCount > 0;

  int get pendingMessageCount => _pendingMessageIds.length;

  int get pendingProposalCount => _pendingProposalIds.length;

  int get pendingDiplomacyEventCount => _pendingDiplomacyEvents.length;

  void clear() {
    _pendingMessageIds.clear();
    _pendingProposalIds.clear();
    _pendingDiplomacyEvents.clear();
    _notificationMessages.clear();
    _notificationProposals.clear();
    _seenNotificationIds.clear();
    _seenMessageIds.clear();
    _seenProposalIds.clear();
  }

  bool markNotificationSeen(int notificationId) {
    return _seenNotificationIds.add(notificationId);
  }

  void rememberMessage(DiplomaticMessage? message) {
    if (message == null) return;
    _notificationMessages[message.id] = message;
  }

  void rememberProposal(DiplomaticProposal? proposal) {
    if (proposal == null) return;
    _notificationProposals[proposal.id] = proposal;
  }

  void queueMessage(String messageId, {required bool minimized}) {
    if (_shouldSkipMessageQueue(messageId, minimized: minimized)) return;
    _pendingMessageIds.add(messageId);
  }

  void queueProposal(String proposalId, {required bool minimized}) {
    if (_shouldSkipProposalQueue(proposalId, minimized: minimized)) return;
    _pendingProposalIds.add(proposalId);
  }

  void queueDiplomacyEvent(GameEventNotification notification) {
    _pendingDiplomacyEvents.add(notification);
  }

  String takeMessageId() {
    return _pendingMessageIds.removeFirst();
  }

  String takeProposalId() {
    return _pendingProposalIds.removeFirst();
  }

  GameEventNotification takeDiplomacyEvent() {
    return _pendingDiplomacyEvents.removeFirst();
  }

  void requeueMessage(String messageId) {
    _pendingMessageIds.add(messageId);
  }

  void requeueProposal(String proposalId) {
    _pendingProposalIds.add(proposalId);
  }

  void markMessageSeen(String messageId) {
    _seenMessageIds.add(messageId);
  }

  void markProposalSeen(String proposalId) {
    _seenProposalIds.add(proposalId);
  }

  bool hasSeenMessage(String messageId) {
    return _seenMessageIds.contains(messageId);
  }

  bool hasSeenProposal(String proposalId) {
    return _seenProposalIds.contains(proposalId);
  }

  DiplomaticMessage? messageById(String messageId) {
    return _notificationMessages[messageId];
  }

  DiplomaticProposal? proposalById(String proposalId) {
    return _notificationProposals[proposalId];
  }

  bool _shouldSkipMessageQueue(String messageId, {required bool minimized}) {
    return messageId.isEmpty ||
        minimized ||
        _seenMessageIds.contains(messageId) ||
        _pendingMessageIds.contains(messageId);
  }

  bool _shouldSkipProposalQueue(String proposalId, {required bool minimized}) {
    return proposalId.isEmpty ||
        minimized ||
        _seenProposalIds.contains(proposalId) ||
        _pendingProposalIds.contains(proposalId);
  }
}
