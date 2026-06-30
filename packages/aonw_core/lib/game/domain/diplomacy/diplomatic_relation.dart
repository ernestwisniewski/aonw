part of 'diplomacy_state.dart';

final class DiplomaticRelation {
  const DiplomaticRelation({
    required this.playerAId,
    required this.playerBId,
    this.status = DiplomaticRelationStatus.neutral,
    this.relationScore = 0,
    this.statusExpiresOnTurn,
    this.lastChangedTurn,
    this.lastChangeReason,
  });

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

  final String playerAId;
  final String playerBId;
  final DiplomaticRelationStatus status;
  final int relationScore;
  final int? statusExpiresOnTurn;
  final int? lastChangedTurn;
  final DiplomaticRelationChangeReason? lastChangeReason;

  String get key => DiplomacyState.relationKey(playerAId, playerBId);

  bool get isTruceExpired =>
      status == DiplomaticRelationStatus.truce && statusExpiresOnTurn != null;

  String? other(String playerId) {
    if (playerId == playerAId) return playerBId;
    if (playerId == playerBId) return playerAId;
    return null;
  }

  DiplomaticRelation copyWith({
    DiplomaticRelationStatus? status,
    int? relationScore,
    Object? statusExpiresOnTurn = _unset,
    int? lastChangedTurn,
    DiplomaticRelationChangeReason? lastChangeReason,
  }) {
    return DiplomaticRelation(
      playerAId: playerAId,
      playerBId: playerBId,
      status: status ?? this.status,
      relationScore: relationScore ?? this.relationScore,
      statusExpiresOnTurn: identical(statusExpiresOnTurn, _unset)
          ? this.statusExpiresOnTurn
          : statusExpiresOnTurn as int?,
      lastChangedTurn: lastChangedTurn ?? this.lastChangedTurn,
      lastChangeReason: lastChangeReason ?? this.lastChangeReason,
    );
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

  @override
  bool operator ==(Object other) =>
      other is DiplomaticRelation &&
      other.playerAId == playerAId &&
      other.playerBId == playerBId &&
      other.status == status &&
      other.relationScore == relationScore &&
      other.statusExpiresOnTurn == statusExpiresOnTurn &&
      other.lastChangedTurn == lastChangedTurn &&
      other.lastChangeReason == lastChangeReason;

  @override
  int get hashCode => Object.hash(
    playerAId,
    playerBId,
    status,
    relationScore,
    statusExpiresOnTurn,
    lastChangedTurn,
    lastChangeReason,
  );

  static const Object _unset = Object();

  static int? _optionalRelationScore(Object? value) {
    final score = optionalIntValue(value, 'DiplomaticRelation.relationScore');
    return score?.clamp(-100, 100).toInt();
  }
}
