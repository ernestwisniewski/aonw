part of 'city_marker.dart';

final class CityMarkerDebugSnapshot {
  final double healthFraction;
  final int visualLevel;
  final CitySpriteTechnologyProfile technologyProfile;
  final String cityName;
  final int population;
  final bool isCapital;
  final bool labelEnabled;
  final bool paintsCityLabel;
  final bool paintsCityLabelOwnerDot;
  final bool showHealthBar;
  final bool paintsCityHealthBar;
  final bool paintsStoredArtifactBadge;
  final bool paintsCityOwnerIndicator;
  final bool paintsCityToken;
  final double labelMaxWidth;
  final double labelOwnerDotRadius;
  final double labelOwnerDotGap;
  final bool paintsCapitalStar;
  final double labelCapitalStarRadius;
  final bool usesTypeIconBadge;
  final bool hasSelectionTint;
  final bool hasSelectionRing;
  final Rect selectionRingRect;
  final double selectionRingStrokeWidth;
  final Color rimColor;
  final Color rimShadowColor;
  final int colorValue;
  final bool hasAmbientFloat;
  final Vector2 restingPosition;
  final bool reduceMotion;
  final double markerWorldScale;
  final int frameIndex;
  final Rect typeIconRect;
  final double typeIconPulse;
  final Rect cityLabelHitRect;
  final Rect cityHealthBarRect;
  final double cityLabelPulse;
  final bool paintsSelectedCityLabelBorder;
  final Vector2 markerSize;
  final Rect spriteBounds;
  final Path spriteClipPath;
  final BoardAssetCapStyle boardCapStyle;
  final double sourceInset;
  final double statusTop;

  CityMarkerDebugSnapshot._(CityMarker marker)
    : healthFraction = marker._healthFraction,
      visualLevel = marker._visualLevel,
      technologyProfile = marker._technologyProfile,
      cityName = marker._name,
      population = marker._population,
      isCapital = marker._isCapital,
      labelEnabled = marker._showLabel,
      paintsCityLabel = marker._shouldPaintLabel,
      paintsCityLabelOwnerDot = false,
      showHealthBar = marker._showHealthBar,
      paintsCityHealthBar = marker._paintsCityHealthBar,
      paintsStoredArtifactBadge = marker._hasStoredArtifact,
      paintsCityOwnerIndicator = false,
      paintsCityToken = true,
      labelMaxWidth = CityMarker._labelMaxWidth,
      labelOwnerDotRadius = 0,
      labelOwnerDotGap = 0,
      paintsCapitalStar = marker._shouldPaintLabel && marker._isCapital,
      labelCapitalStarRadius = CityMarker._labelCapitalStarRadius,
      usesTypeIconBadge = false,
      hasSelectionTint = false,
      hasSelectionRing = false,
      selectionRingRect = Rect.zero,
      selectionRingStrokeWidth = 0,
      rimColor = marker.effectiveRimColor,
      rimShadowColor = marker.effectiveRimShadowColor,
      colorValue = marker._visualState.colorValue,
      hasAmbientFloat = false,
      restingPosition = Vector2(
        marker._visualState.worldPosition.dx,
        marker._visualState.worldPosition.dy,
      ),
      reduceMotion = marker._reduceMotion,
      markerWorldScale = marker._markerWorldScale,
      frameIndex = marker._spriteColumn,
      typeIconRect = marker._typeIconRect,
      typeIconPulse = marker._typeIconPulse,
      cityLabelHitRect = marker._labelHitRect,
      cityHealthBarRect = _healthBarRect(marker),
      cityLabelPulse = marker._labelPulse,
      paintsSelectedCityLabelBorder =
          marker._selected && marker._shouldPaintLabel,
      markerSize = marker.size.clone(),
      spriteBounds = _spriteBounds(marker),
      spriteClipPath = _cityMarkerClipPath(_spriteBounds(marker)),
      boardCapStyle = CityMarker._capStyle,
      sourceInset = CityMarker._sourceInset,
      statusTop = marker._statusTopFor(_spriteBounds(marker));

  static Rect _spriteBounds(CityMarker marker) => marker._spriteBoundsFor(
    Offset(CityMarker._width / 2, CityMarker._height / 2),
  );

  static Rect _healthBarRect(CityMarker marker) {
    if (!marker._paintsCityHealthBar) return Rect.zero;
    final center = Offset(CityMarker._width / 2, CityMarker._height / 2);
    final spriteBounds = marker._spriteBoundsFor(center);
    return MarkerHealthBar.healthRect(
      center: center,
      top: marker._statusTopFor(spriteBounds),
      width: _healthBarWidthFor(spriteBounds),
    );
  }
}

extension _CityMarkerDebugView on CityMarker {
  CityMarkerDebugSnapshot get _debugSnapshot => CityMarkerDebugSnapshot._(this);
}
