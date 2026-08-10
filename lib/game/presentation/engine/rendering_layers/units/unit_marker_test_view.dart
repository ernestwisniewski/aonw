part of 'unit_marker.dart';

extension UnitMarkerTestView on UnitMarker {
  int get spriteColumnForTesting => _spriteController.currentColumn;

  UnitSpriteAction? get spriteActionForTesting => _spriteController.action;

  bool get usesTypeIconBadgeForTesting => _spriteController.hasSpriteAsset;

  double get spriteStatusTopForTesting =>
      UnitMarkerRenderer.spriteStatusTop(_renderModel);

  Rect get typeIconRectForTesting => _typeIconRect;

  Rect get artifactBadgeRectForTesting => _artifactBadgeRect;

  double get typeIconPulseForTesting => _typeIconPulse;

  bool get pendingActionTargetForTesting => pendingActionTarget;

  bool get attackTargetForTesting => attackTarget;

  bool get reduceMotionForTesting => _reduceMotion;

  bool get showPeripheralDetailsForTesting => showPeripheralDetails;

  bool get showOwnerColorForTesting => showOwnerColor;

  bool get showHealthBarForTesting => showHealthBar;

  bool get showTypeBadgeForTesting => showTypeBadge;

  bool get showStateBadgeForTesting => showStateBadge;

  bool get compactWorkVisualForTesting => compactWorkVisual;

  double get markerWorldScaleForTesting => _markerWorldScale;

  double get spriteScaleForTesting => _spriteScale;

  bool get animateIdleForTesting => _animateIdle;

  bool get spriteIdlePausesEnabledForTesting =>
      _spriteController.idlePausesEnabled;

  double get tacticalViewEmphasisForTesting => _tacticalViewEmphasis;

  UnitSpriteSize? get spriteRenderSizeForTesting =>
      UnitMarkerRenderer.spriteRenderSize(_renderModel);

  bool get paintsOwnerColorForTesting => _renderModel.paintsOwnerColor;

  bool get paintsTypeBadgeForTesting => _renderModel.paintsTypeBadge;

  bool get paintsIdentityBadgeForTesting => _renderModel.paintsIdentityBadge;

  bool get paintsHealthBarForTesting => _renderModel.paintsHealthBar;

  bool get paintsStateBadgeForTesting => _renderModel.paintsStateBadge;

  bool get hasFocusPulseForTesting =>
      !_reduceMotion && (_selected || _pendingActionTarget);

  bool get hasSelectionTintForTesting => false;

  bool get hasSelectionRingForTesting => false;

  Rect get selectionRingRectForTesting => Rect.zero;

  double get selectionRingStrokeWidthForTesting => 0;

  bool get animatesSpriteForTesting =>
      !_reduceMotion &&
      _spriteController.hasSpriteAsset &&
      (_spriteController.action != UnitSpriteAction.idle || _animateIdle);

  bool get hasAttackTargetTintForTesting =>
      _hasEffect(_attackTargetTintEffectKey);

  String? get workBadgeLabelForTesting => workBadgeLabel;

  bool get fortifiedForTesting => fortified;

  bool get skippedTurnForTesting => skippedTurn;

  bool get exhaustedForTesting => exhausted;

  bool get carryingArtifactForTesting => carryingArtifact;

  UnitMarkerStateBadge? get stateBadgeForTesting => _stateBadge;

  double get stateBadgeRadiusForTesting =>
      UnitMarkerBadgeStyle.stateBadgeRadiusFor(onCity: onCity);

  int get stateBadgeBackgroundAlphaForTesting =>
      UnitMarkerBadgeStyle.stateBadgeBackgroundAlpha;

  int get artifactBadgeBackgroundAlphaForTesting =>
      UnitMarkerBadgeStyle.artifactBadgeBackgroundAlpha;

  int get workBadgeBackgroundAlphaForTesting =>
      UnitMarkerBadgeStyle.workBadgeBackgroundAlpha;

  double get healthFractionForTesting => _healthFraction;

  Rect get spriteShadowRectForTesting =>
      UnitMarkerRenderer.spriteShadowRect(_renderModel);
}
