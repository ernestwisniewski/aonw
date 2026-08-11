import 'package:aonw_core/game/domain/diplomacy/diplomacy_primitives.dart';
import 'package:aonw_core/util/wire_json.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'diplomatic_message.freezed.dart';

@freezed
abstract class DiplomaticMessage with _$DiplomaticMessage {
  const DiplomaticMessage._();

  const factory DiplomaticMessage({
    required String id,
    required String fromPlayerId,
    required String toPlayerId,
    required DiplomaticMessageTopic topic,
    required DiplomaticMessageCategory category,
    required int createdTurn,
    required int expiresOnTurn,
    DiplomaticMessageResponse? response,
    int? respondedTurn,
    @Default(0) int relationScoreDelta,
    int? relationScoreAfter,
    int? promiseDueTurn,
    @Default(false) bool promiseBroken,
  }) = _DiplomaticMessage;

  factory DiplomaticMessage.create({
    required String id,
    required String fromPlayerId,
    required String toPlayerId,
    required DiplomaticMessageTopic topic,
    required int createdTurn,
    required int expiresOnTurn,
  }) {
    return DiplomaticMessage(
      id: id,
      fromPlayerId: fromPlayerId,
      toPlayerId: toPlayerId,
      topic: topic,
      category: topic.category,
      createdTurn: createdTurn,
      expiresOnTurn: expiresOnTurn,
    );
  }

  factory DiplomaticMessage.fromJson(Map<String, dynamic> json) {
    return DiplomaticMessage(
      id: requiredStringValue(json['id'], 'id'),
      fromPlayerId: requiredStringValue(json['fromPlayerId'], 'fromPlayerId'),
      toPlayerId: requiredStringValue(json['toPlayerId'], 'toPlayerId'),
      topic: enumByName(
        json['topic'],
        DiplomaticMessageTopic.values,
        'DiplomaticMessage.topic',
      ),
      category: enumByName(
        json['category'],
        DiplomaticMessageCategory.values,
        'DiplomaticMessage.category',
      ),
      createdTurn: requiredNonNegativeIntValue(
        json['createdTurn'],
        'createdTurn',
      ),
      expiresOnTurn: requiredNonNegativeIntValue(
        json['expiresOnTurn'],
        'expiresOnTurn',
      ),
      response: optionalEnumByName(
        json['response'],
        DiplomaticMessageResponse.values,
        'DiplomaticMessage.response',
      ),
      respondedTurn: optionalNonNegativeIntValue(
        json['respondedTurn'],
        'respondedTurn',
      ),
      relationScoreDelta:
          optionalIntValue(json['relationScoreDelta'], 'relationScoreDelta') ??
          0,
      relationScoreAfter: optionalIntValue(
        json['relationScoreAfter'],
        'relationScoreAfter',
      ),
      promiseDueTurn: optionalNonNegativeIntValue(
        json['promiseDueTurn'],
        'promiseDueTurn',
      ),
      promiseBroken: json['promiseBroken'] == true,
    );
  }

  bool get responded => response != null;
  bool get hasActivePromise =>
      response != null && promiseDueTurn != null && !promiseBroken;

  bool involves(String playerId) =>
      fromPlayerId == playerId || toPlayerId == playerId;

  bool isExpired(int turn) => !responded && turn >= expiresOnTurn;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromPlayerId': fromPlayerId,
    'toPlayerId': toPlayerId,
    'topic': topic.name,
    'category': category.name,
    'createdTurn': createdTurn,
    'expiresOnTurn': expiresOnTurn,
    if (response != null) 'response': response!.name,
    if (respondedTurn != null) 'respondedTurn': respondedTurn,
    if (relationScoreDelta != 0) 'relationScoreDelta': relationScoreDelta,
    if (relationScoreAfter != null) 'relationScoreAfter': relationScoreAfter,
    if (promiseDueTurn != null) 'promiseDueTurn': promiseDueTurn,
    if (promiseBroken) 'promiseBroken': true,
  };
}
