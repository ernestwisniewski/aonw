import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/util/wire_json.dart';

/// Wire codec for diplomatic contacts, proposals, messages, and relations.
abstract final class DiplomacyEventSerializer {
  static Map<String, dynamic> toJson(GameEvent event) {
    final encode = _diplomacyEventEncoders[event.runtimeType];
    if (encode == null) {
      throw ArgumentError.value(event, 'event', 'Not a diplomacy event');
    }
    return encode(event);
  }

  static GameEvent? tryFromJson(Map<String, dynamic> json, String type) {
    return _diplomacyEventDecoders[type]?.call(json, type);
  }
}

final _diplomacyEventEncoders =
    <Type, Map<String, dynamic> Function(GameEvent)>{
      CivilizationMetEvent: (event) =>
          _civilizationMetToJson(event as CivilizationMetEvent),
      DiplomaticProposalSentEvent: (event) =>
          _proposalSentToJson(event as DiplomaticProposalSentEvent),
      DiplomaticProposalRespondedEvent: (event) =>
          _proposalRespondedToJson(event as DiplomaticProposalRespondedEvent),
      DiplomaticProposalExpiredEvent: (event) =>
          _proposalExpiredToJson(event as DiplomaticProposalExpiredEvent),
      DiplomaticRelationChangedEvent: (event) =>
          _relationChangedToJson(event as DiplomaticRelationChangedEvent),
      DiplomaticMessageSentEvent: (event) =>
          _messageSentToJson(event as DiplomaticMessageSentEvent),
      DiplomaticMessageRespondedEvent: (event) =>
          _messageRespondedToJson(event as DiplomaticMessageRespondedEvent),
      DiplomaticScoreChangedEvent: (event) =>
          _scoreChangedToJson(event as DiplomaticScoreChangedEvent),
      DiplomaticPromiseBrokenEvent: (event) =>
          _promiseBrokenToJson(event as DiplomaticPromiseBrokenEvent),
    };

final _diplomacyEventDecoders =
    <String, GameEvent Function(Map<String, dynamic>, String)>{
      'CivilizationMet': _civilizationMetFromJson,
      'DiplomaticProposalSent': _proposalSentFromJson,
      'DiplomaticProposalResponded': _proposalRespondedFromJson,
      'DiplomaticProposalExpired': _proposalExpiredFromJson,
      'DiplomaticRelationChanged': _relationChangedFromJson,
      'DiplomaticMessageSent': _messageSentFromJson,
      'DiplomaticMessageResponded': _messageRespondedFromJson,
      'DiplomaticScoreChanged': _scoreChangedFromJson,
      'DiplomaticPromiseBroken': _promiseBrokenFromJson,
    };

Map<String, dynamic> _civilizationMetToJson(CivilizationMetEvent event) => {
  'type': 'CivilizationMet',
  'playerId': event.playerId,
  'metPlayerId': event.metPlayerId,
};

Map<String, dynamic> _proposalSentToJson(DiplomaticProposalSentEvent event) => {
  'type': 'DiplomaticProposalSent',
  'proposalId': event.proposalId,
  'fromPlayerId': event.fromPlayerId,
  'toPlayerId': event.toPlayerId,
  'kind': event.kind.name,
  'expiresOnTurn': event.expiresOnTurn,
};

Map<String, dynamic> _proposalRespondedToJson(
  DiplomaticProposalRespondedEvent event,
) => {
  'type': 'DiplomaticProposalResponded',
  'proposalId': event.proposalId,
  'fromPlayerId': event.fromPlayerId,
  'toPlayerId': event.toPlayerId,
  'kind': event.kind.name,
  'accepted': event.accepted,
};

Map<String, dynamic> _proposalExpiredToJson(
  DiplomaticProposalExpiredEvent event,
) => {
  'type': 'DiplomaticProposalExpired',
  'proposalId': event.proposalId,
  'fromPlayerId': event.fromPlayerId,
  'toPlayerId': event.toPlayerId,
  'kind': event.kind.name,
};

Map<String, dynamic> _relationChangedToJson(
  DiplomaticRelationChangedEvent event,
) => {
  'type': 'DiplomaticRelationChanged',
  'playerAId': event.playerAId,
  'playerBId': event.playerBId,
  'oldStatus': event.oldStatus.name,
  'newStatus': event.newStatus.name,
  'reason': event.reason.name,
  'expiresOnTurn': ?event.expiresOnTurn,
};

Map<String, dynamic> _messageSentToJson(DiplomaticMessageSentEvent event) => {
  'type': 'DiplomaticMessageSent',
  'messageId': event.messageId,
  'fromPlayerId': event.fromPlayerId,
  'toPlayerId': event.toPlayerId,
  'topic': event.topic.name,
  'category': event.category.name,
  'expiresOnTurn': event.expiresOnTurn,
};

Map<String, dynamic> _messageRespondedToJson(
  DiplomaticMessageRespondedEvent event,
) => {
  'type': 'DiplomaticMessageResponded',
  'messageId': event.messageId,
  'fromPlayerId': event.fromPlayerId,
  'toPlayerId': event.toPlayerId,
  'topic': event.topic.name,
  'response': event.response.name,
  'relationDelta': event.relationDelta,
  'relationScoreAfter': event.relationScoreAfter,
  'promiseDueTurn': ?event.promiseDueTurn,
};

Map<String, dynamic> _scoreChangedToJson(DiplomaticScoreChangedEvent event) => {
  'type': 'DiplomaticScoreChanged',
  'playerAId': event.playerAId,
  'playerBId': event.playerBId,
  'delta': event.delta,
  'scoreAfter': event.scoreAfter,
  'reason': event.reason.name,
  'sourceId': ?event.sourceId,
};

