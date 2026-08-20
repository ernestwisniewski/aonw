part of 'city_marker.dart';

extension _CityMarkerSpriteRendering on CityMarker {
  bool _paintCitySprite(Canvas canvas, Offset center) {
    final spriteBounds = _spriteBoundsFor(center);
    final spriteClipPath = _cityMarkerClipPath(spriteBounds);
    final imagePaint = Paint()..filterQuality = FilterQuality.medium;

    canvas
      ..save()
      ..clipPath(spriteClipPath)
      ..drawRect(
        spriteBounds,
        HudPaint.fill(HudPalette.surface, alpha: MapAlpha.whisper),
      );

    final frame = _citySpriteFrame;
    if (frame == null) {
      _paintFallbackIcon(canvas, center);
      canvas.restore();
      _paintRim(canvas, spriteClipPath);
      return false;
    }

    final geometry = frame.geometryFor(
      logicalSource: Offset.zero & frame.originalSize,
      destination: spriteBounds,
    );
    canvas
      ..drawImageRect(
        frame.image,
        geometry.source,
        geometry.destination,
        imagePaint,
      )
      ..restore();
    _paintRim(canvas, spriteClipPath);
    return true;
  }

  void _paintRim(Canvas canvas, Path outlinePath) {
    if (_selected) {
      canvas
        ..drawPath(
          outlinePath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = MapStroke.glow + 1.2
            ..color = effectiveRimShadowColor.withAlpha(MapAlpha.regular)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4.4),
        )
        ..drawPath(
          outlinePath,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = MapStroke.glow
            ..color = effectiveRimShadowColor.withAlpha(MapAlpha.faint + 10)
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.9),
        );
    }
    canvas.drawPath(
      outlinePath,
      HudPaint.stroke(
        effectiveRimColor,
        alpha: MapAlpha.strong,
        strokeWidth: MapStroke.bold,
      ),
    );
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

Path _cityMarkerClipPath(Rect spriteBounds) {
  return HexGeometry.projectedTopFacePath(
    bounds: spriteBounds,
    perspectiveY: HexGrid.perspectiveY,
  );
}
