part of 'diplomatic_message_popup_overlay.dart';

abstract final class _DiplomaticPopupPayloads {
  static const _messagePopupMarker = '.diplomaticMessage.';
  static const _proposalPopupMarker = '.diplomaticProposal.';

  static HudMinimizedPopupEntry messageEntry({
    required String saveId,
    required String title,
    required String subtitle,
    required DiplomaticMessage message,
  }) {
    return HudMinimizedPopupEntry(
      id: messagePopupId(saveId, message.id),
      kind: HudMinimizedPopupKind.diplomaticMessage,
      title: title,
      subtitle: subtitle,
      payload: {
        'messageId': message.id,
        'fromPlayerId': message.fromPlayerId,
        'toPlayerId': message.toPlayerId,
        'topic': message.topic.name,
        'createdTurn': message.createdTurn.toString(),
        'expiresOnTurn': message.expiresOnTurn.toString(),
      },
    );
  }

  static HudMinimizedPopupEntry proposalEntry({
    required String saveId,
    required String title,
    required String subtitle,
    required DiplomaticProposal proposal,
  }) {
    return HudMinimizedPopupEntry(
      id: proposalPopupId(saveId, proposal.id),
      kind: HudMinimizedPopupKind.diplomaticProposal,
      title: title,
      subtitle: subtitle,
      payload: {
        'proposalId': proposal.id,
        'fromPlayerId': proposal.fromPlayerId,
        'toPlayerId': proposal.toPlayerId,
        'kind': proposal.kind.name,
        'createdTurn': proposal.createdTurn.toString(),
        'expiresOnTurn': proposal.expiresOnTurn.toString(),
      },
    );
  }

  static DiplomaticMessage? messageFromEntry(HudMinimizedPopupEntry entry) {
    final messageId = entry.payload['messageId'];
    final fromPlayerId = entry.payload['fromPlayerId'];
    final toPlayerId = entry.payload['toPlayerId'];
    final topic = _topicFromName(entry.payload['topic']);
    final createdTurn = int.tryParse(entry.payload['createdTurn'] ?? '');
    final expiresOnTurn = int.tryParse(entry.payload['expiresOnTurn'] ?? '');
    if (messageId == null ||
        fromPlayerId == null ||
        toPlayerId == null ||
        topic == null ||
        createdTurn == null ||
        expiresOnTurn == null) {
      return null;
    }
    return DiplomaticMessage.create(
      id: messageId,
      fromPlayerId: fromPlayerId,
      toPlayerId: toPlayerId,
      topic: topic,
      createdTurn: createdTurn,
      expiresOnTurn: expiresOnTurn,
    );
  }

  static DiplomaticProposal? proposalFromEntry(HudMinimizedPopupEntry entry) {
    final proposalId = entry.payload['proposalId'];
    final fromPlayerId = entry.payload['fromPlayerId'];
    final toPlayerId = entry.payload['toPlayerId'];
    final kind = _proposalKindFromName(entry.payload['kind']);
    final createdTurn = int.tryParse(entry.payload['createdTurn'] ?? '');
    final expiresOnTurn = int.tryParse(entry.payload['expiresOnTurn'] ?? '');
    if (proposalId == null ||
        fromPlayerId == null ||
        toPlayerId == null ||
        kind == null ||
        createdTurn == null ||
        expiresOnTurn == null) {
      return null;
    }
    return DiplomaticProposal(
      id: proposalId,
      fromPlayerId: fromPlayerId,
      toPlayerId: toPlayerId,
      kind: kind,
      createdTurn: createdTurn,
      expiresOnTurn: expiresOnTurn,
    );
  }

  static String messagePopupId(String saveId, String messageId) {
    return HudMinimizedPopupIds.diplomaticMessage(saveId, messageId);
  }

  static String proposalPopupId(String saveId, String proposalId) {
    return HudMinimizedPopupIds.diplomaticProposal(saveId, proposalId);
  }

  static String messageIdFromPopupId(String popupId) {
    final markerIndex = popupId.indexOf(_messagePopupMarker);
    if (markerIndex == -1) return popupId;
    return popupId.substring(markerIndex + _messagePopupMarker.length);
  }

  static String proposalIdFromPopupId(String popupId) {
    final markerIndex = popupId.indexOf(_proposalPopupMarker);
    if (markerIndex == -1) return popupId;
    return popupId.substring(markerIndex + _proposalPopupMarker.length);
  }
}
