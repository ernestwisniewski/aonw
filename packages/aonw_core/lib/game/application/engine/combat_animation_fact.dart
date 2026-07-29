/// Renderer-neutral geometry for one resolved combat event.
final class CombatAnimationFact {
  const CombatAnimationFact({
    required this.eventIndex,
    required this.attackerUnitId,
    required this.defenderId,
    required this.attackerFromCol,
    required this.attackerFromRow,
    required this.attackerToCol,
    required this.attackerToRow,
  });

  final int eventIndex;
  final String attackerUnitId;
  final String defenderId;
  final int attackerFromCol;
  final int attackerFromRow;
  final int attackerToCol;
  final int attackerToRow;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CombatAnimationFact &&
            other.eventIndex == eventIndex &&
            other.attackerUnitId == attackerUnitId &&
            other.defenderId == defenderId &&
            other.attackerFromCol == attackerFromCol &&
            other.attackerFromRow == attackerFromRow &&
            other.attackerToCol == attackerToCol &&
            other.attackerToRow == attackerToRow;
  }

  @override
  int get hashCode => Object.hash(
    eventIndex,
    attackerUnitId,
    defenderId,
    attackerFromCol,
    attackerFromRow,
    attackerToCol,
    attackerToRow,
  );
}
