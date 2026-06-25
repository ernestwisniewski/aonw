enum TechnologyEra {
  foundation,
  settlement,
  expansion,
  specialization,
  industry,
  strategy;

  static TechnologyEra fromString(String value) {
    return TechnologyEra.values.firstWhere(
      (era) => era.name == value,
      orElse: () => throw ArgumentError('Unknown technology era: $value'),
    );
  }
}
