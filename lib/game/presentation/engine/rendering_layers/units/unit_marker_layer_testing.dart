part of 'unit_marker_layer.dart';

extension UnitMarkerLayerTesting on UnitMarkerLayer {
  bool isMarkerSelectedForTesting(String unitId) =>
      _markers[unitId]?.selected ?? false;

  bool isMarkerPendingActionTargetForTesting(String unitId) =>
      _markers[unitId]?.pendingActionTargetForTesting ?? false;

  bool isMarkerAttackTargetForTesting(String unitId) =>
      _markers[unitId]?.attackTargetForTesting ?? false;

  bool markerHasFocusPulseForTesting(String unitId) =>
      _markers[unitId]?.hasFocusPulseForTesting ?? false;

  bool markerHasAttackTargetTintForTesting(String unitId) =>
      _markers[unitId]?.hasAttackTargetTintForTesting ?? false;

  bool markerReduceMotionForTesting(String unitId) =>
      _markers[unitId]?.reduceMotionForTesting ?? false;

  bool markerShowPeripheralDetailsForTesting(String unitId) =>
      _markers[unitId]?.showPeripheralDetailsForTesting ?? false;

  bool markerShowOwnerColorForTesting(String unitId) =>
      _markers[unitId]?.showOwnerColorForTesting ?? false;

  bool markerShowHealthBarForTesting(String unitId) =>
      _markers[unitId]?.showHealthBarForTesting ?? false;

  bool markerShowTypeBadgeForTesting(String unitId) =>
      _markers[unitId]?.showTypeBadgeForTesting ?? false;

  bool markerShowStateBadgeForTesting(String unitId) =>
      _markers[unitId]?.showStateBadgeForTesting ?? false;

  UnitMarkerStateBadge? markerStateBadgeForTesting(String unitId) =>
      _markers[unitId]?.stateBadgeForTesting;

  bool markerIsExhaustedForTesting(String unitId) =>
      _markers[unitId]?.exhaustedForTesting ?? false;

  UnitSpriteAction? markerActionForTesting(String unitId) =>
      _markers[unitId]?.spriteActionForTesting;

  bool markerAnimatesSpriteForTesting(String unitId) =>
      _markers[unitId]?.animatesSpriteForTesting ?? false;

  bool markerCompactWorkVisualForTesting(String unitId) =>
      _markers[unitId]?.compactWorkVisualForTesting ?? false;

  UnitSpriteSize? markerSpriteRenderSizeForTesting(String unitId) =>
      _markers[unitId]?.spriteRenderSizeForTesting;

  double? markerWorldScaleForTesting(String unitId) =>
      _markers[unitId]?.markerWorldScaleForTesting;

  double? markerSpriteScaleForTesting(String unitId) =>
      _markers[unitId]?.spriteScaleForTesting;

  bool markerAnimateIdleForTesting(String unitId) =>
      _markers[unitId]?.animateIdleForTesting ?? false;

  double? markerTacticalViewEmphasisForTesting(String unitId) =>
      _markers[unitId]?.tacticalViewEmphasisForTesting;

  String? markerWorkBadgeForTesting(String unitId) =>
      _markers[unitId]?.workBadgeLabelForTesting;

  bool markerCarriesArtifactForTesting(String unitId) =>
      _markers[unitId]?.carryingArtifactForTesting ?? false;

  double? markerHealthFractionForTesting(String unitId) =>
      _markers[unitId]?.healthFractionForTesting;

  Vector2? markerPositionForTesting(String unitId) =>
      worldPositionForUnit(unitId);

  bool hasMarkerForTesting(String unitId) => _markers.containsKey(unitId);

  bool isPositionLockedForTesting(String unitId) =>
      _animator.isPositionLocked(unitId);

  bool isAnimationMarkerRetainedForTesting(String unitId) =>
      _animator.isRetained(unitId);
}
