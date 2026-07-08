enum WonderType {
  greatLibrary,
  hangingGardens,
  greatWall,
  petra,
  centralBank,
  imperialUniversity,
  grandCathedral,
  motherFactory,
  nationalObservatory,
  svalbardSeedVault,
  grandExposition;

  String get displayName => switch (this) {
    WonderType.greatLibrary => 'Great Library',
    WonderType.hangingGardens => 'Hanging Gardens',
    WonderType.greatWall => 'Great Wall',
    WonderType.petra => 'Petra',
    WonderType.centralBank => 'Central Bank',
    WonderType.imperialUniversity => 'Imperial University',
    WonderType.grandCathedral => 'Grand Cathedral',
    WonderType.motherFactory => 'Mother Factory',
    WonderType.nationalObservatory => 'National Observatory',
    WonderType.svalbardSeedVault => 'Svalbard Seed Vault',
    WonderType.grandExposition => 'Grand Exposition',
  };

  static WonderType fromString(String value) {
    return WonderType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError('Unknown wonder type: $value'),
    );
  }
}
