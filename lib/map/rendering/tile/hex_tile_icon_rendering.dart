part of 'hex_tile_painter.dart';

extension _HexTileIconRendering on HexTilePainter {
  void _drawIconBox({
    required Canvas canvas,
    required RRect? box,
    required List<RRect> badges,
    required List<Rect> iconRects,
    required List<String> iconPaths,
    required Color accent,
  }) {
    if (box == null) return;
    MapIconBadgePainter.paintTray(canvas, box, accent: accent);
    final count = math.min(iconPaths.length, iconRects.length);
    for (int i = 0; i < count; i++) {
      final badge = i < badges.length
          ? badges[i]
          : _badgeForIconRect(iconRects[i]);
      MapIconBadgePainter.paintBadge(canvas, badge, accent: accent);
      _drawIcon(canvas, iconPaths[i], iconRects[i], clip: badge.deflate(3.0));
    }
  }

  void _drawResourceIcons({
    required Canvas canvas,
    required RRect? box,
    required List<RRect> badges,
    required List<Rect> iconRects,
    required List<String> iconPaths,
    required Color accent,
  }) {
    if (badges.isEmpty) return;
    if (box != null) {
      MapIconBadgePainter.paintTray(canvas, box, accent: accent);
    }
    final count = math.min(iconPaths.length, badges.length);
    for (int i = 0; i < count; i++) {
      final badge = badges[i];
      MapIconBadgePainter.paintBadge(
        canvas,
        badge,
        accent: accent,
        prominent: true,
      );
      _drawIcon(canvas, iconPaths[i], iconRects[i], clip: badge.deflate(4.0));
    }
  }

  void _drawIcon(Canvas canvas, String path, Rect iconRect, {RRect? clip}) {
    final image = HexIconCache.imageFor(path);
    final sourceRect = HexIconCache.sourceRectFor(path);
    if (image != null && sourceRect != null) {
      if (clip != null) {
        canvas
          ..save()
          ..clipRRect(clip)
          ..drawImageRect(
            image,
            sourceRect,
            iconRect,
            HexTilePainter._paintMapIconImage,
          )
          ..restore();
        return;
      }
      canvas.drawImageRect(
        image,
        sourceRect,
        iconRect,
        HexTilePainter._paintMapIconImage,
      );
    } else {
      canvas.drawCircle(iconRect.center, iconRect.width / 2, _paintIconDot);
    }
  }

  RRect _badgeForIconRect(Rect iconRect) {
    return RRect.fromRectAndRadius(
      iconRect.inflate(3.0),
      Radius.circular((iconRect.width + 6.0) * 0.32),
    );
  }

  void _drawHeightBadge({
    required Canvas canvas,
    required RRect? rect,
    required Offset paragraphOffset,
    required double perspectiveY,
  }) {
    if (rect == null) return;

    _drawRRectShadow(canvas, rect, 2.5);
    canvas
      ..drawRRect(rect, HexTilePainter._paintBadgeBg)
      ..drawRRect(rect, HexTilePainter._paintBadgeBorder)
      ..save()
      ..scale(1.0, 1.0 / perspectiveY)
      ..drawParagraph(_heightParagraph, paragraphOffset)
      ..restore();
  }

  void _drawRRectShadow(Canvas canvas, RRect rect, double elevation) {
    canvas.drawShadow(
      Path()..addRRect(rect),
      HudPaint.color(Colors.black, alpha: HexTilePainter._shadowAlpha),
      elevation,
      true,
    );
  }
}
