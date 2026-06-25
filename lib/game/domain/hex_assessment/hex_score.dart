class HexScore {
  final int city;
  final int defense;
  final int economy;

  const HexScore({this.city = 0, this.defense = 0, this.economy = 0});

  static const zero = HexScore();

  HexScore add({int city = 0, int defense = 0, int economy = 0}) {
    return HexScore(
      city: this.city + city,
      defense: this.defense + defense,
      economy: this.economy + economy,
    );
  }

  HexScore operator +(HexScore other) {
    return add(
      city: other.city,
      defense: other.defense,
      economy: other.economy,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HexScore &&
            other.city == city &&
            other.defense == defense &&
            other.economy == economy;
  }

  @override
  int get hashCode => Object.hash(city, defense, economy);

  @override
  String toString() {
    return 'HexScore(city: $city, defense: $defense, economy: $economy)';
  }
}
