class MovementCost {
  final int value;
  final bool blocked;

  const MovementCost.passable(this.value) : blocked = false;

  const MovementCost.blocked() : value = 0, blocked = true;

  bool get passable => !blocked;

  @override
  bool operator ==(Object other) {
    return other is MovementCost &&
        other.value == value &&
        other.blocked == blocked;
  }

  @override
  int get hashCode => Object.hash(value, blocked);
}
