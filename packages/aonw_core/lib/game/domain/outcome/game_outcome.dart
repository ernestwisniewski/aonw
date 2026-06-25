import 'package:aonw_core/util/collection_equality.dart';

enum GameOutcomeCondition {
  ongoing,
  conquest,
  domination,
  cultural,
  score,
  draw,
}

class GameOutcome {
  final GameOutcomeCondition condition;
  final String? winnerPlayerId;
  final Map<String, int> scoreByPlayerId;

  const GameOutcome._({
    required this.condition,
    this.winnerPlayerId,
    this.scoreByPlayerId = const {},
  });

  static const ongoing = GameOutcome._(condition: GameOutcomeCondition.ongoing);

  const GameOutcome.conquest(String playerId)
    : this._(
        condition: GameOutcomeCondition.conquest,
        winnerPlayerId: playerId,
      );

  const GameOutcome.winner(String playerId) : this.conquest(playerId);

  const GameOutcome.domination(String playerId)
    : this._(
        condition: GameOutcomeCondition.domination,
        winnerPlayerId: playerId,
      );

  const GameOutcome.cultural(String playerId)
    : this._(
        condition: GameOutcomeCondition.cultural,
        winnerPlayerId: playerId,
      );

  factory GameOutcome.score({
    required String winnerPlayerId,
    required Map<String, int> scoreByPlayerId,
  }) {
    return GameOutcome._(
      condition: GameOutcomeCondition.score,
      winnerPlayerId: winnerPlayerId,
      scoreByPlayerId: Map.unmodifiable(scoreByPlayerId),
    );
  }

  factory GameOutcome.draw({required Map<String, int> scoreByPlayerId}) {
    return GameOutcome._(
      condition: GameOutcomeCondition.draw,
      scoreByPlayerId: Map.unmodifiable(scoreByPlayerId),
    );
  }

  bool get finished => condition != GameOutcomeCondition.ongoing;

  @override
  bool operator ==(Object other) {
    return other is GameOutcome &&
        other.condition == condition &&
        other.winnerPlayerId == winnerPlayerId &&
        mapEquals(other.scoreByPlayerId, scoreByPlayerId);
  }

  @override
  int get hashCode {
    return Object.hash(condition, winnerPlayerId, mapHash(scoreByPlayerId));
  }

  @override
  String toString() {
    return 'GameOutcome(condition: $condition, winnerPlayerId: '
        '$winnerPlayerId, scoreByPlayerId: $scoreByPlayerId)';
  }
}
