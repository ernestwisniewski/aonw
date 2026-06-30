part of 'game_command.dart';

final class SendDiplomaticProposalCommand extends DiplomaticCommand {
  const SendDiplomaticProposalCommand({
    required this.playerId,
    required this.targetPlayerId,
    required this.kind,
    this.proposalId,
    this.goldPayment = 0,
  });

  final String playerId;
  final String targetPlayerId;
  final DiplomaticProposalKind kind;
  final String? proposalId;
  final int goldPayment;

  @override
  bool operator ==(Object other) =>
      other is SendDiplomaticProposalCommand &&
      other.playerId == playerId &&
      other.targetPlayerId == targetPlayerId &&
      other.kind == kind &&
      other.proposalId == proposalId &&
      other.goldPayment == goldPayment;

  @override
  int get hashCode => Object.hash(
    SendDiplomaticProposalCommand,
    playerId,
    targetPlayerId,
    kind,
    proposalId,
    goldPayment,
  );
}

final class RespondDiplomaticProposalCommand extends DiplomaticCommand {
  const RespondDiplomaticProposalCommand({
    required this.playerId,
    required this.proposalId,
    required this.accepted,
  });

  final String playerId;
  final String proposalId;
  final bool accepted;

  @override
  bool operator ==(Object other) =>
      other is RespondDiplomaticProposalCommand &&
      other.playerId == playerId &&
      other.proposalId == proposalId &&
      other.accepted == accepted;

  @override
  int get hashCode => Object.hash(
    RespondDiplomaticProposalCommand,
    playerId,
    proposalId,
    accepted,
  );
}

final class DeclareWarCommand extends DiplomaticCommand {
  const DeclareWarCommand({
    required this.playerId,
    required this.targetPlayerId,
  });

  final String playerId;
  final String targetPlayerId;

  @override
  bool operator ==(Object other) =>
      other is DeclareWarCommand &&
      other.playerId == playerId &&
      other.targetPlayerId == targetPlayerId;

  @override
  int get hashCode => Object.hash(DeclareWarCommand, playerId, targetPlayerId);
}

final class SendGoldGiftCommand extends DiplomaticCommand {
  const SendGoldGiftCommand({
    required this.playerId,
    required this.targetPlayerId,
    required this.amount,
  });

  final String playerId;
  final String targetPlayerId;
  final int amount;

  @override
  bool operator ==(Object other) =>
      other is SendGoldGiftCommand &&
      other.playerId == playerId &&
      other.targetPlayerId == targetPlayerId &&
      other.amount == amount;

  @override
  int get hashCode =>
      Object.hash(SendGoldGiftCommand, playerId, targetPlayerId, amount);
}

final class OpenResourceTradeCommand extends GameCommand {
  const OpenResourceTradeCommand({
    required this.playerId,
    required this.targetPlayerId,
    required this.resource,
    required this.goldPerTurn,
    required this.durationTurns,
    this.agreementId,
  });

  final String playerId;
  final String targetPlayerId;
  final ResourceType resource;
  final int goldPerTurn;
  final int durationTurns;
  final String? agreementId;

  @override
  bool operator ==(Object other) =>
      other is OpenResourceTradeCommand &&
      other.playerId == playerId &&
      other.targetPlayerId == targetPlayerId &&
      other.resource == resource &&
      other.goldPerTurn == goldPerTurn &&
      other.durationTurns == durationTurns &&
      other.agreementId == agreementId;

  @override
  int get hashCode => Object.hash(
    OpenResourceTradeCommand,
    playerId,
    targetPlayerId,
    resource,
    goldPerTurn,
    durationTurns,
    agreementId,
  );
}

final class OpenResourceExchangeCommand extends GameCommand {
  const OpenResourceExchangeCommand({
    required this.playerId,
    required this.targetPlayerId,
    required this.offeredResource,
    required this.requestedResource,
    required this.durationTurns,
    this.agreementId,
  });

  final String playerId;
  final String targetPlayerId;
  final ResourceType offeredResource;
  final ResourceType requestedResource;
  final int durationTurns;
  final String? agreementId;

  @override
  bool operator ==(Object other) =>
      other is OpenResourceExchangeCommand &&
      other.playerId == playerId &&
      other.targetPlayerId == targetPlayerId &&
      other.offeredResource == offeredResource &&
      other.requestedResource == requestedResource &&
      other.durationTurns == durationTurns &&
      other.agreementId == agreementId;

  @override
  int get hashCode => Object.hash(
    OpenResourceExchangeCommand,
    playerId,
    targetPlayerId,
    offeredResource,
    requestedResource,
    durationTurns,
    agreementId,
  );
}

final class SendDiplomaticMessageCommand extends DiplomaticCommand {
  const SendDiplomaticMessageCommand({
    required this.playerId,
    required this.targetPlayerId,
    required this.topic,
    this.messageId,
  });

  final String playerId;
  final String targetPlayerId;
  final DiplomaticMessageTopic topic;
  final String? messageId;

  @override
  bool operator ==(Object other) =>
      other is SendDiplomaticMessageCommand &&
      other.playerId == playerId &&
      other.targetPlayerId == targetPlayerId &&
      other.topic == topic &&
      other.messageId == messageId;

  @override
  int get hashCode => Object.hash(
    SendDiplomaticMessageCommand,
    playerId,
    targetPlayerId,
    topic,
    messageId,
  );
}

final class RespondDiplomaticMessageCommand extends DiplomaticCommand {
  const RespondDiplomaticMessageCommand({
    required this.playerId,
    required this.messageId,
    required this.response,
  });

  final String playerId;
  final String messageId;
  final DiplomaticMessageResponse response;

  @override
  bool operator ==(Object other) =>
      other is RespondDiplomaticMessageCommand &&
      other.playerId == playerId &&
      other.messageId == messageId &&
      other.response == response;

  @override
  int get hashCode => Object.hash(
    RespondDiplomaticMessageCommand,
    playerId,
    messageId,
    response,
  );
}