Map<String, dynamic> _promiseBrokenToJson(DiplomaticPromiseBrokenEvent event) =>
    {
      'type': 'DiplomaticPromiseBroken',
      'messageId': event.messageId,
      'playerAId': event.playerAId,
      'playerBId': event.playerBId,
      'delta': event.delta,
      'scoreAfter': event.scoreAfter,
    };

CivilizationMetEvent _civilizationMetFromJson(
  Map<String, dynamic> json,
  String type,
) => CivilizationMetEvent(
  playerId: requiredStringField(json, type, 'playerId'),
  metPlayerId: requiredStringField(json, type, 'metPlayerId'),
);

DiplomaticProposalSentEvent _proposalSentFromJson(
  Map<String, dynamic> json,
  String type,
) => DiplomaticProposalSentEvent(
  proposalId: requiredStringField(json, type, 'proposalId'),
  fromPlayerId: requiredStringField(json, type, 'fromPlayerId'),
  toPlayerId: requiredStringField(json, type, 'toPlayerId'),
  kind: requiredEnumField(json, type, 'kind', DiplomaticProposalKind.values),
  expiresOnTurn: requiredIntField(json, type, 'expiresOnTurn'),
);

DiplomaticProposalRespondedEvent _proposalRespondedFromJson(
  Map<String, dynamic> json,
  String type,
) => DiplomaticProposalRespondedEvent(
  proposalId: requiredStringField(json, type, 'proposalId'),
  fromPlayerId: requiredStringField(json, type, 'fromPlayerId'),
  toPlayerId: requiredStringField(json, type, 'toPlayerId'),
  kind: requiredEnumField(json, type, 'kind', DiplomaticProposalKind.values),
  accepted: requiredBoolField(json, type, 'accepted'),
);

DiplomaticProposalExpiredEvent _proposalExpiredFromJson(
  Map<String, dynamic> json,
  String type,
) => DiplomaticProposalExpiredEvent(
  proposalId: requiredStringField(json, type, 'proposalId'),
  fromPlayerId: requiredStringField(json, type, 'fromPlayerId'),
  toPlayerId: requiredStringField(json, type, 'toPlayerId'),
  kind: requiredEnumField(json, type, 'kind', DiplomaticProposalKind.values),
);

DiplomaticRelationChangedEvent _relationChangedFromJson(
  Map<String, dynamic> json,
  String type,
) => DiplomaticRelationChangedEvent(
  playerAId: requiredStringField(json, type, 'playerAId'),
  playerBId: requiredStringField(json, type, 'playerBId'),
  oldStatus: requiredEnumField(
    json,
    type,
    'oldStatus',
    DiplomaticRelationStatus.values,
  ),
  newStatus: requiredEnumField(
    json,
    type,
    'newStatus',
    DiplomaticRelationStatus.values,
  ),
  reason: requiredEnumField(
    json,
    type,
    'reason',
    DiplomaticRelationChangeReason.values,
  ),
  expiresOnTurn: optionalIntField(json, type, 'expiresOnTurn'),
);

DiplomaticMessageSentEvent _messageSentFromJson(
  Map<String, dynamic> json,
  String type,
) => DiplomaticMessageSentEvent(
  messageId: requiredStringField(json, type, 'messageId'),
  fromPlayerId: requiredStringField(json, type, 'fromPlayerId'),
  toPlayerId: requiredStringField(json, type, 'toPlayerId'),
  topic: requiredEnumField(json, type, 'topic', DiplomaticMessageTopic.values),
  category: requiredEnumField(
    json,
    type,
    'category',
    DiplomaticMessageCategory.values,
  ),
  expiresOnTurn: requiredIntField(json, type, 'expiresOnTurn'),
);

DiplomaticMessageRespondedEvent _messageRespondedFromJson(
  Map<String, dynamic> json,
  String type,
) => DiplomaticMessageRespondedEvent(
  messageId: requiredStringField(json, type, 'messageId'),
  fromPlayerId: requiredStringField(json, type, 'fromPlayerId'),
  toPlayerId: requiredStringField(json, type, 'toPlayerId'),
  topic: requiredEnumField(json, type, 'topic', DiplomaticMessageTopic.values),
  response: requiredEnumField(
    json,
    type,
    'response',
    DiplomaticMessageResponse.values,
  ),
  relationDelta: requiredIntField(json, type, 'relationDelta'),
  relationScoreAfter: requiredIntField(json, type, 'relationScoreAfter'),
  promiseDueTurn: optionalIntField(json, type, 'promiseDueTurn'),
);

DiplomaticScoreChangedEvent _scoreChangedFromJson(
  Map<String, dynamic> json,
  String type,
) => DiplomaticScoreChangedEvent(
  playerAId: requiredStringField(json, type, 'playerAId'),
  playerBId: requiredStringField(json, type, 'playerBId'),
  delta: requiredIntField(json, type, 'delta'),
  scoreAfter: requiredIntField(json, type, 'scoreAfter'),
  reason: requiredEnumField(
    json,
    type,
    'reason',
    DiplomaticScoreChangeReason.values,
  ),
  sourceId: optionalStringField(json, type, 'sourceId'),
);

DiplomaticPromiseBrokenEvent _promiseBrokenFromJson(
  Map<String, dynamic> json,
  String type,
) => DiplomaticPromiseBrokenEvent(
  messageId: requiredStringField(json, type, 'messageId'),
  playerAId: requiredStringField(json, type, 'playerAId'),
  playerBId: requiredStringField(json, type, 'playerBId'),
  delta: requiredIntField(json, type, 'delta'),
  scoreAfter: requiredIntField(json, type, 'scoreAfter'),
);
