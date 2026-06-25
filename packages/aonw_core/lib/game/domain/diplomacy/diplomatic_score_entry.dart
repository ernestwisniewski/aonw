part of 'diplomacy_state.dart';

final class DiplomaticScoreEntry {
  const DiplomaticScoreEntry({
    required this.playerAId,
    required this.playerBId,
    required this.turn,
    required this.delta,
    required this.scoreAfter,
    required this.reason,
    this.sourceId,
  });

  factory DiplomaticScoreEntry.between({
    required String playerAId,
    required String playerBId,
    required int turn,
    required int delta,
    required int scoreAfter,
    required DiplomaticScoreChangeReason reason,
    String? sourceId,
  }) {
    final pair = DiplomacyState.normalizedPair(playerAId, playerBId);
    return DiplomaticScoreEntry(
      playerAId: pair.$1,
      playerBId: pair.$2,
      turn: turn,
      delta: delta,
      scoreAfter: scoreAfter,
      reason: reason,
      sourceId: sourceId,
    );
  }

  factory DiplomaticScoreEntry.fromJson(Map<String, dynamic> json) {
    return DiplomaticScoreEntry.between(
      playerAId: _requiredString(json, 'playerAId'),
      playerBId: _requiredString(json, 'playerBId'),
      turn: _requiredNonNegativeInt(json['turn'], 'turn'),
      delta: _optionalInt(json['delta'], 'delta') ?? 0,
      scoreAfter: _optionalInt(json['scoreAfter'], 'scoreAfter') ?? 0,
      reason: _enumValue(
        json['reason'],
        DiplomaticScoreChangeReason.values,
        'DiplomaticScoreEntry.reason',
      ),
      sourceId: _optionalString(json, 'sourceId'),
    );
  }

  final String playerAId;
  final String playerBId;
  final int turn;
  final int delta;
  final int scoreAfter;
  final DiplomaticScoreChangeReason reason;
  final String? sourceId;

  String get key => DiplomacyState.relationKey(playerAId, playerBId);

  Map<String, dynamic> toJson() => {
    'playerAId': playerAId,
    'playerBId': playerBId,
    'turn': turn,
    'delta': delta,
    'scoreAfter': scoreAfter,
    'reason': reason.name,
    if (sourceId != null) 'sourceId': sourceId,
  };

  @override
  bool operator ==(Object other) =>
      other is DiplomaticScoreEntry &&
      other.playerAId == playerAId &&
      other.playerBId == playerBId &&
      other.turn == turn &&
      other.delta == delta &&
      other.scoreAfter == scoreAfter &&
      other.reason == reason &&
      other.sourceId == sourceId;

  @override
  int get hashCode => Object.hash(
    DiplomaticScoreEntry,
    playerAId,
    playerBId,
    turn,
    delta,
    scoreAfter,
    reason,
    sourceId,
  );
}
