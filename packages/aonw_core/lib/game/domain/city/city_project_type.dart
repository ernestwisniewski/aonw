enum CityProjectType {
  wealth,
  research;

  String get displayName => switch (this) {
    CityProjectType.wealth => 'Bogactwo',
    CityProjectType.research => 'Badania',
  };

  static CityProjectType fromName(String name) {
    return values.byName(name);
  }
}
