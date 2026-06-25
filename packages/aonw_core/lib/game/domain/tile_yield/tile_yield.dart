class TileYield {
  final int food;
  final int production;
  final int gold;
  final int defense;

  const TileYield({
    required this.food,
    required this.production,
    required this.gold,
    required this.defense,
  });

  static const zero = TileYield(food: 0, production: 0, gold: 0, defense: 0);

  TileYield operator +(TileYield other) {
    return TileYield(
      food: food + other.food,
      production: production + other.production,
      gold: gold + other.gold,
      defense: defense + other.defense,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TileYield &&
            other.food == food &&
            other.production == production &&
            other.gold == gold &&
            other.defense == defense;
  }

  @override
  int get hashCode => Object.hash(food, production, gold, defense);

  @override
  String toString() {
    return 'TileYield(food: $food, production: $production, gold: $gold, defense: $defense)';
  }
}
