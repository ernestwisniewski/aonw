import 'package:flutter/foundation.dart';

@immutable
final class HexTileMarkers {
  final bool canFoundCity;
  final bool forceShowCitySite;
  final bool recommendedCitySite;
  final bool canGrowCity;
  final bool canImproveNow;
  final bool canImproveAfterTechnology;
  final bool workerImprovementCandidate;
  final bool workerBuildAvailable;
  final bool workerBuildBlocked;
  final bool canAttackTarget;

  const HexTileMarkers({
    this.canFoundCity = false,
    this.forceShowCitySite = false,
    this.recommendedCitySite = false,
    this.canGrowCity = false,
    this.canImproveNow = false,
    this.canImproveAfterTechnology = false,
    this.workerImprovementCandidate = false,
    this.workerBuildAvailable = false,
    this.workerBuildBlocked = false,
    this.canAttackTarget = false,
  });

  static const none = HexTileMarkers();

  bool get hasAny =>
      canFoundCity ||
      forceShowCitySite ||
      recommendedCitySite ||
      canGrowCity ||
      canImproveNow ||
      canImproveAfterTechnology ||
      workerImprovementCandidate ||
      workerBuildAvailable ||
      workerBuildBlocked ||
      canAttackTarget;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HexTileMarkers &&
          canFoundCity == other.canFoundCity &&
          forceShowCitySite == other.forceShowCitySite &&
          recommendedCitySite == other.recommendedCitySite &&
          canGrowCity == other.canGrowCity &&
          canImproveNow == other.canImproveNow &&
          canImproveAfterTechnology == other.canImproveAfterTechnology &&
          workerImprovementCandidate == other.workerImprovementCandidate &&
          workerBuildAvailable == other.workerBuildAvailable &&
          workerBuildBlocked == other.workerBuildBlocked &&
          canAttackTarget == other.canAttackTarget;

  @override
  int get hashCode => Object.hash(
    canFoundCity,
    forceShowCitySite,
    recommendedCitySite,
    canGrowCity,
    canImproveNow,
    canImproveAfterTechnology,
    workerImprovementCandidate,
    workerBuildAvailable,
    workerBuildBlocked,
    canAttackTarget,
  );
}
