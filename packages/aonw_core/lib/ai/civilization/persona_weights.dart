class PersonaWeights {
  final double aggression;
  final double expansion;
  final double economy;
  final double science;

  const PersonaWeights({
    required this.aggression,
    required this.expansion,
    required this.economy,
    required this.science,
  });

  static const identity = PersonaWeights(
    aggression: 1.0,
    expansion: 1.0,
    economy: 1.0,
    science: 1.0,
  );

  PersonaWeights multiply(PersonaWeights other) {
    return PersonaWeights(
      aggression: aggression * other.aggression,
      expansion: expansion * other.expansion,
      economy: economy * other.economy,
      science: science * other.science,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PersonaWeights &&
        other.aggression == aggression &&
        other.expansion == expansion &&
        other.economy == economy &&
        other.science == science;
  }

  @override
  int get hashCode => Object.hash(aggression, expansion, economy, science);

  @override
  String toString() {
    return 'PersonaWeights('
        'aggression: $aggression, '
        'expansion: $expansion, '
        'economy: $economy, '
        'science: $science'
        ')';
  }
}
