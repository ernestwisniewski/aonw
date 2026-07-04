class UnitCapabilities {
  final bool producibleByCities;
  final bool naval;
  final bool gainsExperience;
  final bool military;
  final bool recon;

  const UnitCapabilities({
    required this.producibleByCities,
    required this.naval,
    required this.gainsExperience,
    required this.military,
    required this.recon,
  });

  @override
  bool operator ==(Object other) {
    return other is UnitCapabilities &&
        other.producibleByCities == producibleByCities &&
        other.naval == naval &&
        other.gainsExperience == gainsExperience &&
        other.military == military &&
        other.recon == recon;
  }

  @override
  int get hashCode {
    return Object.hash(
      producibleByCities,
      naval,
      gainsExperience,
      military,
      recon,
    );
  }
}
