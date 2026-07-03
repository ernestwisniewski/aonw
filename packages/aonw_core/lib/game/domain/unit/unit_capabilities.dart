class UnitCapabilities {
  final bool producibleByCities;
  final bool naval;
  final bool gainsExperience;

  const UnitCapabilities({
    required this.producibleByCities,
    required this.naval,
    required this.gainsExperience,
  });

  @override
  bool operator ==(Object other) {
    return other is UnitCapabilities &&
        other.producibleByCities == producibleByCities &&
        other.naval == naval &&
        other.gainsExperience == gainsExperience;
  }

  @override
  int get hashCode {
    return Object.hash(producibleByCities, naval, gainsExperience);
  }
}
