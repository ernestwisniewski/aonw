/// Identifies the single AI execution that owns a human turn-opening barrier.
final class TurnOpeningLease {
  final String saveId;
  final int sourceTurn;
  final String executionPlayerId;
  final int generation;

  const TurnOpeningLease({
    required this.saveId,
    required this.sourceTurn,
    required this.executionPlayerId,
    required this.generation,
  });

  @override
  bool operator ==(Object other) {
    return other is TurnOpeningLease &&
        other.saveId == saveId &&
        other.sourceTurn == sourceTurn &&
        other.executionPlayerId == executionPlayerId &&
        other.generation == generation;
  }

  @override
  int get hashCode =>
      Object.hash(saveId, sourceTurn, executionPlayerId, generation);
}
