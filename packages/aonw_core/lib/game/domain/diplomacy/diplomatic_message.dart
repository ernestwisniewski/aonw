part of 'diplomacy_state.dart';

final class DiplomaticMessage {
  const DiplomaticMessage({
    required this.id,
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.topic,
    required this.category,
    required this.createdTurn,
    required this.expiresOnTurn,
    this.response,
    this.respondedTurn,
    this.relationScoreDelta = 0,
    this.relationScoreAfter,
    this.promiseDueTurn,
    this.promiseBroken = false,
  });

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

  final String id;
  final String fromPlayerId;
  final String toPlayerId;
  final DiplomaticMessageTopic topic;
  final DiplomaticMessageCategory category;
  final int createdTurn;
  final int expiresOnTurn;
  final DiplomaticMessageResponse? response;
  final int? respondedTurn;
  final int relationScoreDelta;
  final int? relationScoreAfter;
  final int? promiseDueTurn;
  final bool promiseBroken;

  bool get responded => response != null;
  bool get hasActivePromise =>
      response != null && promiseDueTurn != null && !promiseBroken;

  bool involves(String playerId) =>
      fromPlayerId == playerId || toPlayerId == playerId;

  bool isExpired(int turn) => !responded && turn >= expiresOnTurn;

  DiplomaticMessage copyWith({
    DiplomaticMessageResponse? response,
    int? respondedTurn,
    int? relationScoreDelta,
    int? relationScoreAfter,
    Object? promiseDueTurn = _unset,
    bool? promiseBroken,
  }) {
    return DiplomaticMessage(
      id: id,
      fromPlayerId: fromPlayerId,
      toPlayerId: toPlayerId,
      topic: topic,
      category: category,
      createdTurn: createdTurn,
      expiresOnTurn: expiresOnTurn,
      response: response ?? this.response,
      respondedTurn: respondedTurn ?? this.respondedTurn,
      relationScoreDelta: relationScoreDelta ?? this.relationScoreDelta,
      relationScoreAfter: relationScoreAfter ?? this.relationScoreAfter,
      promiseDueTurn: identical(promiseDueTurn, _unset)
          ? this.promiseDueTurn
          : promiseDueTurn as int?,
      promiseBroken: promiseBroken ?? this.promiseBroken,
    );
  }

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

  @override
  bool operator ==(Object other) =>
      other is DiplomaticMessage &&
      other.id == id &&
      other.fromPlayerId == fromPlayerId &&
      other.toPlayerId == toPlayerId &&
      other.topic == topic &&
      other.category == category &&
      other.createdTurn == createdTurn &&
      other.expiresOnTurn == expiresOnTurn &&
      other.response == response &&
      other.respondedTurn == respondedTurn &&
      other.relationScoreDelta == relationScoreDelta &&
      other.relationScoreAfter == relationScoreAfter &&
      other.promiseDueTurn == promiseDueTurn &&
      other.promiseBroken == promiseBroken;

  @override
  int get hashCode => Object.hash(
    DiplomaticMessage,
    id,
    fromPlayerId,
    toPlayerId,
    topic,
    category,
    createdTurn,
    expiresOnTurn,
    response,
    respondedTurn,
    relationScoreDelta,
    relationScoreAfter,
    promiseDueTurn,
    promiseBroken,
  );

  static const Object _unset = Object();
}
