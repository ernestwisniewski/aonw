part of 'diplomacy_state.dart';

@freezed
abstract class DiplomaticRelation with _$DiplomaticRelation {
  const DiplomaticRelation._();

  const factory DiplomaticRelation({
    required String playerAId,
    required String playerBId,
    @Default(DiplomaticRelationStatus.neutral) DiplomaticRelationStatus status,
    @Default(0) int relationScore,
    int? statusExpiresOnTurn,
    int? lastChangedTurn,
    DiplomaticRelationChangeReason? lastChangeReason,
  }) = _DiplomaticRelation;

  factory DiplomaticRelation.between({
    required String playerAId,
    required String playerBId,
    DiplomaticRelationStatus status = DiplomaticRelationStatus.neutral,
    int relationScore = 0,
    int? statusExpiresOnTurn,
    int? lastChangedTurn,
    DiplomaticRelationChangeReason? lastChangeReason,
  }) {
    final pair = DiplomacyState.normalizedPair(playerAId, playerBId);
    return DiplomaticRelation(
      playerAId: pair.$1,
      playerBId: pair.$2,
      status: status,
      relationScore: relationScore,
      statusExpiresOnTurn: statusExpiresOnTurn,
      lastChangedTurn: lastChangedTurn,
      lastChangeReason: lastChangeReason,
    );
  }

  factory DiplomaticRelation.fromJson(Map<String, dynamic> json) {
    final reader = WireJson(json, 'DiplomaticRelation');
    return DiplomaticRelation.between(
      playerAId: reader.requiredString('playerAId'),
      playerBId: reader.requiredString('playerBId'),
      status: reader.requiredEnum('status', DiplomaticRelationStatus.values),
      relationScore: _optionalRelationScore(json['relationScore']) ?? 0,
      statusExpiresOnTurn: reader.optionalNonNegativeInt('statusExpiresOnTurn'),
      lastChangedTurn: reader.optionalNonNegativeInt('lastChangedTurn'),
      lastChangeReason: reader.optionalEnum(
        'lastChangeReason',
        DiplomaticRelationChangeReason.values,
      ),
    );
  }

  String get key => DiplomacyState.relationKey(playerAId, playerBId);

  bool get isTruceExpired =>
      status == DiplomaticRelationStatus.truce && statusExpiresOnTurn != null;

  String? other(String playerId) {
    if (playerId == playerAId) return playerBId;
    if (playerId == playerBId) return playerAId;
    return null;
  }

  Map<String, dynamic> toJson() => {
    'playerAId': playerAId,
    'playerBId': playerBId,
    'status': status.name,
    if (relationScore != 0) 'relationScore': relationScore,
    if (statusExpiresOnTurn != null) 'statusExpiresOnTurn': statusExpiresOnTurn,
    if (lastChangedTurn != null) 'lastChangedTurn': lastChangedTurn,
    if (lastChangeReason != null) 'lastChangeReason': lastChangeReason!.name,
  };

  static int? _optionalRelationScore(Object? value) {
    final score = optionalIntValue(value, 'DiplomaticRelation.relationScore');
    return score?.clamp(-100, 100).toInt();
  }
}
