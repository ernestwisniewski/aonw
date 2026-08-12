enum StrategicResourceEconomyProfile {
  legacyPresenceV0,
  stockpileV1;

  static StrategicResourceEconomyProfile fromJson(Object? value) {
    if (value == null) return StrategicResourceEconomyProfile.legacyPresenceV0;
    if (value is! String) {
      throw const FormatException(
        'Expected strategic resource economy profile.',
      );
    }
    return StrategicResourceEconomyProfile.values.firstWhere(
      (profile) => profile.name == value,
      orElse: () => throw FormatException(
        'Unknown strategic resource economy profile: $value',
      ),
    );
  }
}
