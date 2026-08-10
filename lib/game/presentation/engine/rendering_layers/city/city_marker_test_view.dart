part of 'city_marker.dart';

extension CityMarkerTestView on CityMarker {
  double get healthFractionForTesting => _healthFraction;

  int get visualLevelForTesting => visualLevel;

  CitySpriteTechnologyProfile get technologyProfileForTesting =>
      technologyProfile;

  String get cityNameForTesting => _name;

  int get populationForTesting => _population;

  bool get isCapitalForTesting => _isCapital;

  bool get labelEnabledForTesting => _showLabel;

  bool get paintsCityLabelForTesting => _shouldPaintLabel;

  bool get paintsCityLabelOwnerDotForTesting => false;

  bool get showHealthBarForTesting => _showHealthBar;

  bool get paintsCityHealthBarForTesting =>
      _showHealthBar || _selected || _healthFraction < 0.995;

  bool get paintsStoredArtifactBadgeForTesting => _hasStoredArtifact;

  bool get paintsCityOwnerIndicatorForTesting => false;

  bool get paintsCityTokenForTesting => true;

  double get labelMaxWidthForTesting => _labelMaxWidth;

  double get labelOwnerDotRadiusForTesting => 0;

  double get labelOwnerDotGapForTesting => 0;

  bool get paintsCapitalStarForTesting => _shouldPaintLabel && _isCapital;

  double get labelCapitalStarRadiusForTesting => _labelCapitalStarRadius;

  bool get usesTypeIconBadgeForTesting => false;

  bool get hasSelectionTintForTesting => false;

  bool get hasSelectionRingForTesting => false;

  Rect get selectionRingRectForTesting => Rect.zero;

  double get selectionRingStrokeWidthForTesting => 0;

  Color get rimColorForTesting => effectiveRimColor;

  Color get rimShadowColorForTesting => effectiveRimShadowColor;

  int get colorValueForTesting => _colorValue;

  bool get hasAmbientFloatForTesting => false;

  Vector2 get restingPositionForTesting => _restingPosition.clone();

  bool get reduceMotionForTesting => _reduceMotion;

  double get markerWorldScaleForTesting => _markerWorldScale;

  int get frameIndexForTesting => _spriteColumn;

  Rect get typeIconRectForTesting => _typeIconRect;

  double get typeIconPulseForTesting => _typeIconPulse;

  Rect get cityLabelHitRectForTesting => _labelHitRectForTesting;

  Rect get cityHealthBarRectForTesting {
    if (!paintsCityHealthBarForTesting) return Rect.zero;
    final center = Offset(_width / 2, _height / 2);
    final spriteBounds = _spriteBoundsFor(center);
    return MarkerHealthBar.healthRect(
      center: center,
      top: _statusTopFor(spriteBounds),
      width: _healthBarWidthFor(spriteBounds),
    );
  }

  double get cityLabelPulseForTesting => _labelPulse;

  bool get paintsSelectedCityLabelBorderForTesting =>
      _selected && _shouldPaintLabel;

  Vector2 get markerSizeForTesting => size.clone();

  Rect get spriteBoundsForTesting =>
      _spriteBoundsFor(Offset(_width / 2, _height / 2));

  Path get spriteClipPathForTesting =>
      BoardAssetCapPainter.clipPathFor(spriteBoundsForTesting);

  BoardAssetCapStyle get boardCapStyleForTesting => _capStyle;

  double get sourceInsetForTesting => _sourceInset;

  double get statusTopForTesting {
    final center = Offset(_width / 2, _height / 2);
    return _statusTopFor(_spriteBoundsFor(center));
  }
}
