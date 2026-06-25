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
    return DiplomaticRelation.between(
      playerAId: _requiredString(json, 'playerAId'),
      playerBId: _requiredString(json, 'playerBId'),
      status: _statusFromJson(json['status']),
      relationScore: _optionalInt(json['relationScore'], 'relationScore') ?? 0,
      statusExpiresOnTurn: _optionalNonNegativeInt(
        json['statusExpiresOnTurn'],
        'statusExpiresOnTurn',
      ),
      lastChangedTurn: _optionalNonNegativeInt(
        json['lastChangedTurn'],
        'lastChangedTurn',
      ),
      lastChangeReason: _reasonFromJson(json['lastChangeReason']),
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

  static String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String && value.isNotEmpty) return value;
    throw ArgumentError.value(
      value,
      'DiplomaticRelation.$field',
      'Expected a non-empty String',
    );
  }

  static int? _optionalNonNegativeInt(Object? value, String field) {
    if (value == null) return null;
    if (value is num && value >= 0 && value.toInt() == value) {
      return value.toInt();
    }
    throw ArgumentError.value(
      value,
      'DiplomaticRelation.$field',
      'Expected a non-negative integer',
    );
  }

  static int? _optionalInt(Object? value, String field) {
    if (value == null) return null;
    if (value is num && value.toInt() == value) {
      return value.toInt().clamp(-100, 100);
    }
    throw ArgumentError.value(
      value,
      'DiplomaticRelation.$field',
      'Expected an integer',
    );
  }

  static DiplomaticRelationStatus _statusFromJson(Object? value) {
    if (value is String) {
      for (final status in DiplomaticRelationStatus.values) {
        if (status.name == value) return status;
      }
    }
    throw ArgumentError.value(
      value,
      'DiplomaticRelation.status',
      'Unknown diplomatic relation status',
    );
  }

  static DiplomaticRelationChangeReason? _reasonFromJson(Object? value) {
    if (value == null) return null;
    if (value is String) {
      for (final reason in DiplomaticRelationChangeReason.values) {
        if (reason.name == value) return reason;
      }
    }
    throw ArgumentError.value(
      value,
      'DiplomaticRelation.lastChangeReason',
      'Unknown diplomatic relation change reason',
    );
  }
}
