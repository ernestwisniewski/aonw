part of 'diplomacy_state.dart';

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
      id: _requiredString(json, 'id'),
      fromPlayerId: _requiredString(json, 'fromPlayerId'),
      toPlayerId: _requiredString(json, 'toPlayerId'),
      topic: _enumValue(
        json['topic'],
        DiplomaticMessageTopic.values,
        'DiplomaticMessage.topic',
      ),
      category: _enumValue(
        json['category'],
        DiplomaticMessageCategory.values,
        'DiplomaticMessage.category',
      ),
      createdTurn: _requiredNonNegativeInt(json['createdTurn'], 'createdTurn'),
      expiresOnTurn: _requiredNonNegativeInt(
        json['expiresOnTurn'],
        'expiresOnTurn',
      ),
      response: _optionalEnumValue(
        json['response'],
        DiplomaticMessageResponse.values,
        'DiplomaticMessage.response',
      ),
      respondedTurn: _optionalNonNegativeInt(
        json['respondedTurn'],
        'respondedTurn',
      ),
      relationScoreDelta:
          _optionalInt(json['relationScoreDelta'], 'relationScoreDelta') ?? 0,
      relationScoreAfter: _optionalInt(
        json['relationScoreAfter'],
        'relationScoreAfter',
      ),
      promiseDueTurn: _optionalNonNegativeInt(
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
