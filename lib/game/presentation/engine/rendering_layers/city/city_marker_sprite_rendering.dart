part of 'city_marker.dart';

extension _CityMarkerSpriteRendering on CityMarker {
  bool _paintCitySprite(Canvas canvas, Offset center) {
    final image = HexIconCache.imageFor(CityMarker._citySpritePath);
    if (image == null) {
      _paintFallbackIcon(canvas, center);
      return false;
    }

    final destination = _spriteBoundsFor(center);
    _drawCityFrame(
      canvas,
      image: image,
      row: _spriteRow,
      column: _spriteColumn,
      destination: destination,
    );
    return true;
  }

  void _paintCityHealthBar(
    Canvas canvas, {
    required Offset center,
    required double statusTop,
    required Rect spriteBounds,
  }) {
    if (!_paintsCityHealthBar) return;
    MarkerHealthBar.paint(
      canvas,
      center: center,
      top: statusTop,
      width: _healthBarWidthFor(spriteBounds),
      fraction: _healthFraction,
    );
  }

  void _paintStoredArtifactBadge(Canvas canvas, {required Rect spriteBounds}) {
    if (!_hasStoredArtifact) return;
    final center = Offset(
      spriteBounds.left - CityMarker._artifactBadgeRadius - 2,
      spriteBounds.top + CityMarker._artifactBadgeRadius + 4,
    );
    final outer = Rect.fromCircle(
      center: center,
      radius: CityMarker._artifactBadgeRadius,
    );
    final inner = outer.deflate(1.5);
    canvas
      ..drawCircle(
        center.translate(0, 1.2),
        CityMarker._artifactBadgeRadius + 1.6,
        HudPaint.shadow(alpha: MapAlpha.regular),
      )
      ..drawOval(outer, HudPaint.fill(HudPalette.bg, alpha: MapAlpha.solid))
      ..drawOval(outer, HudPaint.stroke(HudPalette.goldLight, strokeWidth: 1.1))
      ..drawOval(inner, HudPaint.fill(HudPalette.gold, alpha: MapAlpha.opaque));
    GameIconRenderer.paintIcon(
      canvas,
      GameIcons.artifact,
      topLeft: Offset(center.dx - 4.8, center.dy - 4.8),
      size: 9.6,
      color: HudPalette.bg,
    );
  }

  void _drawCityFrame(
    Canvas canvas, {
    required ui.Image image,
    required int row,
    required int column,
    required Rect destination,
  }) {
    final baseSourceRect = CitySpriteCatalog.sourceRectFor(
      imageWidth: image.width,
      imageHeight: image.height,
      column: column,
      row: row,
    );
    BoardAssetCapPainter.paint(
      canvas: canvas,
      style: CityMarker._capStyle,
      image: image,
      sourceRect: baseSourceRect,
      topRect: destination,
      imagePaint: Paint()..filterQuality = FilterQuality.medium,
      rimColor: effectiveRimColor,
      rimShadowColor: effectiveRimShadowColor,
    );
  }

  void _paintFallbackIcon(Canvas canvas, Offset center) {
    const iconSize = 34.0;
    GameIconRenderer.paintIcon(
      canvas,
      GameIcons.cityFilled,
      topLeft: Offset(center.dx - iconSize / 2, center.dy - iconSize / 2),
      size: iconSize,
      color: HudPalette.goldLight,
    );
  }
}
