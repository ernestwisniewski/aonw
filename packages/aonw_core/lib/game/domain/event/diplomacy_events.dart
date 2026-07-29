part of 'game_event.dart';

final class DiplomaticProposalSentEvent extends DomainEvent {
  const DiplomaticProposalSentEvent({
    required this.proposalId,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.kind,
    required this.expiresOnTurn,
  });

  final String proposalId;
  final String fromPlayerId;
  final String toPlayerId;
  final DiplomaticProposalKind kind;
  final int expiresOnTurn;
}

final class DiplomaticProposalRespondedEvent extends DomainEvent {
  const DiplomaticProposalRespondedEvent({
    required this.proposalId,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.kind,
    required this.accepted,
  });

  final String proposalId;
  final String fromPlayerId;
  final String toPlayerId;
  final DiplomaticProposalKind kind;
  final bool accepted;
}

final class DiplomaticProposalExpiredEvent extends DomainEvent {
  const DiplomaticProposalExpiredEvent({
    required this.proposalId,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.kind,
  });

  final String proposalId;
  final String fromPlayerId;
  final String toPlayerId;
  final DiplomaticProposalKind kind;
}

final class DiplomaticRelationChangedEvent extends DomainEvent {
  const DiplomaticRelationChangedEvent({
    required this.playerAId,
    required this.playerBId,
    required this.oldStatus,
    required this.newStatus,
    required this.reason,
    this.expiresOnTurn,
  });

  final String playerAId;
  final String playerBId;
  final DiplomaticRelationStatus oldStatus;
  final DiplomaticRelationStatus newStatus;
  final DiplomaticRelationChangeReason reason;
  final int? expiresOnTurn;
}

final class DiplomaticMessageSentEvent extends DomainEvent {
  const DiplomaticMessageSentEvent({
    required this.messageId,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.topic,
    required this.category,
    required this.expiresOnTurn,
  });

  final String messageId;
  final String fromPlayerId;
  final String toPlayerId;
  final DiplomaticMessageTopic topic;
  final DiplomaticMessageCategory category;
  final int expiresOnTurn;
}

final class DiplomaticMessageRespondedEvent extends DomainEvent {
  const DiplomaticMessageRespondedEvent({
    required this.messageId,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.topic,
    required this.response,
    required this.relationDelta,
    required this.relationScoreAfter,
    this.promiseDueTurn,
  });

  final String messageId;
  final String fromPlayerId;
  final String toPlayerId;
  final DiplomaticMessageTopic topic;
  final DiplomaticMessageResponse response;
  final int relationDelta;
  final int relationScoreAfter;
  final int? promiseDueTurn;
}

final class DiplomaticScoreChangedEvent extends DomainEvent {
  const DiplomaticScoreChangedEvent({
    required this.playerAId,
    required this.playerBId,
    required this.delta,
    required this.scoreAfter,
    required this.reason,
    this.sourceId,
  });

  final String playerAId;
  final String playerBId;
  final int delta;
  final int scoreAfter;
  final DiplomaticScoreChangeReason reason;
  final String? sourceId;
}

final class DiplomaticPromiseBrokenEvent extends DomainEvent {
  const DiplomaticPromiseBrokenEvent({
    required this.messageId,
    required this.playerAId,
    required this.playerBId,
    required this.delta,
    required this.scoreAfter,
  });

  final String messageId;
  final String playerAId;
  final String playerBId;
  final int delta;
  final int scoreAfter;
}
