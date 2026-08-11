import 'package:aonw_core/game/domain/unit/unit_movement_domain.dart';

class UnitCapabilities {
  final bool producibleByCities;
  final UnitMovementDomain movementDomain;
  final bool gainsExperience;
  final bool military;
  final bool recon;

  const UnitCapabilities({
    required this.producibleByCities,
    UnitMovementDomain? movementDomain,
    bool naval = false,
    required this.gainsExperience,
    required this.military,
    required this.recon,
  }) : movementDomain =
           movementDomain ??
           (naval ? UnitMovementDomain.naval : UnitMovementDomain.land);

  bool get naval => movementDomain == UnitMovementDomain.naval;

  @override
  bool operator ==(Object other) {
    return other is UnitCapabilities &&
        other.producibleByCities == producibleByCities &&
        other.movementDomain == movementDomain &&
        other.gainsExperience == gainsExperience &&
        other.military == military &&
        other.recon == recon;
  }

  @override
  int get hashCode {
    return Object.hash(
      producibleByCities,
      movementDomain,
      gainsExperience,
      military,
      recon,
    );
  }
}
